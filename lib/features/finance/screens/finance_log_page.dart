import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction_model.dart'; // Import model yang benar
// Jika file model ada di folder yang sama, gunakan import di atas.
// Jika di folder models/, sesuaikan pathnya: import '../models/transaction_model.dart';

class FinanceLogPage extends StatelessWidget {
  final List<TransactionModel> transactions;

  const FinanceLogPage({
    super.key, // Gunakan super parameter
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Group transactions by date
    final groupedTransactions = _groupTransactionsByDate(transactions);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat transaksi',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedTransactions.length,
              itemBuilder: (context, index) {
                final dateKey = groupedTransactions.keys.elementAt(index);
                final dayTransactions = groupedTransactions[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        dateKey,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    ...dayTransactions.map((t) => _buildTransactionCard(t, currencyFormat)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTransactionCard(TransactionModel t, NumberFormat currencyFormat) {
    final isIncome = t.type == TransactionType.income;
    final timeStr = DateFormat('HH:mm').format(t.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isIncome ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome ? LucideIcons.shoppingBag : LucideIcons.receipt,
            color: isIncome ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          t.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              timeStr,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                t.category,
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${currencyFormat.format(t.amount)}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Helper: Group transactions by Date String (e.g., "Hari Ini", "Kemarin", "12 Okt 2023")
  Map<String, List<TransactionModel>> _groupTransactionsByDate(List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};

    for (var t in transactions) {
      final dateKey = _getDateLabel(t.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(t);
    }
    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Hari Ini';
    } else if (checkDate == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    }
  }
}