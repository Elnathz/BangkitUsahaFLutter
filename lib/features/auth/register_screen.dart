import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../home/main_wrapper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validation
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _confirmPassCtrl.text.isEmpty) {
      _showToast("Semua field harus diisi", ToastificationType.warning);
      return;
    }

    if (_passCtrl.text.length < 6) {
      _showToast("Password minimal 6 karakter", ToastificationType.warning);
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showToast(
        "Password dan konfirmasi password tidak sama",
        ToastificationType.warning,
      );
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'\S+@\S+\.\S+');
    if (!emailRegex.hasMatch(_emailCtrl.text)) {
      _showToast("Format email tidak valid", ToastificationType.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create account in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        // Update Display Name in Auth
        await user.updateDisplayName(_nameCtrl.text.trim());

        // Prepare Firestore data - Default role is seller (UMKM)
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': user.email,
          'phoneNumber': _phoneCtrl.text.trim(),
          'role': 'seller', // Default role as UMKM
          'createdAt': FieldValue.serverTimestamp(),
          'image': '',
          'storeName': _nameCtrl.text.trim(), // Use name as store name
          'ownerName': _nameCtrl.text.trim(),
          'address': '',
          'openingHours': '',
          'rating': 0.0,
          'totalReviews': 0,
          'totalSales': 0,
        };

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);

        if (mounted) {
          _showToast("Registrasi Berhasil!", ToastificationType.success);
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6), // blue-500
              Color(0xFF2563EB), // blue-600
              Color(0xFF1D4ED8), // blue-700
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),
                  // Logo/Brand Section
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.userPlus,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    "Bangkit Usaha",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    "Daftar Akun Baru",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Registration Form Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        const Text(
                          "Buat Akun",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Isi data untuk mendaftar",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full Name
                        _buildInputField(
                          label: "Nama Lengkap",
                          controller: _nameCtrl,
                          placeholder: "John Doe",
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _buildInputField(
                          label: "Email",
                          controller: _emailCtrl,
                          placeholder: "nama@email.com",
                          isRequired: true,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        _buildInputField(
                          label: "Nomor Telepon",
                          controller: _phoneCtrl,
                          placeholder: "08123456789",
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _buildInputField(
                          label: "Password",
                          controller: _passCtrl,
                          placeholder: "Minimal 6 karakter",
                          isRequired: true,
                          obscureText: !_showPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              color: const Color(0xFF6B7280),
                              size: 20,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        _buildInputField(
                          label: "Konfirmasi Password",
                          controller: _confirmPassCtrl,
                          placeholder: "Ulangi password",
                          isRequired: true,
                          obscureText: !_showConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              color: const Color(0xFF6B7280),
                              size: 20,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => setState(
                                      () => _showConfirmPassword =
                                          !_showConfirmPassword,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF3B82F6,
                              ).withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Memproses...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.userPlus, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Daftar",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFFE5E7EB)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "atau",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFFE5E7EB)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Sudah punya akun? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text(
                                "Masuk",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  Text(
                    "© 2026 Bangkit Usaha. Semua hak dilindungi.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool isRequired = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            children: isRequired
                ? [
                    const TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !_isLoading,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
