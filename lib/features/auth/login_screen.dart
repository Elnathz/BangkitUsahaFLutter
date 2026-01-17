import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan import ini
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Login Email/Password
  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showToast("Email/No HP dan password harus diisi", ToastificationType.warning);
      return;
    }

    setState(() => _isLoading = true);

    String emailInput = _emailController.text.trim();
    String passwordInput = _passController.text.trim();

    // LOGIKA LOGIN NO HP (Konversi ke Email Dummy)
    // Cek jika input hanya angka atau diawali + (format HP)
    if (RegExp(r'^[0-9+]+$').hasMatch(emailInput)) {
      // Normalisasi nomor HP ke format 628... (Sesuai format di SettingsScreen)
      String cleanPhone = emailInput.replaceAll('+', '');
      if (cleanPhone.startsWith('0')) {
        cleanPhone = "62${cleanPhone.substring(1)}";
      } else if (!cleanPhone.startsWith('62')) {
        cleanPhone = "62$cleanPhone";
      }
      
      emailInput = "$cleanPhone@bangkit.usaha"; 
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailInput,
        password: passwordInput,
      );
      _showToast("Berhasil masuk!", ToastificationType.success);
    } on FirebaseAuthException catch (e) {
      String message = "Gagal masuk.";
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        message = "Nomor HP atau Email tidak terdaftar.";
      } else if (e.code == 'wrong-password') {
        message = "Password salah.";
      } else if (e.code == 'invalid-credential') {
        message = "Kombinasi Email/No HP dan Password tidak cocok.";
      } else if (e.code == 'user-disabled') {
        message = "Akun ini telah dinonaktifkan.";
      } else if (e.code == 'too-many-requests') {
        message = "Terlalu banyak percobaan gagal. Coba lagi nanti.";
      } else {
        message = e.message ?? "Terjadi kesalahan saat login.";
      }
      _showToast(message, ToastificationType.error);
    } catch (e) {
      _showToast("Terjadi kesalahan: $e", ToastificationType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Login Google
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      await _checkAndCreateUser(userCred.user);
      _showToast("Berhasil masuk dengan Google!", ToastificationType.success);
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In Error: $e');
      debugPrint('Stack trace: $stackTrace');
      String errorMessage = "Gagal login Google";
      if (e.toString().contains('ClientException')) {
        errorMessage = "Pastikan authorized origins dikonfigurasi di Google Cloud Console";
      }
      _showToast("$errorMessage: ${e.toString().split('\n').first}", ToastificationType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER: BUAT DATA USER JIKA BELUM ADA ---
  Future<void> _checkAndCreateUser(User? user) async {
    if (user == null) return;
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      
      if (!doc.exists) {
        String name = user.displayName ?? 'User';
        // Jika nama default dan ada nomor HP, gunakan format User XXXX
        if (name == 'User' && user.phoneNumber != null && user.phoneNumber!.length >= 4) {
           name = 'User ${user.phoneNumber!.substring(user.phoneNumber!.length - 4)}';
        }

        // Jika user baru (Register Otomatis), buat data default
        await userRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'role': 'buyer', // Default role pembeli
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
          'image': user.photoURL ?? '',
        });
      }
    } catch (e) {
      debugPrint("Gagal membuat data user: $e");
    }
  }

  // --- LOGIC LOGIN TELEPON (OTP) ---
  String? _verificationId;

  void _handlePhoneLogin() {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Masuk dengan No. HP"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan nomor WhatsApp/HP aktif Anda."),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Nomor HP (Contoh: 0812...)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyPhoneNumber(phoneController.text);
            },
            child: const Text("Kirim OTP"),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    // Format nomor: ganti 08... jadi +628...
    String formattedPhone = phoneNumber.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+62${formattedPhone.substring(1)}';
    } else if (formattedPhone.startsWith('62')) {
      formattedPhone = '+$formattedPhone';
    } else if (!formattedPhone.startsWith('+')) {
      // Jika user mengetik 812... tanpa +
      formattedPhone = '+62$formattedPhone';
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android: Otomatis login jika SMS terdeteksi
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          await _checkAndCreateUser(userCred.user); // Simpan data user
          _showToast("Login Berhasil!", ToastificationType.success);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("Phone Auth Error: ${e.code} - ${e.message}");
          setState(() => _isLoading = false);
          
          String errorMsg = "Gagal verifikasi: ${e.message}";
          if (e.code == 'invalid-app-credential') {
            errorMsg = "Verifikasi aplikasi gagal. Cek SHA-256 & Play Integrity API.";
          } else if (e.code == 'too-many-requests') {
            errorMsg = "Terlalu banyak percobaan. Gunakan nomor tes.";
          }
          
          _showToast(errorMsg, ToastificationType.error);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          _verificationId = verificationId;
          _showOtpDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast("Terjadi kesalahan: $e", ToastificationType.error);
    }
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Masukkan Kode OTP"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Kode 6 digit telah dikirim via SMS."),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: "000000",
                counterText: "",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final smsCode = otpController.text.trim();
              if (smsCode.length == 6 && _verificationId != null) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: _verificationId!,
                    smsCode: smsCode,
                  );
                  final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
                  await _checkAndCreateUser(userCred.user); // Simpan data user
                  _showToast("Login Berhasil!", ToastificationType.success);
                } catch (e) {
                  _showToast("Kode OTP Salah", ToastificationType.error);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
            child: const Text("Verifikasi"),
          ),
        ],
      ),
    );
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
                  // Background decorations (simulated with opacity)
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
                      LucideIcons.logIn,
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
                    "Solusi UMKM Modern",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Card
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
                          "Masuk",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937), // gray-800
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Masuk ke akun Anda untuk melanjutkan",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280), // gray-600
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email Input
                        const Text(
                          "Email / No. HP",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151), // gray-700
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Email atau Nomor HP",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB), // gray-50
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB), // gray-200
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6), // blue-500
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password Input
                        const Text(
                          "Password",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passController,
                          obscureText: !_isPasswordVisible,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: "Masukkan password",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                color: const Color(0xFF6B7280),
                                size: 20,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Lupa password?",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2563EB), // blue-600
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleEmailLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFF3B82F6).withOpacity(0.3),
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
                                      Icon(LucideIcons.logIn, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Masuk",
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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

                        // Google Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleGoogleLogin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Logo SVG equivalent
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image.network(
                                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        LucideIcons.chrome,
                                        size: 20,
                                        color: Color(0xFF4285F4),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Masuk dengan Google",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Phone Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handlePhoneLogin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(LucideIcons.phone,
                                    size: 20, color: Color(0xFF374151)),
                                SizedBox(width: 12),
                                Text("Masuk dengan No. HP",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF374151))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Belum punya akun? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                              child: const Text(
                                "Daftar sekarang",
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
}
