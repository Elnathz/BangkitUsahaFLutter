import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/transaction_model.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // KEMBALI KE VERSI LAMA: Menggabungkan stream dari orders, manual_incomes, dan expenses
  Stream<List<TransactionModel>> getTransactions() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    // 1. Stream Order Toko (Income Auto)
    final ordersStream = _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromOrder(doc.data(), doc.id))
            .toList());

    // 2. Stream Pemasukan Manual (Income Manual)
    final manualIncomeStream = _firestore
        .collection('manual_incomes')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromManualIncome(doc.data(), doc.id))
            .toList());

    // 3. Stream Pengeluaran (Expense Manual)
    final expensesStream = _firestore
        .collection('expenses')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromExpense(doc.data(), doc.id))
            .toList());

    // Gabungkan ketiganya menggunakan RxDart
    return CombineLatestStream.list([ordersStream, manualIncomeStream, expensesStream])
        .map((list) {
      final allTransactions = list.expand((x) => x).toList();
      // Urutkan dari yang terbaru
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      return allTransactions;
    });
  }

  // Tambah Pengeluaran Manual (Ke koleksi expenses)
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('expenses').add({
      'userId': uid,
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Tambah Pemasukan Manual (Ke koleksi manual_incomes)
  Future<void> addManualIncome({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('manual_incomes').add({
      'userId': uid,
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
