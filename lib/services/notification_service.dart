import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // Ganti dart:io dengan ini agar aman di Web
import 'package:firebase_messaging/firebase_messaging.dart';

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
          'chat_channel_id',
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
}

// Handler Background (Harus di luar class, top-level function)
// Ini menangani notifikasi saat aplikasi BENAR-BENAR MATI (Terminated)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Saat app mati, sistem Android yang akan menangani tampilan notifikasi secara otomatis
  // jika payload berisi "notification". Kita tidak perlu coding UI di sini.
  print("Handling a background message: ${message.messageId}");
}
