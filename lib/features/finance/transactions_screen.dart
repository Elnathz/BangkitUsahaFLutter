import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
// Ensure this path matches your folder structure
import './models/transaction_model.dart';
import './screens/finance_log_page.dart'; // Adjusted path if they are in the same folder
import '../chat/chat_screen.dart';
import '../notifications/notification_screen.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String selectedPeriod = 'week';

  // --- MOCK DATA (Fixed to use TransactionModel) ---
  List<TransactionModel> transactions = [
    TransactionModel(
      id: '1',
      type: TransactionType.income,
      category: 'Penjualan Produk',
      amount: 250000,
      title: 'Penjualan Keripik Singkong', // Changed description to title
      date: DateTime(2025, 12, 3),
    ),
    TransactionModel(
      id: '2',
      type: TransactionType.expense,
      category: 'Bahan Baku',
      amount: 150000,
      title: 'Pembelian singkong 10kg',
      date: DateTime(2025, 12, 2),
    ),
    TransactionModel(
      id: '3',
      type: TransactionType.income,
      category: 'Jasa',
      amount: 500000,
      title: 'Konsultasi Bisnis',
      date: DateTime(2025, 12, 1),
    ),
    TransactionModel(
      id: '4',
      type: TransactionType.expense,
      category: 'Operasional',
      amount: 50000,
      title: 'Bensin pengiriman',
      date: DateTime(2025, 11, 30),
    ),
    TransactionModel(
      id: '5',
      type: TransactionType.income,
      category: 'Penjualan Produk',
      amount: 1200000,
      title: 'Pesanan Katering',
      date: DateTime(2025, 11, 28),
    ),
  ];

  final PeriodData weeklyData = PeriodData(
    revenue: 4850000,
    revenueChange: 12.5,
    orders: 28,
  );
  final PeriodData monthlyData = PeriodData(
    revenue: 18500000,
    revenueChange: 15.3,
    orders: 95,
  );

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
  double get totalExpense => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
  double get balance => totalIncome - totalExpense;
  PeriodData get periodData =>
      selectedPeriod == 'week' ? weeklyData : monthlyData;

  void handleAddTransaction(TransactionModel transaction) {
    setState(() {
      transactions.insert(0, transaction);
    });
  }

  // NOTE: I commented out onAddTransaction because FinanceLogPage likely
  // doesn't support it yet based on your error logs.
  void navigateToFinanceLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinanceLogPage(
          transactions: transactions,
          // onAddTransaction: handleAddTransaction, // Uncomment if FinanceLogPage accepts this
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // --- HEADER FIXED ---
          SizedBox(
            height: 340,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Header
                Container(
                  height: 280,
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, const Color(0xFF503C37)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ROW (JUDUL + TOMBOL) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Keuangan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              _buildHeaderIcon(
                                context,
                                LucideIcons.messageCircle,
                                const ChatScreen(),
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderIcon(
                                context,
                                LucideIcons.bell,
                                const NotificationScreen(),
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderIcon(
                                context,
                                Icons.history,
                                FinanceLogPage(
                                  transactions: transactions,
                                  // onAddTransaction: handleAddTransaction, // Check FinanceLogPage
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Total Saldo Saat Ini',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(balance)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // SUMMARY CARD
                Positioned(
                  bottom: 10,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            title: 'Pemasukan',
                            amount: totalIncome,
                            color: Colors.green,
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[200],
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            title: 'Pengeluaran',
                            amount: totalExpense,
                            color: Colors.red,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- CONTENT LIST ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ringkasan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    _buildPeriodSelector(primaryColor),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRevenueCard(primaryColor),
                const SizedBox(height: 24),
                const Text(
                  "Riwayat Terbaru",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...transactions.take(5).map((transaction) {
                  return _buildProfessionalTransactionTile(transaction);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildHeaderIcon(
      BuildContext context,
      IconData icon,
      Widget destination,
      ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Rp ${NumberFormat.compact(locale: "id_ID").format(amount)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Omzet ${selectedPeriod == 'week' ? 'Mingguan' : 'Bulanan'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(periodData.revenue)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: periodData.revenueChange >= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      periodData.revenueChange >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: periodData.revenueChange >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${periodData.revenueChange}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: periodData.revenueChange >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.grey[100],
            color: primaryColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text(
            "${periodData.orders} pesanan berhasil",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!), // Added border for clarity
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          _periodButton('week', 'Minggu', primaryColor),
          _periodButton('month', 'Bulan', primaryColor),
        ],
      ),
    );
  }

  Widget _periodButton(String value, String label, Color primaryColor) {
    final isSelected = selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = value),
      child: AnimatedContainer( // Added animation for smooth transition
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primaryColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalTransactionTile(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome
                ? Icons.monetization_on_outlined
                : Icons.shopping_bag_outlined,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              transaction.title, // Fixed: using title instead of description
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('d MMM yyyy', 'id_ID').format(transaction.date),
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${isIncome ? '+' : '-'} ${NumberFormat.compactCurrency(locale: 'id_ID', symbol: '').format(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// --- ADDED MISSING CLASS DEFINITION ---
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