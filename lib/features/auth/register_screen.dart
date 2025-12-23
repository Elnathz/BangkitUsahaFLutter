import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../home/main_wrapper.dart'; // Benar (Mencari di folder features/home/)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // Nama Toko atau Nama Pengguna
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(); // Khusus Penjual
  final _hoursCtrl = TextEditingController(); // Khusus Penjual

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // State untuk Role: true = Penjual, false = Pembeli
  bool _isSeller = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // 1. Validasi Input Umum
    if (_emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _nameCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty) {
      _showToast("Harap isi semua data wajib", ToastificationType.warning);
      return;
    }

    // 2. Validasi Khusus Penjual
    if (_isSeller) {
      if (_addressCtrl.text.isEmpty || _hoursCtrl.text.isEmpty) {
        _showToast("Penjual wajib mengisi Alamat & Jam Operasional",
            ToastificationType.warning);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // 3. Buat Akun di Firebase Auth
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // 4. Update Display Name di Auth
        await user.updateDisplayName(_nameCtrl.text.trim());

        // 5. Siapkan Data Firestore
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': user.email,
          'phoneNumber': _phoneCtrl.text.trim(),
          'role': _isSeller ? 'seller' : 'buyer', // Penanda Role
          'createdAt': FieldValue.serverTimestamp(),
          'image': '', // Foto kosong dulu
        };

        if (_isSeller) {
          // Data Khusus Penjual
          userData['storeName'] = _nameCtrl.text.trim();
          userData['ownerName'] = _nameCtrl.text.trim(); // Default owner name
          userData['address'] = _addressCtrl.text.trim();
          userData['openingHours'] = _hoursCtrl.text.trim();
          userData['rating'] = 0.0;
          userData['totalReviews'] = 0;
          userData['totalSales'] = 0;
        } else {
          // Data Khusus Pembeli
          userData['userName'] = _nameCtrl.text.trim();
          // Pembeli juga bisa punya ownerName agar kompatibel dgn chat
          userData['ownerName'] = _nameCtrl.text.trim();
        }

        // 6. Simpan ke Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);

        if (mounted) {
          _showToast("Registrasi Berhasil!", ToastificationType.success);
          // Pindah ke Halaman Utama (MainWrapper) dan hapus history back
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainWrapper()),
                (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Terjadi kesalahan";
      if (e.code == 'weak-password') msg = "Password terlalu lemah";
      if (e.code == 'email-already-in-use') msg = "Email sudah terdaftar";
      _showToast(msg, ToastificationType.error);
    } catch (e) {
      _showToast("Gagal daftar: $e", ToastificationType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(msg),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme
        .of(context)
        .primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Buat Akun Baru",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange, // Update to orange
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Silakan lengkapi data diri Anda",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // --- PILIHAN ROLE (Tab Switch) ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildRoleButton("Pembeli", false)),
                    Expanded(child: _buildRoleButton("Penjual", true)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- FORM INPUT ---

              // 1. Nama (Label Dinamis)
              TextField(
                controller: _nameCtrl,
                decoration: _inputDecor(
                  _isSeller ? "Nama Toko" : "Nama Pengguna",
                  _isSeller ? LucideIcons.store : LucideIcons.user,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecor("Email", LucideIcons.mail),
              ),
              const SizedBox(height: 16),

              // 3. No. Telepon
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecor("No. Telepon", LucideIcons.phone),
              ),
              const SizedBox(height: 16),

              // 4. Password
              TextField(
                controller: _passCtrl,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecor("Kata Sandi", LucideIcons.lock)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- FIELD KHUSUS PENJUAL ---
              if (_isSeller) ...[
                const Divider(height: 32),
                const Text(
                  "Informasi Toko",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Alamat (Lokasi)
                TextField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: _inputDecor("Alamat Lengkap", LucideIcons.mapPin),
                ),
                const SizedBox(height: 16),

                // Jam Operasional
                TextField(
                  controller: _hoursCtrl,
                  decoration: _inputDecor(
                      "Jam Operasional (Contoh: 08:00 - 17:00)",
                      LucideIcons.clock),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 32),

              // TOMBOL DAFTAR
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Explicitly set to orange
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isSeller
                      ? "DAFTAR SEBAGAI PENJUAL"
                      : "DAFTAR SEBAGAI PEMBELI",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper: Tombol Pilihan Role
  Widget _buildRoleButton(String title, bool isRoleSeller) {
    final isSelected = _isSeller == isRoleSeller;
    // Change primaryColor to orange
    const primaryColor = Colors.orange;

    return GestureDetector(
      onTap: () => setState(() => _isSeller = isRoleSeller),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: isSelected ? null : Border.all(
              color: Colors.grey[300]!), // Added border for unselected
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Widget Helper: Dekorasi Input
  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      // Changed to orange
      filled: true,
      fillColor: Colors.orange.withOpacity(0.05),
      // Matches login screen's subtle orange fill
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Colors.orange, width: 2), // Orange focus border
      ),
    );
  }
}