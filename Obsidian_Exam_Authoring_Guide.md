# Obsidian Exam Authoring Guide

Welcome to the **RIMS EdTech Exam Content Engine**. We use Markdown files (authored in Obsidian or any text editor) to quickly write, structure, and deploy mock exams directly to Firebase.

This guide is the single source of truth for authoring exams after the latest schema update.

---

## What You See in the App vs. What You Write

| App Label (UI) | Frontmatter Field | Example Value |
|---|---|---|
| **TEST SERIES** dropdown | `subject` | `"Mathematics"` |
| **TOPIC** dropdown | `group` | `"Group B and below"` |
| Exam Title | `title` | `"RIMS Competitive Exam — Percentage"` |

> ⚠️ **Difficulty is completely removed.** Do not add a `difficulty` field — it is no longer used anywhere in the app.

---

## 1. Directory Structure

All exam files live in `app/test_exams/`. Each exam is **one `.md` file**. The parser will convert every `.md` file in that directory into one exam in Firestore.

```
app/
  test_exams/
    percentage_test_formatted.md    ← one exam = one file
    algebra_test.md
    reasoning_test.md
```

---

## 2. File Format

A valid exam file has two parts:
1. **Frontmatter** — YAML metadata block at the very top of the file
2. **Body** — The questions, one after another

---

### 2.1 Frontmatter (Required)

The file **must** start with a YAML block enclosed in `---` delimiters.

```yaml
---
title: "RIMS Competitive Exam Series — Percentage"
subject: "Mathematics"
group: "Group B and below"
duration_minutes: 45
xp_reward: 200
status: "published"
---
```

#### All Frontmatter Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `title` | String | ✅ Yes | The exam's display name in the app |
| `subject` | String | ✅ Yes | Maps to the **TEST SERIES** picker in the app |
| `group` | String | ✅ Yes | Maps to the **TOPIC** picker in the app |
| `duration_minutes` | Number | ✅ Yes | Time limit in minutes (e.g. `45`) |
| `xp_reward` | Number | ✅ Yes | XP awarded to the exam itself (e.g. `200`) |
| `status` | String | Optional | `"published"` or `"draft"` (default: `"draft"`) |
| `description` | String | Optional | Short description shown in the exam library |
| `created_by` | String | Optional | Author identifier (default: `"obsidian_parser"`) |

> 🚫 **Do NOT include `difficulty`, `difficultyTier`, or any difficulty field.** These are removed from the schema.

---

### 2.2 Writing Questions

Each question starts with a `## Q<number>` heading. The parser uses these headings to split questions — the heading text is ignored.

#### Question Block Structure

```markdown
## Q1
<Question text here. Supports LaTeX: $\frac{x}{y}$>

- [ ] Option A (wrong)
- [x] Option B (correct — use [x])
- [ ] Option C (wrong)
- [ ] Option D (wrong)

**Points:** 2
**Explanation:** The correct answer is (b) because...
```

#### Per-Question Fields

| Field | Format | Required | Description |
|---|---|---|---|
| Question text | Plain text / LaTeX | ✅ Yes | The question body. LaTeX supported with `$...$` or `$$...$$` |
| Options | `- [ ]` / `- [x]` | ✅ Yes | 2–5 options. Mark the correct one with `[x]` |
| `**Points:**` | Number | Optional | Marks for this question (default: `1`). **This also sets the `xpReward`** |
| `**Explanation:**` | Text | Optional | Shown to student after submission |

> 💡 `**Points:** 3` means this question is worth 3 marks AND earns 3 XP when answered correctly.

> 🚫 **Do NOT add `**Difficulty:**` per question.** It is ignored.

---

### 2.3 Full Example File

```markdown
---
title: "RIMS Competitive Exam — Percentages"
subject: "Mathematics"
group: "Group B and below"
duration_minutes: 45
xp_reward: 200
status: "published"
---

## Q1
Convert 3/8 into percentage.

- [ ] 35.5%
- [x] 37.5%
- [ ] 32.5%
- [ ] 40%

**Points:** 1
**Explanation:** Correct answer is (b).

## Q2
What is 35% of 480?

- [ ] 152
- [x] 168
- [ ] 176
- [ ] 184

**Points:** 1
**Explanation:** Correct answer is (b).
```

---

## 3. How the Data Connects (App Flow)

```
Frontmatter: subject = "Mathematics"
                │
                ▼
    Firestore: exams/{id}.subject = "Mathematics"
    Firestore: questions/{id}.subject = "Mathematics"   ← denormalised
                │
                ▼
    App UI: TEST SERIES dropdown shows "Mathematics"
                │
                ▼
    User selects → Mock Test starts (filters by subject + group)

Frontmatter: group = "Group B and below"
                │
                ▼
    Firestore: exams/{id}.group = "Group B and below"
    Firestore: questions/{id}.group = "Group B and below"  ← denormalised
                │
                ▼
    App UI: TOPIC dropdown shows "Group B and below"
```

---

## 4. How to Upload

### Step 1: Parse the Markdown files into JSON

```bash
cd app
dart run scripts/obsidian_parser.dart test_exams database_seed.json
```

This reads every `.md` file in `test_exams/` and produces a single `database_seed.json`. Each `.md` file becomes **one exam** with all its questions.

### Step 2: Set Firebase credentials

```bash
export GOOGLE_APPLICATION_CREDENTIALS="service-account.json"
```

### Step 3: Upload to Firestore

```bash
dart run scripts/upload_to_firestore.dart
```

This reads `database_seed.json` and:
- Creates one `exams/{id}` document per exam
- Creates all question sub-documents under `exams/{id}/questions/`
- Updates `metadata/mock_test_config` with the new subjects, groups, and their mappings (used to populate the app's TEST SERIES and TOPIC dropdowns)

---

## 5. Tips & Troubleshooting

**Wiping all data before a fresh upload:**
```bash
firebase firestore:delete --all-collections --project edtech-3f6fe -f
```

**Re-deploying Firestore indexes** (if you see `FAILED_PRECONDITION` errors):
```bash
firebase deploy --only firestore:indexes --project edtech-3f6fe
```

**My exam was split into multiple separate exams:**
This happened before because difficulty was used as a grouping key. Since difficulty is now fully removed, each `.md` file always produces exactly **one exam** regardless of how you write your questions.

**TEST SERIES / TOPIC not showing in the app:**
These dropdowns are populated from `metadata/mock_test_config` in Firestore. Run the upload script after adding new files to refresh them.

**Converting from Word/DOCX to Markdown:**
```bash
brew install pandoc
pandoc -f docx -t markdown input.docx -o app/test_exams/my_exam.md
```
Then format the resulting `.md` to match the structure above before running the parser.

**LaTeX rendering:**
- Inline math: `$x^2 + y^2 = z^2$`
- Display math: `$$E = mc^2$$`
- The app uses flutter_math_fork for rendering.
