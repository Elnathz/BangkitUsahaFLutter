import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../transaction_model.dart';

class AddTransactionDialog extends StatefulWidget {
  final Function(Transaction) onAdd;

  const AddTransactionDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType selectedType = TransactionType.income;

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: selectedType,
      category: _categoryController.text,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text,
      date: DateTime.now(),
    );

    widget.onAdd(transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Tambah Transaksi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tambahkan transaksi baru ke pencatatan keuangan Anda.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),

                // Transaction Type
                const Text(
                  'Jenis Transaksi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        TransactionType.income,
                        'Pemasukan',
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeButton(
                        TransactionType.expense,
                        'Pengeluaran',
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category
                const Text(
                  'Kategori',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Penjualan Produk',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kategori harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Amount
                const Text(
                  'Jumlah (Rp)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah harus diisi';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Jumlah harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'Keterangan (Opsional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Tambahkan keterangan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Simpan Transaksi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label, IconData icon) {
    final isSelected = selectedType == type;
    final color = type == TransactionType.income
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Material(
      color: isSelected ? color : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 0,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedType = type;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
