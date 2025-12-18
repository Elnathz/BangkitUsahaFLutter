// FILE: providers/product_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ProductModel> _products = [];
  bool _isLoading = true;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  List<ProductModel> get myProducts {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    return _products.where((p) => p.sellerId == userId).toList();
  }

  List<ProductModel> get marketplaceProducts {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return _products;
    return _products.where((p) => p.sellerId != userId).toList();
  }

  ProductProvider() {
    _initializeProducts();
  }

  void _initializeProducts() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadProducts();
      } else {
        _products = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _loadProducts() {
    _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').add(product.toMap());
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('products').doc(id).update(data);
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }
}

