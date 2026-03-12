import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String businessId;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final String category; // "Meals", "Drinks", "Soup", "Vegetables"
  final List<String> categories; // Kept for backwards compatibility if needed, or migration
  final List<String> customOptions; // e.g., ["Chicken", "Beef", "Pork"]
  final List<Map<String, dynamic>> optionGroups; // {"title": "Meat", "options": ["Chicken", "Beef"]}
  final bool isAvailable;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.description = '',
    required this.basePrice,
    this.imageUrl = '',
    this.category = 'Meals',
    this.categories = const [],
    this.customOptions = const [],
    this.optionGroups = const [],
    this.isAvailable = true,
    required this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      basePrice: (map['basePrice'] as num).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? 'Meals',
      categories: List<String>.from(map['categories'] ?? []),
      customOptions: List<String>.from(map['customOptions'] ?? []),
      optionGroups: map['optionGroups'] != null 
          ? List<Map<String, dynamic>>.from(map['optionGroups'].map((x) => Map<String, dynamic>.from(x)))
          : [],
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'imageUrl': imageUrl,
      'category': category,
      'categories': categories,
      'customOptions': customOptions,
      'optionGroups': optionGroups,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
