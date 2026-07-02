import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single MPSC job advertisement scraped from the MPSC website
/// and stored in the `mpsc_advertisements` Firestore collection.
class JobAdvertisement {
  final String id;
  final String title;
  final String department;
  final String lastDate;
  final String pdfLink;
  final String status; // "active" | "expired"
  final DateTime? scrapedAt;

  const JobAdvertisement({
    required this.id,
    required this.title,
    required this.department,
    required this.lastDate,
    required this.pdfLink,
    required this.status,
    this.scrapedAt,
  });

  factory JobAdvertisement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['scrapedAt'];
    return JobAdvertisement(
      id: doc.id,
      title: d['title'] as String? ?? '',
      department: d['department'] as String? ?? 'General',
      lastDate: d['lastDate'] as String? ?? 'Check PDF',
      pdfLink: d['pdfLink'] as String? ?? '',
      status: d['status'] as String? ?? 'active',
      scrapedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
