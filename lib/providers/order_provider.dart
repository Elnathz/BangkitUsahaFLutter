// FILE: providers/order_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = true;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  List<OrderModel> get buyingOrders {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    return _orders.where((o) => o.buyerId == userId).toList();
  }

  List<OrderModel> get sellingOrders {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    return _orders.where((o) => o.sellerId == userId).toList();
  }

  OrderProvider() {
    _initializeOrders();
  }

  void _initializeOrders() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadOrders();
      } else {
        _orders = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _loadOrders() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Load orders where user is either buyer or seller
    _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((buyingSnapshot) {
      _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((sellingSnapshot) {
        final buyingOrders = buyingSnapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList();
        final sellingOrders = sellingSnapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList();

        _orders = [...buyingOrders, ...sellingOrders];
        _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        notifyListeners();
      });
    });
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').add(order.toMap());
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }
}