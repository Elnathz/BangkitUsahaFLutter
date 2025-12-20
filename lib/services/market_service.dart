import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. AMBIL PRODUK BERANDA (Hanya yang stok > 0)
  Stream<QuerySnapshot> getAvailableProducts() {
    return _firestore
        .collection('products')
        .where('stock', isGreaterThan: 0)
        .snapshots();
  }

  // 2. AMBIL KERANJANG USER (Fungsi ini yang tadi hilang/error)
  Stream<QuerySnapshot> getUserCart() {
    User? user = _auth.currentUser;
    // Jika user belum login, kembalikan stream kosong agar tidak error
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // 3. TAMBAH KE KERANJANG
  Future<void> addToCart(
    String productId,
    String name,
    int price,
    String image,
  ) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("Anda belum login");

    DocumentReference cartRef = _firestore
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
        'imageUrl': image,
        'qty': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 4. PROSES BELI / CHECKOUT
  Future<String> processPayment(
    String productId,
    int qty, {
    bool isFromCart = false,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return "User belum login";

    DocumentReference productRef = _firestore
        .collection('products')
        .doc(productId);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(productRef);

        if (!snapshot.exists) throw Exception("Barang tidak ditemukan");

        int currentStock = snapshot.get('stock');
        int price = snapshot.get('price');

        if (currentStock >= qty) {
          // A. Kurangi Stok
          transaction.update(productRef, {'stock': currentStock - qty});

          // B. Catat Order
          DocumentReference orderRef = _firestore.collection('orders').doc();
          transaction.set(orderRef, {
            'buyerId': user.uid,
            'productId': productId,
            'qty': qty,
            'totalPrice': price * qty,
            'status': 'paid',
            'timestamp': FieldValue.serverTimestamp(),
          });

          // C. Hapus dari keranjang jika perlu
          if (isFromCart) {
            transaction.delete(
              _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('cart')
                  .doc(productId),
            );
          }
        } else {
          throw Exception("Stok Habis! Sisa: $currentStock");
        }
      });
      return "SUCCESS";
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }
}
