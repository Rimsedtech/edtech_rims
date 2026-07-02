import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitwise_academy/features/jobs/data/models/job_advertisement.dart';

/// Repository that streams active MPSC job advertisements from Firestore.
///
/// The [mpsc_advertisements] collection is written exclusively by the
/// Cloud Function (Admin SDK). This repository is read-only from the
/// client side, matching the Firestore security rules.
class JobRepository {
  final FirebaseFirestore _firestore;

  const JobRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Returns a real-time stream of active advertisements, newest first.
  ///
  /// Requires the composite index on [status ASC, scrapedAt DESC] to be
  /// deployed via `firebase deploy --only firestore:indexes`.
  Stream<List<JobAdvertisement>> watchActiveJobs() {
    return _firestore
        .collection('mpsc_advertisements')
        .where('status', isEqualTo: 'active')
        .orderBy('scrapedAt', descending: true)
        .withConverter<JobAdvertisement>(
          fromFirestore: (snap, _) => JobAdvertisement.fromFirestore(snap),
          toFirestore: (_, __) => {}, // read-only
        )
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
