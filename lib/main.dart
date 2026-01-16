import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Tambahkan import ini
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'theme_manager.dart';
import 'features/auth/login_screen.dart';
import 'features/home/main_wrapper.dart';
import 'services/notification_service.dart';
import 'services/market_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await NotificationService.initialize();

    // Initialize date formatting for Indonesian and English
    await Future.wait([
      initializeDateFormatting('id_ID', null),
      initializeDateFormatting('en_US', null),
    ]);

    // Initialize theme manager
    await ThemeManager.init();

    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

// Client-side fallback: Check for stale orders on login
// This runs once per app session as a fallback to Cloud Functions
void _checkStaleOrdersOnLogin() {
  // Run in background without blocking UI
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      final cancelledCount = await MarketService().checkAndCancelStaleOrders();
      if (cancelledCount > 0) {
        print("[Auto-Cancel] Cancelled $cancelledCount stale orders");
      }
    } catch (e) {
      print("[Auto-Cancel] Error: $e");
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Color Scheme - Blue Theme
  static const Color primaryBlue = Color(0xFF1565C0); // Main Blue
  static const Color lightBlue = Color(0xFF42A5F5); // Light Blue
  static const Color darkBlue = Color(0xFF0D47A1); // Dark Blue

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

            // Light Theme
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryBlue,
                primary: primaryBlue,
                secondary: lightBlue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              appBarTheme: const AppBarTheme(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Dark Theme
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryBlue,
                primary: primaryBlue,
                secondary: lightBlue,
                brightness: Brightness.dark,
                surface: const Color(0xFF112240),
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(
                0xFF0A1929,
              ), // Dark Blue Background
              appBarTheme: const AppBarTheme(
                backgroundColor: darkBlue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Authentication Stream
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // User logged in
                if (snapshot.hasData) {
                  // Run stale order check in background (client-side fallback)
                  _checkStaleOrdersOnLogin();
                  return const MainWrapper();
                }

                // User not logged in
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
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A1929),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Error Initializing App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
