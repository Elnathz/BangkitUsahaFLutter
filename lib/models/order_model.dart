// FILE: models/order_model.dart
class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;
  final String image;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
    required this.image,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
      'image': image,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      total: (map['total'] ?? 0).toDouble(),
      image: map['image'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}