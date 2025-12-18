import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  StreamSubscription? _transactionSubscription;

  // Getters yang diminta oleh Screen
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get totalBalance => _totalIncome - _totalExpense;

  TransactionProvider() {
    _initTransactions();
  }

  void _initTransactions() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToTransactions(user.uid);
      } else {
        _transactions = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _listenToTransactions(String userId) {
    _isLoading = true;
    notifyListeners();

    _transactionSubscription?.cancel();
    _transactionSubscription = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _transactions = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              // Konversi timestamp ke DateTime agar mudah dipakai UI
              if (data['timestamp'] is Timestamp) {
                data['date'] = (data['timestamp'] as Timestamp).toDate();
              } else {
                data['date'] = DateTime.now();
              }
              return data;
            }).toList();

            _calculateTotals();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Error listening to transactions: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _calculateTotals() {
    _totalIncome = 0.0;
    _totalExpense = 0.0;

    for (var tx in _transactions) {
      final amount = (tx['amount'] ?? 0.0).toDouble();
      if (tx['type'] == 'income') {
        _totalIncome += amount;
      } else if (tx['type'] == 'expense') {
        _totalExpense += amount;
      }
    }
  }

  // Method generic untuk menambah transaksi (diminta oleh UI)
  Future<void> addTransaction({
    required double amount,
    required String description,
    required String type, // 'income' atau 'expense'
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('transactions').add({
        'userId': userId,
        'amount': amount,
        'type': type,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Tidak perlu notifyListeners() manual karena stream listener akan menangkap perubahan
    } catch (e) {
      debugPrint("Error adding transaction: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
