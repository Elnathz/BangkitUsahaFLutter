import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String category;
  final String description;
  final String image;
  final String sellerId;
  final String sellerName;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.description,
    required this.image,
    required this.sellerId,
    required this.sellerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'description': description,
      'image': image,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      stock: (map['stock'] ?? 0).toInt(),
      category: map['category'] ?? 'Umum',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? 'Penjual',
    );
  }
}
