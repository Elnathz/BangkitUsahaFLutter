import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // BAGIAN 1: PRODUK (GET DATA)
  // ==========================================

  // 1. GLOBAL MARKET (Untuk Beranda - Tetap Terbaru)
  Stream<QuerySnapshot> getAvailableProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 2. TOKO SAYA (Untuk Tab Inventory - Mode Drag & Drop)
  // KITA KEMBALIKAN KE 'order' AGAR BISA DIGESER-GESER
  Stream<QuerySnapshot> getUserProducts() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('products')
        .where('uid', isEqualTo: user.uid)
        .orderBy('order') // <--- PENTING: Pakai 'order' agar Drag & Drop jalan
        .snapshots();
  }

  // ==========================================
  // BAGIAN 2: KERANJANG BELANJA
  // ==========================================

  // Tambah ke Keranjang
  Future<void> addToCart(
    String productId,
    String name,
    int price,
    String image,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Harus login");

    final cartRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(productId);

    final doc = await cartRef.get();
    if (doc.exists) {
      await cartRef.update({'qty': FieldValue.increment(1)});
    } else {
      await cartRef.set({
        'productId': productId,
        'name': name,
        'price': price,
        'image': image,
        'qty': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Ambil Data Keranjang
  Stream<QuerySnapshot> getUserCart() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Hapus Item Keranjang
  Future<void> removeFromCart(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  // Update Qty Keranjang
  Future<void> updateCartQty(String productId, int newQty) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (newQty < 1) {
      await removeFromCart(productId);
    } else {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(productId)
          .update({'qty': newQty});
    }
  }

  // ==========================================
  // BAGIAN 3: TRANSAKSI & ORDER
  // ==========================================

  // BUAT PESANAN BARU (CHECKOUT)
  Future<String> createOrder({
    required List<Map<String, dynamic>> items,
    required int totalPrice,
    required String sellerId,
    required String sellerName,
    required String deliveryAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return "LOGIN_REQUIRED";

    try {
      String orderId = "ORD-${DateTime.now().millisecondsSinceEpoch}";

      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'buyerId': user.uid,
        'buyerName': user.displayName ?? "Pembeli",
        'sellerId': sellerId,
        'sellerName': sellerName,
        'items': items,
        'totalPrice': totalPrice,
        'status': 'Menunggu',
        'address': deliveryAddress,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Kurangi Stok Produk
      for (var item in items) {
        if (item['productId'] != null) {
          await _firestore
              .collection('products')
              .doc(item['productId'])
              .update({
                'stock': FieldValue.increment(-item['qty']),
                'sold': FieldValue.increment(item['qty']),
              });
        }
      }

      return "SUCCESS";
    } catch (e) {
      return e.toString();
    }
  }

  // UPDATE STATUS PESANAN (Penjual/Pembeli)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      DocumentReference orderRef = _firestore.collection('orders').doc(orderId);

      // Jika status berubah jadi 'Selesai', cairkan dana ke penjual
      if (newStatus == 'Selesai') {
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot orderSnap = await transaction.get(orderRef);
          if (!orderSnap.exists) throw Exception("Order not found");

          Map<String, dynamic> data = orderSnap.data() as Map<String, dynamic>;
          String sellerId = data['sellerId'];
          int total = data['totalPrice'];

          // 1. Update Status Order
          transaction.update(orderRef, {
            'status': 'Selesai',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // 2. Tambah Saldo Dompet Penjual
          DocumentReference sellerRef = _firestore
              .collection('users')
              .doc(sellerId);
          transaction.update(sellerRef, {
            'walletBalance': FieldValue.increment(total),
          });

          // 3. Catat Riwayat Transaksi (Mutasi)
          DocumentReference transRef = _firestore
              .collection('wallet_transactions')
              .doc();
          transaction.set(transRef, {
            'userId': sellerId,
            'type': 'income', // Pemasukan
            'amount': total,
            'description': 'Penjualan ${data['items'][0]['name']}',
            'timestamp': FieldValue.serverTimestamp(),
          });
        });
      } else {
        // Update status biasa (Diproses/Diantar)
        await orderRef.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error update status: $e");
      rethrow;
    }
  }

  // ==========================================
  // BAGIAN 4: AMBIL DATA PESANAN (LIST ORDER)
  // ==========================================

  // 1. PESANAN SAYA (Sebagai PEMBELI - Riwayat Belanja)
  // Butuh Index: buyerId Ascending + createdAt Descending
  Stream<QuerySnapshot> getMyOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 2. PESANAN MASUK (Sebagai PENJUAL - Toko)
  // Butuh Index: sellerId Ascending + createdAt Descending
  Stream<QuerySnapshot> getIncomingOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Legacy Support
  Future<String> processPayment(String productId, int qty) async {
    return "SUCCESS";
  }
}
