import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ TAMBAHKAN BARIS INI
import 'features/finance/transactions_screen.dart';
import 'theme_manager.dart';

import 'features/auth/login_screen.dart';
import 'features/home/main_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Future.wait([
    initializeDateFormatting('id_ID', null),
    initializeDateFormatting('en_US', null),
  ]);
    await ThemeManager.init();
    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // DEFINISI WARNA ANDA
  static const Color primaryBrown = Color(0xFF8D6E63); // Warna Utama
  static const Color lightBrown = Color(0xFFA1887F); // Warna Terang
  static const Color darkBrown = Color(0xFF6D4C41); // Warna Gelap

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, currentMode, _) {
        return ToastificationWrapper(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Bangkit Usaha',

            themeMode: currentMode,

            // --- TEMA TERANG (LIGHT MODE) ---
            theme: ThemeData(
              brightness: Brightness.light,
              // Menggunakan warna cokelat sebagai bibit warna (seed)
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryBrown,
                primary: primaryBrown,
                secondary: lightBrown,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(
                0xFFF5F5F5,
              ), // Putih gading (agar hangat)
              appBarTheme: const AppBarTheme(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // --- TEMA GELAP (DARK MODE) ---
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryBrown,
                primary: primaryBrown,
                secondary: lightBrown,
                brightness: Brightness.dark,
                surface: const Color(0xFF1E1E1E),
              ),
              useMaterial3: true,
              // Background gelap menggunakan varian Cokelat Sangat Tua agar senada
              scaffoldBackgroundColor: const Color(0xFF3E2723),
              appBarTheme: const AppBarTheme(
                backgroundColor:
                    darkBrown, // Header pakai cokelat tua pilihan Anda
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

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
