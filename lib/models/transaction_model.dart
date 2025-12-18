// FILE: models/transaction_model.dart
enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final TransactionType type;
  final String category;
  final double amount;
  final String description;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

