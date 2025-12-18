import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = true;
  StreamSubscription? _ordersSubscription;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  // Getter khusus untuk memisahkan pesanan sebagai pembeli dan penjual
  List<OrderModel> get buyingOrders => _orders
      .where((order) => order.buyerId == _auth.currentUser?.uid)
      .toList();

  List<OrderModel> get sellingOrders => _orders
      .where((order) => order.sellerId == _auth.currentUser?.uid)
      .toList();

  OrderProvider() {
    _initializeOrders();
  }

  void _initializeOrders() {
    _auth.authStateChanges().listen((user) {
      _ordersSubscription?.cancel();
      if (user != null) {
        _loadOrders(user.uid);
      } else {
        _orders = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _loadOrders(String userId) {
    // Mengambil semua order di mana user terlibat (baik sbg buyer maupun seller)
    _ordersSubscription = _firestore
        .collection('orders')
        .where(
          Filter.or(
            Filter('buyerId', isEqualTo: userId),
            Filter('sellerId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .listen((snapshot) {
          _orders = snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();

          // Sorting manual di client side karena keterbatasan query majemuk Firestore
          _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _isLoading = false;
          notifyListeners();
        });
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

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
