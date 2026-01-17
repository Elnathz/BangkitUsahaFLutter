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
    String image, {
    String sellerId = "",
    String sellerName = "Toko",
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Harus login");
    final cartRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(productId);
    final doc = await cartRef.get();
    if (doc.exists) {
      await cartRef.update({
        'qty': FieldValue.increment(1),
        // Update seller info if missing/changed (optional)
        'sellerId': sellerId, 
        'sellerName': sellerName,
      });
    } else {
      await cartRef.set({
        'productId': productId,
        'name': name,
        'price': price,
        'image': image,
        'qty': 1,
        'sellerId': sellerId, // NEW
        'sellerName': sellerName, // NEW
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

      // GUNAKAN BATCH AGAR BISA OFFLINE & ATOMIK
      WriteBatch batch = _firestore.batch();
      DocumentReference orderRef = _firestore.collection('orders').doc(orderId);

      // 1. Simpan Pesanan ke Batch
      batch.set(orderRef, {
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

      // 2. Kurangi Stok Produk (Masukkan ke Batch)
      for (var item in items) {
        if (item['productId'] != null) {
          final productRef = _firestore
              .collection('products')
              .doc(item['productId']);

          // Update Stok dalam Batch
          batch.update(productRef, {
            'stock': FieldValue.increment(-item['qty']),
            'sold': FieldValue.increment(item['qty']),
          });

        }
      }

      // EKSEKUSI BATCH (Bisa Offline, akan disinkronkan saat online)
      await batch.commit();

      // 3. [NOTIFIKASI] (Fire and Forget - Tidak perlu await agar UI tidak macet jika offline)
      _sendNotification(
        recipientId: sellerId,
        title: "Pesanan Baru Masuk! 📦",
        body: "${user.displayName ?? 'Seseorang'} memesan barang dari toko Anda.",
        type: "order_incoming",
        relatedId: orderId,
      );

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
        // GANTI TRANSACTION DENGAN BATCH AGAR BISA OFFLINE
        // Transaction wajib online, Batch bisa offline (queued)
        WriteBatch batch = _firestore.batch();
        
        String sellerId = data['sellerId'];
        int total = data['totalPrice'];

        // 1. Update Status Order
        batch.update(orderRef, {
          'status': 'Selesai',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Tambah Saldo Dompet Penjual
        DocumentReference sellerRef = _firestore
            .collection('users')
            .doc(sellerId);
        batch.update(sellerRef, {
          'walletBalance': FieldValue.increment(total),
        });

        // 3. Catat Riwayat Transaksi (Mutasi)
        DocumentReference transRef = _firestore
            .collection('wallet_transactions')
            .doc();
        batch.set(transRef, {
          'userId': sellerId,
          'type': 'income', // Pemasukan
          'amount': total,
          'description': 'Penjualan $productName',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await batch.commit();

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
        .limit(20) // BATASI LOAD: Hanya 20 pesanan terakhir
        .snapshots();
  }

  Stream<QuerySnapshot> getIncomingOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(20) // BATASI LOAD: Hanya 20 pesanan masuk terakhir
        .snapshots();
  }

  // ==========================================
  // BUYER CANCELLATION (2-minute rule)
  // ==========================================
  
  /// Cancel order by buyer
  /// - Within 2 minutes: instant cancel (needsApproval = false)
  /// - After 2 minutes: needs seller approval (needsApproval = true)
  Future<void> cancelOrderByBuyer(String orderId, String reason, {required bool needsApproval}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Login required");
    
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();
      
      if (!orderSnap.exists) throw Exception("Order not found");
      
      final data = orderSnap.data()!;
      final sellerId = data['sellerId'];
      final items = data['items'] as List<dynamic>? ?? [];
      final productName = items.isNotEmpty ? items[0]['name'] ?? 'Pesanan' : 'Pesanan';
      
      if (needsApproval) {
        // Request cancellation - needs seller approval
        await orderRef.update({
          'cancelRequested': true,
          'cancelRequestReason': reason,
          'cancelRequestedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Notify seller about cancellation request
        await _sendNotification(
          recipientId: sellerId,
          title: "Permintaan Pembatalan 📝",
          body: "Pembeli mengajukan pembatalan pesanan '$productName'. Alasan: $reason",
          type: "cancel_request",
          relatedId: orderId,
        );
      } else {
        // Instant cancel - within 2 minutes
        await orderRef.update({
          'status': 'Dibatalkan',
          'cancelReason': reason,
          'cancelledBy': 'buyer',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Restore product stock
        for (var item in items) {
          if (item['productId'] != null) {
            await _firestore
                .collection('products')
                .doc(item['productId'])
                .update({
              'stock': FieldValue.increment(item['qty'] ?? 1),
              'sold': FieldValue.increment(-(item['qty'] ?? 1)),
            });
          }
        }
        
        // Notify seller about cancellation
        await _sendNotification(
          recipientId: sellerId,
          title: "Pesanan Dibatalkan ❌",
          body: "Pembeli membatalkan pesanan '$productName'. Alasan: $reason",
          type: "order_cancelled",
          relatedId: orderId,
        );
      }
    } catch (e) {
      print("Error cancelling order: $e");
      rethrow;
    }
  }

  /// Seller approves or rejects cancellation request
  Future<void> handleCancelRequest(String orderId, bool approve) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Login required");
    
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();
      
      if (!orderSnap.exists) throw Exception("Order not found");
      
      final data = orderSnap.data()!;
      final buyerId = data['buyerId'];
      final items = data['items'] as List<dynamic>? ?? [];
      final productName = items.isNotEmpty ? items[0]['name'] ?? 'Pesanan' : 'Pesanan';
      
      if (approve) {
        // Approve cancellation
        await orderRef.update({
          'status': 'Dibatalkan',
          'cancelReason': data['cancelRequestReason'] ?? 'Disetujui penjual',
          'cancelledBy': 'buyer_approved',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelRequested': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Restore stock
        for (var item in items) {
          if (item['productId'] != null) {
            await _firestore
                .collection('products')
                .doc(item['productId'])
                .update({
              'stock': FieldValue.increment(item['qty'] ?? 1),
              'sold': FieldValue.increment(-(item['qty'] ?? 1)),
            });
          }
        }
        
        await _sendNotification(
          recipientId: buyerId,
          title: "Pembatalan Disetujui ✅",
          body: "Penjual menyetujui pembatalan pesanan '$productName'.",
          type: "cancel_approved",
          relatedId: orderId,
        );
      } else {
        // Reject cancellation
        await orderRef.update({
          'cancelRequested': false,
          'cancelRejectedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        await _sendNotification(
          recipientId: buyerId,
          title: "Pembatalan Ditolak ❌",
          body: "Penjual menolak pembatalan pesanan '$productName'. Pesanan akan tetap diproses.",
          type: "cancel_rejected",
          relatedId: orderId,
        );
      }
    } catch (e) {
      print("Error handling cancel request: $e");
      rethrow;
    }
  }

  // ==========================================
  // AUTO-CANCEL STALE ORDERS
  // - Menunggu: 3 days without response
  // - Diproses: 7 days without shipping
  // ==========================================
  
  /// Check and cancel orders that have been waiting too long
  /// This runs on app initialization and periodically
  Future<int> checkAndCancelStaleOrders() async {
    int cancelledCount = 0;
    
    try {
      // 1. Check "Menunggu" orders older than 3 days
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final menungguOrders = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'Menunggu')
          .where('createdAt', isLessThan: Timestamp.fromDate(threeDaysAgo))
          .get();
      
      for (var doc in menungguOrders.docs) {
        await _cancelStaleOrder(
          doc.id, 
          doc.data(), 
          'Penjual tidak merespon dalam 3 hari',
        );
        cancelledCount++;
      }
      
      // 2. Check "Diproses" orders older than 7 days (from updatedAt)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final diprosesOrders = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'Diproses')
          .where('updatedAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();
      
      for (var doc in diprosesOrders.docs) {
        await _cancelStaleOrder(
          doc.id, 
          doc.data(), 
          'Pesanan tidak dikirim dalam 7 hari',
        );
        cancelledCount++;
      }
      
      print("Auto-cancelled $cancelledCount stale orders");
      return cancelledCount;
    } catch (e) {
      print("Error checking stale orders: $e");
      return cancelledCount;
    }
  }
  
  /// Cancel a single stale order - restore stock and notify both parties
  Future<void> _cancelStaleOrder(String orderId, Map<String, dynamic> orderData, String cancelReason) async {
    try {
      final buyerId = orderData['buyerId'];
      final sellerId = orderData['sellerId'];
      final items = orderData['items'] as List<dynamic>? ?? [];
      final productName = items.isNotEmpty ? items[0]['name'] ?? 'Pesanan' : 'Pesanan';
      
      // 1. Update order status to cancelled
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Dibatalkan',
        'cancelReason': 'Otomatis dibatalkan - $cancelReason',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 2. Restore product stock
      for (var item in items) {
        if (item['productId'] != null) {
          try {
            final productRef = _firestore.collection('products').doc(item['productId']);
            final productSnap = await productRef.get();
            if (productSnap.exists) {
               await productRef.update({
                'stock': FieldValue.increment(item['qty'] ?? 1),
                'sold': FieldValue.increment(-(item['qty'] ?? 1)),
              });
            }
          } catch (e) {
            print("Skipping stock restore for missing product: ${item['productId']}");
          }
        }
      }
      
      // 3. Notify buyer about cancellation
      await _sendNotification(
        recipientId: buyerId,
        title: "Pesanan Dibatalkan ⚠️",
        body: "Pesanan '$productName' dibatalkan karena $cancelReason.",
        type: "order_cancelled",
        relatedId: orderId,
      );
      
      // 4. Notify seller about cancellation
      await _sendNotification(
        recipientId: sellerId,
        title: "Pesanan Terlewat ⚠️",
        body: "Pesanan '$productName' dibatalkan otomatis - $cancelReason.",
        type: "order_cancelled",
        relatedId: orderId,
      );
      
      print("Cancelled stale order: $orderId");
    } catch (e) {
      print("Error cancelling order $orderId: $e");
    }
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

  // ==========================================
  // FEEDBACK & RE-ORDER
  // ==========================================

  // Submit Review & Update Product Rating
  Future<String> submitReview({
    required String productId,
    required String shopId,
    required double rating,
    required String comment,
    required List<String> images,
    required String orderId, // NEW: Need orderId to mark as reviewed
  }) async {
    final user = _auth.currentUser;
    if (user == null) return "LOGIN_REQUIRED";

    try {
      // GANTI TRANSACTION DENGAN BATCH AGAR BISA OFFLINE
      final productRef = _firestore.collection('products').doc(productId);
      final orderRef = _firestore.collection('orders').doc(orderId);

      // Baca data (bisa dari cache jika offline)
      final productSnap = await productRef.get();
      final orderSnap = await orderRef.get();

      if (productSnap.exists && orderSnap.exists) {
        WriteBatch batch = _firestore.batch();

        // Update Product Rating
        final data = productSnap.data() as Map<String, dynamic>;
        double currentRating = (data['rating'] ?? 0).toDouble();
        int totalReviews = (data['totalReviews'] ?? 0).toInt();
        double newRating = ((currentRating * totalReviews) + rating) / (totalReviews + 1);

        batch.update(productRef, {
          'rating': newRating,
          'totalReviews': FieldValue.increment(1),
        });

        // Add Review
        final reviewRef = _firestore.collection('reviews').doc();
        batch.set(reviewRef, {
          'productId': productId,
          'shopId': shopId,
          'userId': user.uid,
          'userName': user.displayName ?? "Pengguna",
          'userImage': user.photoURL ?? "",
          'rating': rating,
          'comment': comment,
          'images': images,
          'createdAt': FieldValue.serverTimestamp(),
          'likes': 0,
        });

        // Mark item as reviewed in Order
        // Note: Array update is tricky, we need to read modify write.
        List<dynamic> items = orderSnap.data()?['items'] ?? [];
        List<dynamic> newItems = items.map((item) {
          if (item['productId'] == productId) {
            Map<String, dynamic> newItem = Map.from(item);
            newItem['reviewed'] = true; // Mark as reviewed
            return newItem;
          }
          return item;
        }).toList();

        batch.update(orderRef, {'items': newItems});
        
        await batch.commit();
      }
      return "SUCCESS";
    } catch (e) {
      return e.toString();
    }
  }

  // Re-order Items (Add all to cart)
  Future<String> reorderItems(List<dynamic> items) async {
    final user = _auth.currentUser;
    if (user == null) return "LOGIN_REQUIRED";

    try {
      // Use Future.wait to add all items in parallel
      await Future.wait(items.map((item) async {
        if (item['productId'] != null) {
          await addToCart(
            item['productId'],
            item['name'] ?? "Produk",
            item['price'] is int ? item['price'] : (item['price'] as num).toInt(),
            item['image'] ?? "",
            sellerId: item['sellerId'] ?? "",
            sellerName: item['sellerName'] ?? "Toko",
          );
          // Optional: Update qty if you want exact re-order amount in cart
          // But addToCart adds +1 by default. 
          // If we want exact qty, we might need a specific parameter or separate call.
          // For now, let's just add them to cart (increment existing or set new).
        }
      }));
      return "SUCCESS";
    } catch (e) {
      return e.toString();
    }
  }
}
