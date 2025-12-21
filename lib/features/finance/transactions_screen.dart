import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_model.dart';
import 'finance_log_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String selectedPeriod = 'week'; // 'week' or 'month'

  // --- MOCK DATA ---
  List<Transaction> transactions = [
    Transaction(
      id: '1',
      type: TransactionType.income,
      category: 'Penjualan Produk',
      amount: 250000,
      description: 'Penjualan Keripik Singkong',
      date: DateTime(2025, 12, 3),
    ),
    Transaction(
      id: '2',
      type: TransactionType.expense,
      category: 'Bahan Baku',
      amount: 150000,
      description: 'Pembelian singkong 10kg',
      date: DateTime(2025, 12, 2),
    ),
    Transaction(
      id: '3',
      type: TransactionType.income,
      category: 'Penjualan Produk',
      amount: 180000,
      description: 'Penjualan Sambal Matah',
      date: DateTime(2025, 12, 2),
    ),
    Transaction(
      id: '4',
      type: TransactionType.expense,
      category: 'Operasional',
      amount: 50000,
      description: 'Biaya listrik',
      date: DateTime(2025, 12, 1),
    ),
    Transaction(
      id: '5',
      type: TransactionType.income,
      category: 'Penjualan Produk',
      amount: 320000,
      description: 'Penjualan Kue Lapis',
      date: DateTime(2025, 12, 1),
    ),
    Transaction(
      id: '7',
      type: TransactionType.income,
      category: 'Penjualan Produk',
      amount: 420000,
      description: 'Penjualan Brownies Premium',
      date: DateTime(2025, 11, 29),
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

  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  PeriodData get periodData =>
      selectedPeriod == 'week' ? weeklyData : monthlyData;

  void handleAddTransaction(Transaction transaction) {
    setState(() {
      transactions.insert(0, transaction);
    });
  }

  void navigateToFinanceLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinanceLogPage(
          transactions: transactions,
          onAddTransaction: handleAddTransaction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // --- BAGIAN FIXED (Header & Summary Card) ---
          SizedBox(
            height: 340, // Tinggi area tetap
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Background Header
                Container(
                  height: 280,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Keuangan Toko',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: navigateToFinanceLog,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Total Saldo Saat Ini',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(balance)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. KARTU PEMASUKAN & PENGELUARAN
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

          // --- BAGIAN SCROLLABLE ---
          Expanded(
            child: ListView(
              // PERUBAHAN PENTING DI SINI:
              // Bottom padding diubah jadi 100 agar tidak ketutup Nav Bar
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

  // --- WIDGET HELPER ---

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
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Rp ${NumberFormat.compact(locale: "id_ID").format(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Omzet ${selectedPeriod == 'week' ? 'Mingguan' : 'Bulanan'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(periodData.revenue)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
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
      child: Container(
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

  Widget _buildProfessionalTransactionTile(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome
        ? Icons.monetization_on_outlined
        : Icons.shopping_bag_outlined;

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
          child: Icon(icon, color: color, size: 24),
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
              transaction.description,
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
        trailing: Text(
          '${isIncome ? '+' : '-'} ${NumberFormat.compactCurrency(locale: 'id_ID', symbol: '').format(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ),
    );
  }
}
