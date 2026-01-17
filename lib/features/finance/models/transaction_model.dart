import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;
  final String? orderId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.orderId,
  });

  // 1. Factory dari Order Toko (Otomatis)
  factory TransactionModel.fromOrder(Map<String, dynamic> map, String docId) {
    final timestamp = map['createdAt'] as Timestamp? ?? Timestamp.now();
    
    String displayTitle = 'Penjualan Produk';
    if (map['items'] != null && (map['items'] as List).isNotEmpty) {
      final firstItem = map['items'][0];
      displayTitle = firstItem['name'] ?? 'Produk';
      if ((map['items'] as List).length > 1) {
        displayTitle += ' & ${(map['items'] as List).length - 1} lainnya';
      }
    }

    return TransactionModel(
      id: docId,
      title: displayTitle,
      amount: (map['totalPrice'] ?? 0).toDouble(),
      type: TransactionType.income,
      date: timestamp.toDate(),
      category: 'Penjualan Online',
      orderId: docId,
    );
  }

  // 2. Factory dari Pengeluaran (Manual)
  factory TransactionModel.fromExpense(Map<String, dynamic> map, String docId) {
    final timestamp = map['date'] as Timestamp? ?? Timestamp.now();
    return TransactionModel(
      id: docId,
      title: map['title'] ?? 'Pengeluaran',
      amount: (map['amount'] ?? 0).toDouble(),
      type: TransactionType.expense,
      date: timestamp.toDate(),
      category: map['category'] ?? 'Operasional',
      orderId: null,
    );
  }

  // 3. Factory BARU: Pemasukan Manual (Misal: Penjualan Offline)
  factory TransactionModel.fromManualIncome(Map<String, dynamic> map, String docId) {
    final timestamp = map['date'] as Timestamp? ?? Timestamp.now();
    return TransactionModel(
      id: docId,
      title: map['title'] ?? 'Pemasukan Lain',
      amount: (map['amount'] ?? 0).toDouble(),
      type: TransactionType.income,
      date: timestamp.toDate(),
      category: map['category'] ?? 'Penjualan Offline',
      orderId: null,
    );
  }

  // 4. Factory dari Firestore (Wajib ada karena dipanggil di FinanceService)
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? 'Transaksi',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] ?? 'Umum',
      orderId: data['orderId'],
    );
  }
}