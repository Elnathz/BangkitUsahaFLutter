<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/firebase-%23FFCA28.svg?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Google_Maps-4285F4?style=for-the-badge&logo=google-maps&logoColor=white" alt="Google Maps"/>
</p>

<h1 align="center">🚀 Bangkit Usaha</h1>

<p align="center">
  <strong>Aplikasi Manajemen Usaha Modern untuk UMKM Indonesia</strong>
</p>

<p align="center">
  Bangkit Usaha adalah aplikasi manajemen usaha berbasis mobile yang dibangun menggunakan framework <strong>Flutter</strong>. Aplikasi ini dirancang untuk membantu pelaku UMKM dalam mengelola inventaris, keuangan, transaksi, dan operasional bisnis mereka secara efisien dan modern.
</p>

---

## 👥 Tim Pengembang (Kelompok 2)

| Nama                            | NIM            |
| :------------------------------ | :------------- |
| **Adam Haritsa Thahara**  | A11.2024.15556 |
| **Angela Echa Naresti**   | A11.2024.15791 |
| **Farros Rifantiarno R.** | A11.2024.15694 |
| **Puguh Wibowo**          | A11.2024.15942 |

---

## 📱 Deskripsi Aplikasi

**Bangkit Usaha** adalah solusi digital lengkap untuk pengelolaan bisnis UMKM. Aplikasi ini menyediakan berbagai fitur yang saling terintegrasi untuk memudahkan pemilik usaha dalam:

- 📊 **Monitoring Bisnis** - Dashboard interaktif dengan grafik penjualan dan statistik real-time
- 📦 **Kelola Inventaris** - Manajemen produk dengan fitur tambah, edit, hapus, dan notifikasi stok rendah
- 💰 **Pencatatan Keuangan** - Tracking pemasukan dan pengeluaran dengan laporan mingguan/bulanan
- 🛒 **Manajemen Pesanan** - Pengelolaan pesanan masuk dan checkout yang efisien
- 🏪 **Profil Toko** - Halaman profil toko dengan informasi bisnis lengkap
- 👥 **Komunitas** - Fitur sosial untuk berbagi tips dan pengalaman antar pelaku usaha
- 💬 **Chat** - Komunikasi langsung antar pengguna dalam aplikasi
- 🔔 **Notifikasi** - Pemberitahuan real-time untuk transaksi dan update penting
- 📍 **Lokasi Usaha** - Integrasi Google Maps untuk menampilkan dan memilih lokasi toko

---

## 🛠️ Tech Stack

### **Core Framework**

| Teknologi | Versi   | Deskripsi                   |
| :-------- | :------ | :-------------------------- |
| Flutter   | ^3.10.3 | Framework UI cross-platform |
| Dart      | Latest  | Bahasa pemrograman utama    |

### **Backend & Cloud Services (Firebase)**

| Package                | Versi    | Fungsi                   |
| :--------------------- | :------- | :----------------------- |
| `firebase_core`      | ^3.0.0   | Inisialisasi Firebase    |
| `firebase_auth`      | ^5.7.0   | Autentikasi pengguna     |
| `cloud_firestore`    | ^5.6.12  | Database NoSQL real-time |
| `firebase_storage`   | ^12.4.10 | Penyimpanan file/gambar  |
| `firebase_messaging` | ^15.2.10 | Push notification        |
| `google_sign_in`     | ^6.2.1   | Login dengan Google      |

### **State Management**

| Package      | Versi   | Fungsi               |
| :----------- | :------ | :------------------- |
| `provider` | ^6.1.2  | State management     |
| `rxdart`   | ^0.28.0 | Reactive programming |

### **UI & Styling**

| Package                  | Versi    | Fungsi              |
| :----------------------- | :------- | :------------------ |
| `google_fonts`         | ^6.2.1   | Tipografi modern    |
| `lucide_icons`         | ^0.257.0 | Icon set modern     |
| `cupertino_icons`      | ^1.0.8   | iOS-style icons     |
| `toastification`       | ^3.0.3   | Toast notifications |
| `cached_network_image` | ^3.4.1   | Image caching       |

### **Maps & Location**

| Package                 | Versi   | Fungsi                       |
| :---------------------- | :------ | :--------------------------- |
| `google_maps_flutter` | ^2.5.0  | Tampilan peta interaktif     |
| `geolocator`          | ^10.1.0 | Akses GPS device             |
| `geocoding`           | ^2.1.1  | Konversi koordinat ke alamat |

### **Utilities**

| Package                | Versi   | Fungsi                     |
| :--------------------- | :------ | :------------------------- |
| `intl`               | ^0.19.0 | Format tanggal & mata uang |
| `image_picker`       | ^1.2.1  | Upload foto produk/profil  |
| `url_launcher`       | ^6.2.5  | Buka link eksternal        |
| `shared_preferences` | ^2.5.4  | Penyimpanan lokal          |
| `http`               | ^1.2.0  | HTTP requests              |

### **Media**

| Package          | Versi  | Fungsi          |
| :--------------- | :----- | :-------------- |
| `video_player` | ^2.8.1 | Pemutar video   |
| `chewie`       | ^1.7.1 | Video player UI |

---

## ⚙️ Instalasi & Setup

### **Prasyarat**

Pastikan Anda telah menginstall:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.10.3 atau lebih baru)
- [Android Studio](https://developer.android.com/studio) atau [VS Code](https://code.visualstudio.com/)
- Emulator Android/iOS atau device fisik
- Akun [Firebase](https://firebase.google.com/) (untuk konfigurasi backend)
- [Google Cloud Platform](https://console.cloud.google.com/) API Key untuk Maps

### **Langkah Instalasi**

1. **Clone Repository**

   ```bash
   git clone https://github.com/Elnathz/BangkitUsahaFLutter.git
   cd BangkitUsahaFLutter
   ```
2. **Install Dependencies**

   ```bash
   flutter pub get
   ```
3. **Konfigurasi Firebase**

   Pastikan file `lib/firebase_options.dart` sudah terkonfigurasi dengan project Firebase Anda.

   Jika belum ada, setup menggunakan [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/):

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. **Konfigurasi Google Maps API Key**

   <details>
   <summary><strong>🌐 Untuk Web (Chrome)</strong></summary>

   Edit file `web/index.html`, tambahkan script berikut di dalam tag `<head>`:

   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY"></script>
   ```

   </details>

   <details>
   <summary><strong>📱 Untuk Android</strong></summary>

   Edit file `android/app/src/main/AndroidManifest.xml`:

   **a. Tambahkan permissions (sebelum tag `<application>`):**

   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.INTERNET" />

   <!-- Untuk share ke WhatsApp & Instagram -->
   <queries>
       <intent>
           <action android:name="android.intent.action.VIEW" />
           <data android:scheme="https" />
       </intent>
       <intent>
           <action android:name="android.intent.action.VIEW" />
           <data android:scheme="instagram" />
       </intent>
   </queries>
   ```

   **b. Tambahkan API Key Maps (di dalam tag `<application>`):**

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY" />
   ```

   </details>

   <details>
   <summary><strong>🍎 Untuk iOS</strong></summary>

   Edit file `ios/Runner/AppDelegate.swift`:

   ```swift
   import GoogleMaps

   // Di dalam application function, tambahkan:
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

   Edit `ios/Runner/Info.plist`, tambahkan:

   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Aplikasi membutuhkan akses lokasi untuk menampilkan peta.</string>
   ```

   </details>

---

## 🚀 Cara Menjalankan Aplikasi

### **Mode Development**

```bash
# Jalankan di device/emulator default
flutter run

# Jalankan di Chrome (Web)
flutter run -d chrome

# Jalankan di Chrome dengan disable web security (untuk development)
flutter run -d chrome --web-browser-flag "--disable-web-security"

# Jalankan di Android Emulator
flutter run -d android

# Jalankan di iOS Simulator
flutter run -d ios
```

### **Build Production**

```bash
# Build APK untuk Android
flutter build apk --release

# Build App Bundle untuk Play Store
flutter build appbundle --release

# Build untuk Web
flutter build web --release

# Build untuk iOS
flutter build ios --release
```

---

## 📂 Struktur Folder

```
lib/
├── features/                     # Modul fitur aplikasi
│   ├── account/                  # Manajemen akun & profil pengguna
│   ├── auth/                     # Autentikasi
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── cart/                     # Keranjang belanja
│   ├── chat/                     # Fitur chat antar pengguna
│   ├── community/                # Fitur komunitas & sosial media
│   ├── finance/                  # Manajemen keuangan
│   │   ├── models/
│   │   └── screens/
│   ├── home/                     # Dashboard & halaman utama
│   │   ├── dashboard_screen.dart
│   │   └── main_wrapper.dart
│   ├── inventory/                # Manajemen stok produk
│   │   ├── checkout_screen.dart
│   │   └── products_screen.dart
│   ├── notifications/            # Layanan notifikasi
│   └── shop/                     # Profil & tampilan toko
│
├── services/                     # Business logic & API services
│   ├── address_service.dart      # Layanan alamat & lokasi
│   ├── badge_service.dart        # Sistem badge pengguna
│   ├── chat_service.dart         # Backend chat
│   ├── finance_service.dart      # Logic keuangan
│   ├── market_service.dart       # Logic pasar & transaksi
│   └── notification_service.dart # Handler notifikasi
│
├── firebase_options.dart         # Konfigurasi Firebase
├── theme_manager.dart            # Pengaturan tema aplikasi
├── map_picker_screen.dart        # Screen pemilihan lokasi
└── main.dart                     # Entry point aplikasi
```

---

## 🔗 API Services

Aplikasi ini menggunakan beberapa layanan API internal yang terhubung dengan Firebase:

| Service                       | File                                       | Deskripsi                                  |
| :---------------------------- | :----------------------------------------- | :----------------------------------------- |
| **MarketService**       | `lib/services/market_service.dart`       | CRUD produk, manajemen toko, dan transaksi |
| **FinanceService**      | `lib/services/finance_service.dart`      | Pencatatan pemasukan & pengeluaran         |
| **ChatService**         | `lib/services/chat_service.dart`         | Pengiriman & penerimaan pesan              |
| **AddressService**      | `lib/services/address_service.dart`      | Geocoding & reverse geocoding              |
| **NotificationService** | `lib/services/notification_service.dart` | Push notification & local notification     |
| **BadgeService**        | `lib/services/badge_service.dart`        | Sistem achievement & badge                 |

### **External APIs**

- **Firebase Authentication** - Login & registrasi pengguna
- **Cloud Firestore** - Database real-time
- **Firebase Storage** - Upload gambar produk & profil
- **Google Maps API** - Tampilan peta & geocoding
- **Firebase Cloud Messaging** - Push notifications

<p align="center">
  <sub>Dibuat dengan ❤️ oleh Kelompok 2 menggunakan Flutter</sub>
</p>
