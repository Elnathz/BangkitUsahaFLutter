import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart'; // PENTING: Jangan lupa ini
import 'firebase_options.dart';

// Import halaman-halaman
import 'features/auth/login_screen.dart';
import 'features/home/main_wrapper.dart';

void main() async {
  // 1. Pastikan binding aktif
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Coba inisialisasi Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Jika berhasil, jalankan App
    runApp(const MyApp());
  } catch (e) {
    // 3. JIKA ERROR: Jalankan App Darurat untuk menampilkan pesan error
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. BUNGKUS DENGAN TOASTIFICATION WRAPPER
    // Tanpa ini, perintah toastification.show() di profil akan bikin aplikasi crash/white screen
    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bangkit Usaha',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        // Logika Pengecekan Login
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // A. Sedang Memuat
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Menghubungkan..."),
                    ],
                  ),
                ),
              );
            }

            // B. Ada Error pada Stream
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text("Error Auth: ${snapshot.error}")),
              );
            }

            // C. Sudah Login -> Masuk Wrapper (Dashboard, Profil, dll)
            if (snapshot.hasData) {
              return const MainWrapper();
            }

            // D. Belum Login -> Ke Halaman Login
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

// Widget Darurat jika Firebase Gagal
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "Gagal Menjalankan Aplikasi",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                const Text(
                  "Coba cek koneksi internet atau konfigurasi firebase_options.dart",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
