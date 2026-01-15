import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/transaction_model.dart'; // Ubah path ke folder models
import 'widgets/add_transaction_dialog.dart';

class FinanceLogPage extends StatefulWidget {
  final List<TransactionModel> transactions;
  final Function(TransactionModel) onAddTransaction;

  const FinanceLogPage({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
  });

  @override
  State<FinanceLogPage> createState() => _FinanceLogPageState();
}

class _FinanceLogPageState extends State<FinanceLogPage> {
  String filter = 'all'; // 'all', 'income', 'expense'

  List<TransactionModel> get filteredTransactions {
    if (filter == 'all') return widget.transactions;
    if (filter == 'income') {
      return widget.transactions
          .where((t) => t.type == TransactionType.income)
          .toList();
    }
    return widget.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
  }

  int get incomeCount {
    return widget.transactions
        .where((t) => t.type == TransactionType.income)
        .length;
  }

  int get expenseCount {
    return widget.transactions
        .where((t) => t.type == TransactionType.expense)
        .length;
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );
  }

  void _handleExportData() {
    _showSnackbar('Data keuangan sedang diexport...', Colors.blue);
    Future.delayed(const Duration(milliseconds: 1500), () {
      _showSnackbar('Export selesai! File telah diunduh.', Colors.green);
    });
  }

  void _handleOpenFilter() {
    _showSnackbar('Filter tanggal akan segera tersedia', Colors.blue);
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Action Buttons
                _buildActionButtons(),

                const SizedBox(height: 24),

                // Filter Tabs
                _buildFilterTabs(),

                const SizedBox(height: 16),

                // Transactions List
                if (filteredTransactions.isEmpty)
                  _buildEmptyState()
                else
                  ...filteredTransactions.map((transaction) {
                    return _buildTransactionCard(transaction);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Aktivitas Keuangan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Kelola semua transaksi Anda',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action buttons grid
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Add button
        Expanded(
          child: _buildActionButton(
            icon: Icons.add,
            label: 'Tambah',
            color: const Color(0xFF16A34A),
            onTap: _showAddTransactionDialog,
          ),
        ),
        const SizedBox(width: 12),

        // Export button
        Expanded(
          child: _buildActionButton(
            icon: Icons.download,
            label: 'Export',
            color: null,
            onTap: _handleExportData,
          ),
        ),
        const SizedBox(width: 12),

        // Filter button
        Expanded(
          child: _buildActionButton(
            icon: Icons.calendar_today,
            label: 'Filter',
            color: null,
            onTap: _handleOpenFilter,
          ),
        ),
      ],
    );
  }

  // Action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color? color,
    required VoidCallback onTap,
  }) {
    final isColored = color != null;

    return Material(
      color: isColored ? color : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: isColored ? 0 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: isColored
                ? null
                : Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isColored ? Colors.white : const Color(0xFF374151),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isColored ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter tabs
  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            'all',
            'Semua (${widget.transactions.length})',
            null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'income',
            'Pemasukan ($incomeCount)',
            const Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'expense',
            'Pengeluaran ($expenseCount)',
            const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  // Filter chip
  Widget _buildFilterChip(String value, String label, Color? activeColor) {
    final isActive = filter == value;
    final chipColor = isActive
        ? (activeColor ?? Theme.of(context).primaryColor)
        : Colors.white;

    return Material(
      color: chipColor,
      borderRadius: BorderRadius.circular(20),
      elevation: isActive ? 2 : 0,
      child: InkWell(
        onTap: () {
          setState(() {
            filter = value;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: isActive
                ? null
                : Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value == 'income' && isActive)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              if (value == 'expense' && isActive)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.arrow_downward,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Transaction card
  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Future: navigate to transaction detail
        },
        borderRadius: BorderRadius.circular(12),
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
                    if (transaction.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'd MMMM yyyy',
                        'id_ID',
                      ).format(transaction.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

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
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada transaksi',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              filter == 'all'
                  ? 'Tambahkan transaksi pertama Anda'
                  : 'Tidak ada ${filter == 'income' ? 'pemasukan' : 'pengeluaran'}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
