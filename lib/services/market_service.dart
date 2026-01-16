import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ... (BAGIAN 1 & 2: GET DATA & KERANJANG - TIDAK BERUBAH) ...
  Stream<QuerySnapshot> getAvailableProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserProducts() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('products')
        .where('uid', isEqualTo: user.uid)
        .orderBy('order')
        .snapshots();
  }

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
  // BAGIAN 3: TRANSAKSI & ORDER (DI UPDATE)
  // ==========================================

  // BUAT PESANAN BARU (CHECKOUT)
  Future<String> createOrder({
    required List<Map<String, dynamic>> items,
    required int totalPrice,
    required String sellerId,
    required String sellerName,
    required String deliveryAddress,
    int shippingCost = 0,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return "LOGIN_REQUIRED";

    try {
      String orderId = "ORD-${DateTime.now().millisecondsSinceEpoch}";

      // 1. Simpan Pesanan
      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'buyerId': user.uid,
        'buyerName': user.displayName ?? "Pembeli",
        'sellerId': sellerId,
        'sellerName': sellerName,
        'items': items,
        'totalPrice': totalPrice,
        'status': 'Menunggu',
        'shippingCost': shippingCost,
        'address': deliveryAddress,
        'deliveryLat': deliveryLat,
        'deliveryLng': deliveryLng,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. [NOTIFIKASI] Beritahu Penjual ada pesanan masuk
      await _sendNotification(
        recipientId: sellerId,
        title: "Pesanan Baru Masuk! 📦",
        body:
            "${user.displayName ?? 'Seseorang'} memesan barang dari toko Anda.",
        type: "order_incoming",
        relatedId: orderId,
      );

      // 3. Kurangi Stok Produk & Cek Stok Habis
      for (var item in items) {
        if (item['productId'] != null) {
          final productRef = _firestore
              .collection('products')
              .doc(item['productId']);

          // Update Stok
          await productRef.update({
            'stock': FieldValue.increment(-item['qty']),
            'sold': FieldValue.increment(item['qty']),
          });

          // Cek sisa stok untuk notifikasi
          final productSnap = await productRef.get();
          if (productSnap.exists) {
            int currentStock = productSnap.data()?['stock'] ?? 0;
            if (currentStock <= 0) {
              // [NOTIFIKASI] Stok Habis ke Penjual
              await _sendNotification(
                recipientId: sellerId,
                title: "Stok Habis! ⚠️",
                body: "Produk '${item['name']}' telah habis terjual.",
                type: "stock_empty",
                relatedId: item['productId'],
              );
            }
          }
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
      DocumentSnapshot orderSnap = await orderRef.get(); // Ambil data dulu

      if (!orderSnap.exists) throw Exception("Order not found");
      Map<String, dynamic> data = orderSnap.data() as Map<String, dynamic>;
      String buyerId = data['buyerId'];
      String productName =
          (data['items'] != null && (data['items'] as List).isNotEmpty)
          ? data['items'][0]['name']
          : "Pesanan Anda";

      // Jika status berubah jadi 'Selesai', cairkan dana ke penjual
      if (newStatus == 'Selesai') {
        await _firestore.runTransaction((transaction) async {
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
            'description': 'Penjualan $productName',
            'timestamp': FieldValue.serverTimestamp(),
          });
        });

        // [NOTIFIKASI] Ke Penjual (Dana Masuk)
        await _sendNotification(
          recipientId: data['sellerId'],
          title: "Dana Diterima! 💰",
          body: "Pesanan selesai. Dana penjualan masuk ke saldo Anda.",
          type: "wallet",
          relatedId: orderId,
        );
      } else {
        // Update status biasa (Diproses/Diantar)
        await orderRef.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // [NOTIFIKASI] Ke Pembeli (Update Status)
        String bodyMsg = "";
        if (newStatus == "Diproses") {
          bodyMsg = "Penjual sedang mengemas pesanan Anda.";
        } else if (newStatus == "Dikirim") {
          bodyMsg = "Pesanan Anda sedang dalam perjalanan.";
        } else if (newStatus == "Sampai") {
          bodyMsg = "Pesanan telah sampai! Mohon konfirmasi terima.";
        }

        if (bodyMsg.isNotEmpty) {
          await _sendNotification(
            recipientId: buyerId,
            title: "Status Pesanan: $newStatus 🚚",
            body: "$productName: $bodyMsg",
            type: "order_update",
            relatedId: orderId,
          );
        }
      }
    } catch (e) {
      print("Error update status: $e");
      rethrow;
    }
  }

  // ... (BAGIAN 4: GET ORDER - TIDAK BERUBAH) ...
  Stream<QuerySnapshot> getMyOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getIncomingOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> processPayment(String productId, int qty) async {
    return "SUCCESS";
  }

  // ==========================================
  // FUNGSI BANTUAN NOTIFIKASI (BARU)
  // ==========================================
  Future<void> _sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'type': type, // 'order_incoming', 'order_update', 'stock_empty'
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Gagal kirim notif: $e");
    }
  }
}
