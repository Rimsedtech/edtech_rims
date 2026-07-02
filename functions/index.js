/* eslint-disable require-jsdoc */
"use strict";

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const axios = require("axios");
const cheerio = require("cheerio");
const pdfParse = require("pdf-parse");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

const BASE_URL = "https://mpsc.mizoram.gov.in";
const SCRAPE_URL = `${BASE_URL}/page/advertisement-2026-2027`;
const TTL_DAYS = 90;

// ── Helper: stable 40-char SHA-1 doc ID from a URL ──
function urlToDocId(url) {
  return crypto.createHash("sha1").update(url).digest("hex");
}

// ── Helper: resolve relative URLs ──
function resolveUrl(href) {
  if (!href) return null;
  return href.startsWith("/") ? `${BASE_URL}${href}` : href;
}

// ── Helper: extract department from ad title text ──
function extractDepartment(title) {
  const match = title.match(/under\s+(.+?)(?:\s+Deptt?\.?|$)/i);
  return match ? match[1].trim() : "General";
}

// ── Helper: extract last date from PDF text ──
async function extractLastDate(pdfLink) {
  try {
    const pdfRes = await axios.get(pdfLink, {
      responseType: "arraybuffer",
      timeout: 12000,
    });
    const { text } = await pdfParse(pdfRes.data);
    const match = text.match(
      /last\s+date[^:]*:\s*([\d]{1,2}[\s\-/][\w]+[\s\-/][\d]{2,4})/i
    );
    return match ? match[1].trim() : "Check PDF";
  } catch {
    return "Check PDF"; // Scanned PDF or network error — graceful fallback
  }
}

// ────────────────────────────────────────────────
// scrapeMPSC — runs every 6 hours
// ────────────────────────────────────────────────
exports.scrapeMPSC = onSchedule("every 6 hours", async () => {
  const logRef = db.collection("scrape_logs").doc();
  let successCount = 0;
  let failureCount = 0;

  try {
    const { data } = await axios.get(SCRAPE_URL, { timeout: 15000 });
    const $ = cheerio.load(data);

    // Collect all PDF links from standard <a href="...pdf"> tags
    const ads = [];
    $("a[href$='.pdf']").each((_, el) => {
      const rawHref = $(el).attr("href");
      const title = $(el).text().trim();
      const link = resolveUrl(rawHref);
      if (title && link) ads.push({ title, link });
    });

    logger.info(`Found ${ads.length} PDF links on page.`);

    for (const ad of ads) {
      try {
        const docId = urlToDocId(ad.link);
        const docRef = db.collection("mpsc_advertisements").doc(docId);

        // Deduplication — skip if already stored
        if ((await docRef.get()).exists) continue;

        const department = extractDepartment(ad.title);
        const lastDate = await extractLastDate(ad.link);

        await docRef.set({
          title: ad.title,
          department,
          pdfLink: ad.link,
          lastDate,
          // v1: status lifecycle managed by cleanMPSC via scrapedAt TTL
          // v2 upgrade: parse lastDate → lastDateTimestamp for precise expiry
          status: "active",
          scrapedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        successCount++;
        logger.info(`Saved: ${ad.title}`);
      } catch (docErr) {
        failureCount++;
        logger.error(`Failed for "${ad.title}": ${docErr.message}`);
      }
    }
  } catch (globalErr) {
    logger.error("Global scrape aborted:", globalErr.message);
    await logRef.set({
      status: "failed",
      error: globalErr.message,
      successCount: 0,
      failureCount: 0,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  await logRef.set({
    status: "success",
    successCount,
    failureCount,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(`Scrape complete. Success: ${successCount}, Failed: ${failureCount}`);
});

// ────────────────────────────────────────────────
// cleanMPSC — runs weekly, expires old ads
// v1: TTL by scrapedAt age (90 days)
// v2 path: switch to lastDateTimestamp < now() once parsing is reliable
// ────────────────────────────────────────────────
exports.cleanMPSC = onSchedule("every 168 hours", async () => {
  const cutoff = new Date(Date.now() - TTL_DAYS * 24 * 60 * 60 * 1000);

  const snap = await db
    .collection("mpsc_advertisements")
    .where("status", "==", "active")
    .where("scrapedAt", "<", cutoff)
    .get();

  if (snap.empty) {
    logger.info("cleanMPSC: No expired advertisements found.");
    return;
  }

  const batch = db.batch();
  snap.docs.forEach((doc) => batch.update(doc.ref, { status: "expired" }));
  await batch.commit();

  logger.info(`cleanMPSC: Expired ${snap.size} old advertisements.`);
});
