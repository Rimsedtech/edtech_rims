import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/features/store/data/models/skin_model.dart';

/// Repository for handling Avatar Store data (fetching skins, uploading skins).
@lazySingleton
class StoreRepository with FirebaseGuardedExecution {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  StoreRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  CollectionReference<Map<String, dynamic>> get _skinsCollection =>
      _firestore.collection('skins');

  /// Streams all available skins from the store, ordered by price.
  Stream<Result<List<SkinModel>>> watchSkins() {
    return guardedStream(
      () => _skinsCollection
          .orderBy('price', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map(SkinModel.fromFirestore).toList();
          }),
      taskName: 'watchSkins',
    );
  }

  /// Uploads a new skin to Firebase Storage and saves its metadata to Firestore.
  Future<Result<SkinModel>> uploadSkin({
    required File imageFile,
    required String name,
    required int price,
  }) async {
    return guardedTask(() async {
      // 1. Upload image to Firebase Storage
      final fileName = 'skin_${DateTime.now().millisecondsSinceEpoch}.png';
      final storageRef = _storage.ref().child('skins/$fileName');

      final uploadTask = await storageRef.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // 2. Save metadata to Firestore
      final docRef = await _skinsCollection.add({
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newDoc = await docRef.get();
      return SkinModel.fromFirestore(newDoc);
    }, taskName: 'uploadSkin');
  }
}
