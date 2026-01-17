import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/finance/models/transaction_model.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Menggunakan koleksi 'transactions_v2' agar database benar-benar baru dan bersih (mulai dari 0)
  Stream<List<TransactionModel>> getNewTransactions() {
    final user = _auth.currentUser;
    // Jika tidak ada user login, kembalikan list kosong (0 data)
    if (user == null) return Stream.value([]);
    return _firestore
        .collection(
          'transactions_v3',
        ) // Ganti nama koleksi untuk meninggalkan data lama
        .where(
          'userId',
          isEqualTo: user.uid,
        ) // Filter mutlak berdasarkan User ID
        .orderBy('date', descending: true)
        .limit(30) // BATASI LOAD: Hanya ambil 30 transaksi terbaru
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Tambahkan fungsi ini agar bisa menyimpan ke transactions_v3
  Future<void> addManualIncome({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('transactions_v3').add({
      'userId': user.uid,
      'title': title,
      'amount': amount,
      'type': 'income',
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('transactions_v3').add({
      'userId': user.uid,
      'title': title,
      'amount': amount,
      'type': 'expense',
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
