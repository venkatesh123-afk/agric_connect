import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String farmerId;
  final Timestamp createdAt;
  final String category;
  final int quantity; // ✅ store quantity from Firestore or local

  File? image; // optional local file

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.farmerId,
    required this.createdAt,
    required this.category,
    required this.quantity,
    this.image,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      imageUrl: data['imageUrl'] ?? '',
      farmerId: data['farmerId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      category: data['category'] ?? '',
      quantity: data['quantity'] is int ? data['quantity'] : 0,
    );
  }

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      imageUrl: data['imageUrl'] ?? '',
      farmerId: data['farmerId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      category: data['category'] ?? '',
      quantity: data['quantity'] is int ? data['quantity'] : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'farmerId': farmerId,
      'createdAt': createdAt,
      'category': category,
      'quantity': quantity,
    };
  }

  void operator [](String other) {}
}
