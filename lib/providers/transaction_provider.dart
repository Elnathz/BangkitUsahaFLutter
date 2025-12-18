// FILE: providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  TransactionProvider() {
    _initializeTransactions();
  }

  void _initializeTransactions() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadTransactions();
      } else {
        _transactions = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _loadTransactions() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final data = transaction.toMap();
      data['userId'] = userId;
      await _firestore.collection('transactions').add(data);
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _firestore.collection('transactions').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }
}