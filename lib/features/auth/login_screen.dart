import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // State to toggle password visibility

  // Login Email/Password
  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showToast("Email dan Password harus diisi", ToastificationType.warning);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _showToast(e.message ?? "Gagal login", ToastificationType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Login Google
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      // --- PERUBAHAN ADA DI SINI ---
      // Kita inisialisasi GoogleSignIn dengan clientId khusus untuk WEB
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // PASTE KODE CLIENT ID DARI FIREBASE DI BAWAH INI:
        clientId:
            '1083523484604-h2im51pc98fnofml1lpjfs2k324fo162.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // -----------------------------

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
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      _showToast("Gagal login Google: $e", ToastificationType.error);
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
      backgroundColor: Colors.white, // Background mainly white
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LOGO FRONT AND CENTER
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    // Using the asset found in your dashboard_screen.dart
                    image: const DecorationImage(
                      image: AssetImage('assets/images/bangkitusaha.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. HOOK TEXT
              const Text(
                "Kembangkan bisnismu\nbersama kami!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange, // Orange palette
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // 3. EMAIL INPUT (with Mail Icon)
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(
                    LucideIcons.mail,
                    color: Colors.orange,
                  ),
                  filled: true,
                  fillColor: Colors.orange.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. PASSWORD INPUT (with Lock Icon & Eye Toggle)
              TextField(
                controller: _passController,
                obscureText: !_isPasswordVisible, // Toggle logic
                decoration: InputDecoration(
                  labelText: "Kata Sandi",
                  prefixIcon: const Icon(
                    LucideIcons.lock,
                    color: Colors.orange,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.orange.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. LOGIN BUTTON (Orange)
              ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Orange
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "MASUK",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("atau", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // 6. GOOGLE BUTTON (Chrome Icon)
              // ...
              OutlinedButton.icon(
                onPressed: _handleGoogleLogin,
                icon: Container(
                  width: 24,
                  height: 24,
                  child: Image.network(
                    // LINK LOGO RESMI GOOGLE (PNG Transparan)
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/225px-Google_%22G%22_logo.svg.png',
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Jika internet mati, muncul icon globe sebagai cadangan
                      return const Icon(LucideIcons.globe, color: Colors.grey);
                    },
                  ),
                ),
                label: const Text(
                  "Masuk dengan Google",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),

              // ...
              const SizedBox(height: 32),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Belum punya akun? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to Register Screen
                    },
                    child: const Text(
                      "Daftar Sekarang",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
