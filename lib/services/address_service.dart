import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Mendapatkan Lokasi Saat Ini (GPS)
  Future<Map<String, dynamic>> getCurrentLocationAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek Service GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi tidak aktif. Harap nyalakan GPS.');
    }

    // Cek Izin Aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Cek pengaturan HP.');
    }

    // Ambil Koordinat
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Ubah Koordinat jadi Alamat (Geocoding)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Format alamat lengkap
        String fullAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.postalCode}";

        return {
          'address': fullAddress,
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      } else {
        throw Exception('Alamat tidak ditemukan.');
      }
    } catch (e) {
      throw Exception('Gagal mendapatkan detail alamat: $e');
    }
  }

  // 2. Simpan Alamat ke Firestore
  Future<void> saveAddress(
    String label,
    String fullAddress,
    double lat,
    double lng,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .add({
          'label': label, // Rumah, Kantor, Kost
          'fullAddress': fullAddress,
          'latitude': lat,
          'longitude': lng,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // 3. Ambil Daftar Alamat
  Stream<QuerySnapshot> getUserAddresses() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
