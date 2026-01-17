import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // Ganti dart:io dengan ini agar aman di Web
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Cek jika sedang di Web, kita skip inisialisasi Android/iOS
    // karena Local Notification di Web cara kerjanya beda.
    if (kIsWeb) {
      return;
    }

    // 1. Setup Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Setup iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(initializationSettings);

    // --- TAMBAHAN: Buat Notification Channel untuk Android ---
    // Penting agar notifikasi muncul saat aplikasi ditutup (Background/Terminated)
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'chat_channel_id', // ID harus sama dengan di AndroidManifest.xml
          'Chat Notifications', // Nama yang muncul di pengaturan HP
          description: 'Notifikasi pesan masuk',
          importance: Importance.max,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'general_channel_id', // Channel untuk notifikasi umum
          'General Notifications',
          description: 'Notifikasi pesanan dan info lainnya',
          importance: Importance.max,
        ),
      );
    }

    // 3. Minta Izin (Hanya untuk Android, menggunakan pengecekan yang aman)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    // 4. Setup Firebase Messaging (FCM)
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Minta izin notifikasi (Penting untuk iOS & Android 13+)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handler untuk notifikasi saat aplikasi di Foreground (Sedang dibuka)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Jika ada notifikasi masuk saat aplikasi dibuka, kita tampilkan manual
      // menggunakan Local Notification agar muncul popup (heads-up)
      if (notification != null && android != null) {
        // --- FILTER NOTIFIKASI GANDA ---
        // Cek apakah notifikasi ini ditujukan untuk user yang sedang login
        final currentUser = FirebaseAuth.instance.currentUser;
        final recipientId = message.data['recipientId'];

        if (currentUser != null &&
            recipientId != null &&
            recipientId != currentUser.uid) {
          return; // Abaikan notifikasi jika bukan untuk user ini
        }

        showNotification(
          id: notification.hashCode,
          title: notification.title ?? 'Notifikasi Baru',
          body: notification.body ?? '',
        );
      }
    });

    // Handler saat notifikasi diklik dan aplikasi terbuka dari background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notifikasi diklik: ${message.data}');
      // Di sini Anda bisa menambahkan navigasi ke halaman chat/order
    });
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Jika di Web, kita hentikan fungsi agar tidak error
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'chat_channel_id', // Default channel, bisa disesuaikan
          'Chat Notifications',
          channelDescription: 'Notifikasi pesan masuk',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

  // Fungsi untuk mendapatkan Token FCM (Diperlukan untuk dikirim ke Database User)
  static Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  // --- MANAJEMEN TOKEN (Sync & Remove) ---

  /// Panggil fungsi ini saat Login atau saat membuka halaman utama/profil
  /// untuk memastikan token HP ini terdaftar di akun yang benar.
  static Future<void> syncFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? token = await getFCMToken();
    if (token != null) {
      // Simpan token ke array fcmTokens agar support multi-device
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmToken': token, // Fallback untuk backward compatibility
        'walletBalance': 0, // Inisialisasi saldo awal akun baru
      }, SetOptions(merge: true));
    }
  }

  /// Panggil fungsi ini saat Logout agar HP ini tidak menerima notifikasi lagi
  /// dari akun tersebut.
  static Future<void> removeFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? token = await getFCMToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
        // Jangan hapus 'fcmToken' single field karena mungkin dipakai device lain (legacy)
      });
    }
  }
}

// Handler Background (Harus di luar class, top-level function)
// Ini menangani notifikasi saat aplikasi BENAR-BENAR MATI (Terminated)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Saat app mati, sistem Android yang akan menangani tampilan notifikasi secara otomatis
  // jika payload berisi "notification". Kita tidak perlu coding UI di sini.
  print("Handling a background message: ${message.messageId}");
}
