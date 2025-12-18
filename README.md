# Bangkit Usaha - Flutter Mobile App

Aplikasi mobile untuk UMKM yang dibangun dengan Flutter, dikonversi dari React TypeScript.

## 🚀 Fitur Utama

- ✅ **Authentication** - Login dengan Email & Google Sign-In
- ✅ **Business Setup** - Onboarding untuk UMKM baru
- ✅ **Dashboard** - Overview pendapatan, transaksi, dan pesanan
- ✅ **Pencatatan Keuangan** - Catat pemasukan dan pengeluaran
- ✅ **Manajemen Stok** - Kelola produk toko sendiri
- ✅ **Manajemen Pesanan** - Track pembelian dan penjualan
- ✅ **Profil UMKM** - Informasi bisnis lengkap

## 📱 Struktur Project

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── transaction_model.dart
│   ├── product_model.dart
│   └── order_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── transaction_provider.dart
│   ├── product_provider.dart
│   └── order_provider.dart
├── screens/                  # UI Screens
│   ├── login_screen.dart
│   ├── business_setup_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── my_store_screen.dart
│   ├── orders_screen.dart
│   └── profile_screen.dart
└── widgets/                  # Reusable widgets
    ├── stats_card.dart
    └── order_card.dart
```

## 🔧 Setup Instructions

### 1. Prerequisites

- Flutter SDK (≥3.0.0)
- Dart SDK
- Android Studio / VS Code dengan Flutter extension
- Firebase account

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Android:

1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Register Android app dengan package name: `com.example.bangkit_usaha`
3. Download `google-services.json`
4. Letakkan di `android/app/google-services.json`
5. Enable Authentication (Email/Password & Google Sign-In)
6. Enable Cloud Firestore
7. Setup Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.sellerId == request.auth.uid;
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (resource.data.buyerId == request.auth.uid || 
         resource.data.sellerId == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.buyerId == request.auth.uid || 
         resource.data.sellerId == request.auth.uid);
    }
  }
}
```

#### iOS (Opsional):

1. Download `GoogleService-Info.plist`
2. Letakkan di `ios/Runner/GoogleService-Info.plist`

### 4. Update Package Name (Optional)

Jika ingin mengubah package name dari `com.example.bangkit_usaha`:

**Android:**
- Edit `android/app/build.gradle` → ubah `applicationId`
- Edit `android/app/src/main/AndroidManifest.xml` → ubah package

### 5. Run the App

```bash
# Development mode
flutter run

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ios --release
```

## 🎨 Customization

### Mengubah Warna Tema

Edit `main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF2563EB), // Ubah warna di sini
  brightness: Brightness.light,
),
```

### Mengubah Font

Edit `pubspec.yaml` dan tambahkan font custom:

```yaml
fonts:
  - family: CustomFont
    fonts:
      - asset: fonts/CustomFont-Regular.ttf
      - asset: fonts/CustomFont-Bold.ttf
        weight: 700
```

Lalu di `main.dart`:

```dart
textTheme: GoogleFonts.customFontTextTheme(),
```

## 📊 Data Structure

### Users Collection

```json
{
  "uid": "string",
  "email": "string",
  "storeName": "string",
  "ownerName": "string",
  "phoneNumber": "string",
  "isSetupComplete": true,
  "createdAt": "timestamp"
}
```

### Transactions Collection

```json
{
  "userId": "string",
  "type": "income|expense",
  "category": "string",
  "amount": 0,
  "description": "string",
  "date": "ISO8601",
  "createdAt": "timestamp"
}
```

### Products Collection

```json
{
  "name": "string",
  "price": 0,
  "stock": 0,
  "category": "string",
  "description": "string",
  "image": "url",
  "sellerId": "string",
  "sellerName": "string",
  "createdAt": "timestamp"
}
```

### Orders Collection

```json
{
  "productId": "string",
  "productName": "string",
  "price": 0,
  "quantity": 0,
  "total": 0,
  "buyerId": "string",
  "buyerName": "string",
  "sellerId": "string",
  "sellerName": "string",
  "status": "pending|processing|completed|cancelled",
  "paymentMethod": "string",
  "createdAt": "timestamp"
}
```

## 🐛 Troubleshooting

### Build Failed - Gradle Issues

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Firebase Auth Issues

- Pastikan `google-services.json` sudah ada
- Periksa SHA-1 fingerprint di Firebase Console
- Enable Authentication methods di Firebase Console

### Dependencies Issues

```bash
flutter pub cache repair
flutter clean
flutter pub get
```

## 📝 To-Do / Future Features

- [ ] Community/Forum feature
- [ ] Chat messaging between buyers and sellers
- [ ] Tips bisnis content
- [ ] Marketplace for browsing products
- [ ] Notifications
- [ ] Export to PDF
- [ ] Charts & Analytics
- [ ] Multi-language support
- [ ] Dark mode

## 📄 License

[Your License Here]

## 👥 Contributors

- Converted from React TypeScript to Flutter
- Original design: Bangkit Usaha Team

## 🙏 Credits

- Firebase for backend services
- Google Fonts for typography
- Flutter community for amazing packages

---

**Made with ❤️ for UMKM Indonesia** 🇮🇩