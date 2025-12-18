import 'package:flutter/material.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stok Produk")),
      body: const Center(child: Text("Fitur Stok Segera Hadir")),
    );
  }
}
