class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final String shopName;
  final double price;
  final String size;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.shopName,
    required this.price,
    required this.size,
    this.quantity = 1,
  });

  String get key => '$productId-$size';

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name: name,
        imageUrl: imageUrl,
        shopName: shopName,
        price: price,
        size: size,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'shopName': shopName,
        'price': price,
        'size': size,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        shopName: json['shopName'] as String,
        price: (json['price'] as num).toDouble(),
        size: json['size'] as String,
        quantity: json['quantity'] as int? ?? 1,
      );
}
