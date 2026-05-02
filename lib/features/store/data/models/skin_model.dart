import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a purchasable character skin in the Avatar Store.
class SkinModel extends Equatable {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final DateTime createdAt;

  const SkinModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.createdAt,
  });

  factory SkinModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SkinModel(
      id: doc.id,
      name: data['name'] as String,
      price: (data['price'] as num).toInt(),
      imageUrl: data['imageUrl'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, name, price, imageUrl, createdAt];

  /// Helper to determine if the imageUrl is a remote network URL.
  bool get isNetworkImage => imageUrl.startsWith('http');

  /// Helper to determine if the imageUrl is a local file URI.
  bool get isLocalImage => imageUrl.startsWith('file://');
}
