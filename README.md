# Bangkit Usaha Flutter 🚀

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)

Bangkit Usaha adalah aplikasi manajemen usaha berbasis mobile yang dibangun menggunakan Framework **Flutter**. Aplikasi ini dirancang untuk membantu UMKM dalam mengelola inventaris, keuangan, dan operasional bisnis mereka secara efisien.

---

## 👥 Kelompok 2 (Tim Pengembang)

Project ini dikembangkan oleh tim mahasiswa sebagai bagian dari tugas **Pemrograman Perangkat Bergerak / Mobile Programming**.

| Nama                      | NIM            |
| :------------------------ | :------------- |
| **Adam Haritsa Thahara**  | A11.2024.15556 |
| **Angela Echa Naresti**   | A11.2024.15791 |
| **Farros Rifantiarno R.** | A11.2024.15694 |
| **Puguh WIbowo**          | A11.2024.15942 |

---

## ✨ Fitur Utama

Aplikasi Bangkit Usaha dilengkapi dengan berbagai fitur untuk mendukung produktivitas usaha:

- **📊 Dashboard Informatif**: Ringkasan performa usaha, grafik penjualan, dan notifikasi penting.
- **📦 Manajemen Inventaris**: Tambah, edit, dan hapus produk dengan mudah. Monitor stok secara real-time.
- **💰 Pencatatan Keuangan**: Catat transaksi pemasukan dan pengeluaran.
- **🔐 Autentikasi Pengguna**: Login aman menggunakan Firebase Auth dan Google Sign-In.
- **📍 Lokasi & Peta**: Integrasi Geolocation untuk fitur berbasis lokasi.
- **🔔 Notifikasi**: Pemberitahuan real-time untuk update penting.
- **💬 Chat**: Fitur komunikasi built-in.

---

## 🛠️ Tech Stack & Dependencies

Project ini menggunakan teknologi dan library berikut:

- **Core**: [Flutter](https://flutter.dev/) (SDK ^3.10.3) & Dart.
- **Backend & Cloud**:
  - [Firebase Core, Auth, Firestore, Storage](https://firebase.google.com/) (Backend as a Service).
- **State Management**: `provider` (^6.1.2).
- **UI & Styling**:
  - `google_fonts`: Tipografi modern.
  - `lucide_icons` & `cupertino_icons`: Ikon set lengkap.
  - `toastification`: Notifikasi toast yang cantik.
- **Utilities**:
  - `intl`: Format tanggal dan mata uang.
  - `image_picker`: Upload foto produk/profil.
  - `geolocator` & `geocoding`: Layanan lokasi.
  - `shared_preferences`: Penyimpanan data lokal sederhana.
  - `flutter_local_notifications`: Sistem notifikasi.

---

## 📲 Cara Instalasi & Menjalankan Aplikasi

Ikuti langkah-langkah berikut untuk menjalankan project ini di komputer lokal Anda:

### Prasyarat

- Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
- Siapkan emulator Android/iOS atau hubungkan device fisik.

### Langkah-langkah

1.  **Clone Repository**

    ```bash
    git clone https://github.com/username/BangkitUsahaFLutter.git
    cd BangkitUsahaFLutter
    ```

2.  **Install Dependencies**

    ```bash
    flutter pub get
    ```

3.  **Konfigurasi Firebase**

    - Pastikan file `firebase_options.dart` sudah terkonfigurasi dengan project Firebase Anda.
    - Jika belum, setup menggunakan [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).

4.  **Jalankan Aplikasi**
    ```bash
    flutter run
    ```

### 🌐 Konfigurasi Khusus Web

Jika menjalankan di Chrome/Web, Anda **wajib** menambahkan script Google Maps ke dalam file `web/index.html` di bagian `<head>`:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=MASUKKAN_API_KEY_GOOGLE_MAPS_ANDA"></script>
```

Tanpa ini, peta akan error (`cannot read properties of undefined`).

### 📱 Konfigurasi Khusus Android

Agar fitur **Peta**, **Lokasi**, dan **Share** berjalan di HP Android, edit file `android/app/src/main/AndroidManifest.xml`:

1. **Tambahkan Permission & Queries** (sebelum tag `<application>`):
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

   <!-- Agar bisa buka WhatsApp & Instagram -->
   <queries>
       <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>
       <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="instagram" /></intent>
   </queries>
   ```

2. **Tambahkan API Key Maps** (di dalam tag `<application>`):
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="MASUKKAN_API_KEY_GOOGLE_MAPS_ANDA" />
   ```

---

## 📂 Struktur Folder

```
lib/
├── features/                 # Modul-modul fitur aplikasi
│   ├── account/              # Fitur manajemen akun pengguna
│   ├── auth/                 # Autentikasi (Login, Register)
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── cart/                 # Keranjang belanja
│   ├── chat/                 # Fitur chat antar pengguna
│   ├── community/            # Fitur komunitas/sosial
│   ├── finance/              # Manajemen keuangan
│   │   ├── models/
│   │   ├── screens/
│   │   └── transactions_screen.dart
│   ├── home/                 # Halaman utama dan dashboard
│   │   ├── dashboard_screen.dart
│   │   └── main_wrapper.dart
│   ├── inventory/            # Manajemen stok produk
│   │   ├── checkout_screen.dart
│   │   └── products_screen.dart
│   ├── notifications/        # Layanan notifikasi
│   └── shop/                 # Tampilan toko
├── services/                 # Logic bisnis & API calls
│   ├── address_service.dart      # Layanan lokasi/alamat
│   ├── chat_service.dart         # Backend chat
│   ├── market_service.dart       # Logic pasar/transaksi
│   └── notification_service.dart # Handler notifikasi lokal
├── firebase_options.dart     # Config Firebase otomatis
├── theme_manager.dart        # Pengaturan tema aplikasi
└── main.dart                 # Entry point aplikasi
```

---

## 📄 Lisensi

Project ini dilisensikan di bawah [MIT License](LICENSE).

---

<center>
  <sub>Dibuat dengan ❤️ menggunakan Flutter</sub>
</center>
