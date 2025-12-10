class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'] ?? 'Food',
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }
}