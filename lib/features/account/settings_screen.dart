import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../../features/auth/login_screen.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _handleLogout() async {
    try {
      // Coba hapus token, tapi jangan halangi logout jika gagal (misal offline)
      try {
        await NotificationService.removeFCMToken();
      } catch (e) {
        debugPrint("Gagal hapus token: $e");
      }
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showToast("Gagal keluar: $e", ToastificationType.error);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isObscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Atur Kata Sandi"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Atur kata sandi agar Anda bisa login menggunakan Nomor HP/Email & Password.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: isObscure,
                  decoration: InputDecoration(
                    labelText: "Kata Sandi Baru",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure ? LucideIcons.eye : LucideIcons.eyeOff,
                      ),
                      onPressed: () => setState(() => isObscure = !isObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: isObscure,
                  decoration: const InputDecoration(
                    labelText: "Konfirmasi Kata Sandi",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (passwordController.text.isEmpty) {
                    _showToast(
                      "Kata sandi tidak boleh kosong",
                      ToastificationType.warning,
                    );
                    return;
                  }
                  if (passwordController.text != confirmController.text) {
                    _showToast(
                      "Kata sandi tidak cocok",
                      ToastificationType.error,
                    );
                    return;
                  }
                  if (passwordController.text.length < 6) {
                    _showToast(
                      "Minimal 6 karakter",
                      ToastificationType.warning,
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  try {
                    // KHUSUS LOGIN NO HP: Jika belum ada email, buat email dummy
                    // agar bisa menggunakan fitur Email/Password Auth Firebase
                    if (user?.email == null && user?.phoneNumber != null) {
                      String dummyEmail =
                          "${user!.phoneNumber!.replaceAll('+', '')}@bangkit.usaha";
                      await user?.updateEmail(dummyEmail);
                    }

                    await user?.updatePassword(passwordController.text);
                    _showToast(
                      "Kata sandi berhasil diatur! Anda bisa login dengan No HP + Password.",
                      ToastificationType.success,
                    );
                  } catch (e) {
                    if (e.toString().contains('requires-recent-login')) {
                      _showToast(
                        "Keamanan: Silakan Login ulang untuk mengatur sandi.",
                        ToastificationType.error,
                      );
                    } else {
                      _showToast("Gagal: $e", ToastificationType.error);
                    }
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
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
      appBar: AppBar(
        title: const Text("Pengaturan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Akun",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.lock, color: Colors.blue),
                  title: const Text("Atur Kata Sandi"),
                  subtitle: const Text("Untuk login manual (No HP/Email)"),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Lainnya",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(LucideIcons.logOut, color: Colors.red),
              title: const Text("Keluar", style: TextStyle(color: Colors.red)),
              onTap: _handleLogout,
            ),
          ),
        ],
      ),
    );
  }
}
