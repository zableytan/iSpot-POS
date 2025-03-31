import 'package:flutter/foundation.dart';

enum ProductCategory {
  beer,
  snack,
  billiard,
  other
}

class Product {
  final String id;
  final String name;
  final double price;
  final ProductCategory category;
  final String description;
  int stockQuantity;
  final String? imageUrl;
  final DateTime createdAt;
  DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.stockQuantity,
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  Product copyWith({
    String? id,
    String? name,
    double? price,
    ProductCategory? category,
    String? description,
    int? stockQuantity,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      description: description ?? this.description,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category.toString(),
      'description': description,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      category: ProductCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => ProductCategory.other,
      ),
      description: map['description'],
      stockQuantity: map['stockQuantity'],
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}