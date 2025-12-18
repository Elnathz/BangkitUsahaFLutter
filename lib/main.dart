import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';
import 'firebase_options.dart';
import 'theme_manager.dart'; // <--- Import file baru tadi

// Import halaman
import 'features/auth/login_screen.dart';
import 'features/home/main_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await ThemeManager.init(); // <--- Load tema tersimpan sebelum aplikasi jalan
    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Bungkus dengan ValueListenableBuilder agar aplikasi rebuild saat tema berubah
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, currentMode, _) {
        return ToastificationWrapper(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Bangkit Usaha',

            // --- PENGATURAN TEMA ---
            themeMode: currentMode, // Ikuti settingan manager
            theme: ThemeData(
              // Tema Terang
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[50],
            ),
            darkTheme: ThemeData(
              // Tema Gelap
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212), // Hitam elegan
            ),

            // -----------------------
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData) return const MainWrapper();
                return const LoginScreen();
              },
            ),
          ),
        );
      },
    );
  }
}

// (Class ErrorApp tetap sama seperti sebelumnya, biarkan saja di bawah sini)
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: Text(error))),
    );
  }
}
