import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/market_service.dart'; // Pastikan import ini benar

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Keranjang Saya")),
      body: StreamBuilder<QuerySnapshot>(
        stream: MarketService().getUserCart(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var items = snapshot.data!.docs;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  Text("Keranjang masih kosong"),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var data = items[index].data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.image,
                    ), // Nanti ganti Image.network(data['imageUrl'])
                  ),
                  title: Text(data['name']),
                  subtitle: Text("Rp ${data['price']} x ${data['qty']}"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text("Beli"),
                    onPressed: () async {
                      // Checkout item ini
                      String res = await MarketService().processPayment(
                        data['productId'],
                        data['qty'],
                        isFromCart: true, // Hapus dari keranjang setelah sukses
                      );

                      if (res == "SUCCESS") {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Berhasil dibeli!")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(res),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
