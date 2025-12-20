enum TransactionType {
  income,
  expense,
}

class Transaction {
  final String id;
  final TransactionType type;
  final String category;
  final double amount;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  // Helper untuk copy with
  Transaction copyWith({
    String? id,
    TransactionType? type,
    String? category,
    double? amount,
    String? description,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  // Convert to JSON (untuk future backend integration)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  // Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'] == 'income' 
          ? TransactionType.income 
          : TransactionType.expense,
      category: json['category'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
    );
  }
}

// Data class untuk periode summary
class PeriodData {
  final double revenue;
  final double revenueChange;
  final int orders;

  PeriodData({
    required this.revenue,
    required this.revenueChange,
    required this.orders,
  });
}