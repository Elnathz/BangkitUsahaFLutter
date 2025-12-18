import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all';

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddTransactionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final totalIncome = transactionProvider.totalIncome;
    final totalExpense = transactionProvider.totalExpense;
    final balance = totalIncome - totalExpense;

    List<TransactionModel> filteredTransactions =
        transactionProvider.transactions;
    if (_filter == 'income') {
      filteredTransactions = transactionProvider.transactions
          .where((t) => t.type == TransactionType.income)
          .toList();
    } else if (_filter == 'expense') {
      filteredTransactions = transactionProvider.transactions
          .where((t) => t.type == TransactionType.expense)
          .toList();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[700]!],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pencatatan Keuangan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Balance Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo Saat Ini (Cloud)',
                            style: TextStyle(
                              color: Colors.green[100],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(balance)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
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
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          size: 16,
                                          color: Colors.green[100],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pemasukan',
                                          style: TextStyle(
                                            color: Colors.green[100],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${NumberFormat('#,###', 'id_ID').format(totalIncome)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          size: 16,
                                          color: Colors.green[100],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pengeluaran',
                                          style: TextStyle(
                                            color: Colors.green[100],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${NumberFormat('#,###', 'id_ID').format(totalExpense)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add,
                        label: 'Catat Baru',
                        color: Colors.green[600]!,
                        onTap: _showAddTransactionDialog,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.download,
                        label: 'Export PDF',
                        color: Colors.grey[100]!,
                        textColor: Colors.grey[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur Export PDF akan segera tersedia',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.calendar_today,
                        label: 'Filter',
                        color: Colors.grey[100]!,
                        textColor: Colors.grey[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Filter tanggal akan segera tersedia',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      isSelected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pemasukan',
                      isSelected: _filter == 'income',
                      color: Colors.green,
                      onTap: () => setState(() => _filter = 'income'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pengeluaran',
                      isSelected: _filter == 'expense',
                      color: Colors.red,
                      onTap: () => setState(() => _filter = 'expense'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Transactions List
            Expanded(
              child: transactionProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada data transaksi.',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mulai catat keuangan Anda sekarang.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return _TransactionCard(transaction: transaction);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: textColor ?? Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: textColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isIncome ? Colors.green : Colors.red, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (transaction.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(transaction.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'} Rp ${NumberFormat('#,###', 'id_ID').format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green[700] : Colors.red[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTransactionDialog extends StatefulWidget {
  const _AddTransactionDialog();

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  TransactionType _type = TransactionType.income;
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_categoryController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi kategori dan jumlah uang')),
      );
      return;
    }

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      category: _categoryController.text,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text,
      date: DateTime.now(),
    );

    context.read<TransactionProvider>().addTransaction(transaction);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi tersimpan ke Cloud! ☁️')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Catat Transaksi',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Data akan disimpan ke server Bangkit Usaha.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Type Selector
              const Text('Jenis Transaksi'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _type = TransactionType.income),
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: const Text('Pemasukan'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _type == TransactionType.income
                            ? Colors.green[600]
                            : null,
                        foregroundColor: _type == TransactionType.income
                            ? Colors.white
                            : Colors.green[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _type = TransactionType.expense),
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      label: const Text('Pengeluaran'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _type == TransactionType.expense
                            ? Colors.red[600]
                            : null,
                        foregroundColor: _type == TransactionType.expense
                            ? Colors.white
                            : Colors.red[600],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Category
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'Contoh: Jual Beras / Beli Pupuk',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Amount
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (Opsional)',
                  hintText: 'Catatan tambahan...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
