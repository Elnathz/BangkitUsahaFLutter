import 'dart:async';
import 'dart:io';

class ConnectivityService {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller untuk broadcast status koneksi
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Status koneksi saat ini
  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  // Inisialisasi pengecekan
  void initialize() {
    // Cek awal saat aplikasi mulai
    _checkConnection().then((value) {
      _updateStatus(value);
    });

    // Cek berkala setiap 5 detik (Polling sederhana)
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      bool currentStatus = await _checkConnection();
      _updateStatus(currentStatus);
    });
  }

  void _updateStatus(bool status) {
    if (_hasConnection != status) {
      _hasConnection = status;
      _connectionStatusController.add(_hasConnection);
    }
  }

  // Fungsi pengecekan koneksi fisik ke internet
  Future<bool> _checkConnection() async {
    try {
      // 1. Coba lookup ke google.com (Timeout 3 detik)
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      // 2. FALLBACK: Jika Google gagal, coba ke Cloudflare (one.one.one.one)
      try {
        final result = await InternetAddress.lookup(
          'one.one.one.one',
        ).timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}
