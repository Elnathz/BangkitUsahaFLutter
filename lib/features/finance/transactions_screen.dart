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

  // Mock data transactions
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
      id: '6',
      type: TransactionType.expense,
      category: 'Bahan Baku',
      amount: 200000,
      description: 'Pembelian bumbu dan rempah',
      date: DateTime(2025, 11, 30),
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

  // Weekly data
  final PeriodData weeklyData = PeriodData(
    revenue: 4850000,
    revenueChange: 12.5,
    orders: 28,
  );

  // Monthly data
  final PeriodData monthlyData = PeriodData(
    revenue: 18500000,
    revenueChange: 15.3,
    orders: 95,
  );

  // Calculated values
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

  // Handle add transaction
  void handleAddTransaction(Transaction transaction) {
    setState(() {
      transactions.insert(0, transaction);
    });
  }

  // Navigate to finance log
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header with gradient
          _buildHeader(),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 16),

                // Finance Log Access Card
                _buildFinanceLogCard(),

                const SizedBox(height: 24),

                // Recent Transactions
                _buildRecentTransactionsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header with gradient background
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keuangan',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Period Selector
          _buildPeriodSelector(),

          const SizedBox(height: 16),

          // Revenue Summary Card
          _buildRevenueSummaryCard(),

          const SizedBox(height: 16),

          // Balance Summary Card
          _buildBalanceSummaryCard(),
        ],
      ),
    );
  }

  // Period selector toggle
  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildPeriodButton('week', 'Mingguan')),
          Expanded(child: _buildPeriodButton('month', 'Bulanan')),
        ],
      ),
    );
  }

  // Period button
  Widget _buildPeriodButton(String period, String label) {
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF16A34A) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Revenue summary card
  Widget _buildRevenueSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pendapatan',
                    style: TextStyle(fontSize: 14, color: Color(0xFFDCFCE7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(periodData.revenue)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: periodData.revenueChange > 0
                      ? Colors.white.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      periodData.revenueChange > 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${periodData.revenueChange.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${selectedPeriod == 'week' ? '7 hari terakhir' : '30 hari terakhir'} • ${periodData.orders} pesanan',
            style: const TextStyle(fontSize: 12, color: Color(0xFFDCFCE7)),
          ),
        ],
      ),
    );
  }

  // Balance summary card
  Widget _buildBalanceSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Saat Ini',
            style: TextStyle(fontSize: 14, color: Color(0xFFDCFCE7)),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${NumberFormat('#,###', 'id_ID').format(balance)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.arrow_upward,
                          size: 16,
                          color: Color(0xFFDCFCE7),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Pemasukan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFDCFCE7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(totalIncome)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: Color(0xFFDCFCE7),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Pengeluaran',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFDCFCE7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(totalExpense)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Finance log access card
  Widget _buildFinanceLogCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFBBF7D0), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFDBEAFE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: navigateToFinanceLog,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Aktivitas Keuangan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Kelola transaksi & lihat riwayat lengkap',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Recent transactions section
  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: navigateToFinanceLog,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...transactions.take(3).map((transaction) {
          return _buildTransactionCard(transaction);
        }).toList(),
      ],
    );
  }

  // Transaction card
  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isIncome
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncome
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(transaction.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '${isIncome ? '+' : '-'}Rp ${NumberFormat('#,###', 'id_ID').format(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
