import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TAMBAHAN: Untuk FilteringTextInputFormatter
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../models/transaction_model.dart';
import '../services/finance_service.dart';
import 'finance_log_page.dart';

// Import Chat & Notification
import '../../chat/chat_screen.dart';
import '../../notifications/notification_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FinanceService _financeService = FinanceService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _financeService.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? [];

                double totalIncome = 0;
                double totalExpense = 0;

                for (var t in transactions) {
                  if (t.type == TransactionType.income) {
                    totalIncome += t.amount;
                  } else {
                    totalExpense += t.amount;
                  }
                }
                double currentBalance = totalIncome - totalExpense;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildBalanceCard(currentBalance),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Pemasukan',
                                    totalIncome,
                                    Colors.green,
                                    LucideIcons.arrowDownCircle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    'Pengeluaran',
                                    totalExpense,
                                    Colors.red,
                                    LucideIcons.arrowUpCircle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Aktivitas Keuangan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (transactions.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FinanceLogPage(
                                          transactions: transactions),
                                    ),
                                  );
                                },
                                child: const Text("Lihat Semua"),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (transactions.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.clipboardList,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("Belum ada transaksi",
                                  style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 8),
                              Text(
                                "Penjualan toko akan muncul otomatis di sini",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final transaction = transactions[index];
                            return _buildTransactionItem(transaction);
                          },
                          childCount: transactions.length > 5
                              ? 5
                              : transactions.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      
      // FAB BARU: CATAT TRANSAKSI
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTransactionDialog(context),
          backgroundColor: const Color(0xFF5D4037),
          icon: const Icon(LucideIcons.penTool, color: Colors.white),
          label: const Text("Catat Transaksi",
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // --- LOGIC DIALOG BARU (MULTIFUNGSI) ---
  void _showAddTransactionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    
    // State lokal untuk dialog
    bool isIncome = false; // Default Pengeluaran
    String selectedCategory = 'Operasional';

    // List Kategori sesuai tipe
    final List<String> expenseCategories = [
      'Operasional', 'Bahan Baku', 'Gaji', 'Listrik/Air', 'Sewa', 'Lainnya'
    ];
    final List<String> incomeCategories = [
      'Penjualan Offline', 'Investasi', 'Modal Tambahan', 'Lainnya'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Catat Transaksi Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. SWITCH BUTTON (Pemasukan / Pengeluaran)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isIncome = false;
                                selectedCategory = expenseCategories.first;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isIncome ? Colors.red[50] : null,
                                borderRadius: BorderRadius.circular(8),
                                border: !isIncome ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
                              ),
                              child: Center(
                                child: Text(
                                  "Pengeluaran",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !isIncome ? Colors.red : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isIncome = true;
                                selectedCategory = incomeCategories.first;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isIncome ? Colors.green[50] : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isIncome ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
                              ),
                              child: Center(
                                child: Text(
                                  "Pemasukan",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. INPUT FIELD
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan',
                      hintText: isIncome ? 'Mis: Jual Kardus Bekas' : 'Mis: Beli Tepung',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // INPUT NOMINAL (HANYA ANGKA)
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number, // Keyboard angka
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly // Hanya menerima digit 0-9
                    ],
                    decoration: InputDecoration(
                      labelText: 'Nominal (Rp)',
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 3. DROPDOWN KATEGORI
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: (isIncome ? incomeCategories : expenseCategories)
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedCategory = val!),
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      amountController.text.isNotEmpty) {
                    
                    final amount = double.tryParse(amountController.text) ?? 0;
                    
                    if (isIncome) {
                      _financeService.addManualIncome(
                        title: titleController.text,
                        amount: amount,
                        category: selectedCategory,
                        date: DateTime.now(),
                      );
                    } else {
                      _financeService.addExpense(
                        title: titleController.text,
                        amount: amount,
                        category: selectedCategory,
                        date: DateTime.now(),
                      );
                    }
                    
                    Navigator.pop(ctx);
                    toastification.show(
                      context: context,
                      title: Text('${isIncome ? "Pemasukan" : "Pengeluaran"} berhasil dicatat'),
                      type: ToastificationType.success,
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIncome ? Colors.green : const Color(0xFF5D4037),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.arrowLeft,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Keuangan Bisnis",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIcon(context, LucideIcons.messageCircle, const ChatScreen()),
              const SizedBox(width: 8),
              _buildHeaderIcon(context, LucideIcons.bell, const NotificationScreen()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context, IconData icon, Widget destination) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => destination)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Saldo',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(balance),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(LucideIcons.checkCircle,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text('Terintegrasi dengan History Toko',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(amount),
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final isIncome = t.type == TransactionType.income;
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(t.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
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
          ),
        ),
        title: Text(
          t.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.category,
                    style: TextStyle(color: Colors.grey[700], fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(dateStr,
                    style: TextStyle(color: Colors.grey[400], fontSize: 10)),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${_currencyFormat.format(t.amount)}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}