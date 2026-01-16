import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../services/market_service.dart';
import '../inventory/checkout_screen.dart'; // Import Halaman Checkout

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../services/market_service.dart';
import '../inventory/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Set of selected Product IDs
  final Set<String> _selectedItems = {};
  
  // Format Currency
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang Saya"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: MarketService().getUserCart(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return _buildEmptyCart();
          }

          // GROUP ITEMS BY SELLER ID
          // Map<String (sellerId), List<DocumentSnapshot>>
          Map<String, List<DocumentSnapshot>> groupedItems = {};
          
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            String sellerId = data['sellerId'] ?? "unknown";
            // Jika sellerId kosong, masuk ke 'Lainnya' atau 'Toko'
            if (sellerId.isEmpty) sellerId = "unknown";
            
            if (!groupedItems.containsKey(sellerId)) {
              groupedItems[sellerId] = [];
            }
            groupedItems[sellerId]!.add(doc);
          }

          // Calculate Total Price of Selected Items
          int grandTotal = 0;
          int selectedCount = 0;
          List<Map<String, dynamic>> checkoutItems = [];

          for (var doc in docs) {
            if (_selectedItems.contains(doc.id)) { // doc.id is usually productId based on MarketService
              var data = doc.data() as Map<String, dynamic>;
              int price = (data['price'] ?? 0).toInt();
              int qty = (data['qty'] ?? 1).toInt();
              grandTotal += (price * qty);
              selectedCount++;
              
              // Prepare item for checkout
              checkoutItems.add({
                'productId': data['productId'],
                'name': data['name'],
                'price': price,
                'qty': qty,
                'image': data['image'] ?? '',
                'sellerId': data['sellerId'] ?? '',
                'sellerName': data['sellerName'] ?? 'Toko',
              });
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedItems.keys.length,
                  itemBuilder: (context, index) {
                    String sellerId = groupedItems.keys.elementAt(index);
                    List<DocumentSnapshot> items = groupedItems[sellerId]!;
                    
                    // Ambil nama toko dari item pertama
                    String sellerName = "Toko";
                    if (items.isNotEmpty) {
                       var firstItem = items[0].data() as Map<String, dynamic>;
                       sellerName = firstItem['sellerName'] ?? "Toko";
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER TOKO
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.store, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                        // ITEMS IN THIS TOKO
                        ...items.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          String productId = doc.id; // Doc ID is productId
                          bool isSelected = _selectedItems.contains(productId);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // CHECKBOX
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: Colors.blue,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedItems.add(productId);
                                        } else {
                                          _selectedItems.remove(productId);
                                        }
                                      });
                                    },
                                  ),
                                  // IMAGE
                                  Container(
                                    width: 60, height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      image: (data['image'] != null && data['image'] != "")
                                          ? DecorationImage(
                                              image: NetworkImage(data['image']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: (data['image'] == null || data['image'] == "") 
                                        ? const Icon(LucideIcons.image, color: Colors.grey) 
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // INFO
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? "Produk",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(currencyFormat.format(data['price'] ?? 0), style: TextStyle(color: Colors.blue[700])),
                                      ],
                                    ),
                                  ),
                                  // QTY & DELETE
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                        onPressed: () {
                                          MarketService().removeFromCart(productId);
                                          _selectedItems.remove(productId); // Remove from selection if deleted
                                        },
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              int currentQty = (data['qty'] ?? 1).toInt();
                                              if (currentQty > 1) {
                                                MarketService().updateCartQty(productId, currentQty - 1);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(LucideIcons.minus, size: 14, color: Colors.grey),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              "${data['qty'] ?? 1}",
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              int currentQty = (data['qty'] ?? 1).toInt();
                                              MarketService().updateCartQty(productId, currentQty + 1);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(LucideIcons.plus, size: 14, color: Colors.blue),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
              // BOTTOM BAR (TOTAL)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Total Pembayaran", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            currencyFormat.format(grandTotal),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedCount == 0 ? null : () {
                        // NAVIGASI KE CHECKOUT SCREEN
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              items: checkoutItems,
                              totalPrice: grandTotal,
                              // KOSONGKAN SELLER ID/NAME (Karena support multi seller)
                              sellerId: "", 
                              sellerName: "",
                              isFromCart: true,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Beli ($selectedCount)", style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shoppingCart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Keranjang masih kosong", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
