class Product {
  String id;
  String name;
  String variant; // normal, small, combo
  double price;
  double cost;
  String? imageUrl; // Product image URL
  String? description; // Product description

  Product({
    required this.id,
    required this.name,
    required this.variant,
    required this.price,
    required this.cost,
    this.imageUrl,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'variant': variant,
      'price': price,
      'cost': cost,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'],
      variant: map['variant'],
      price: map['price'].toDouble(),
      cost: map['cost'].toDouble(),
      imageUrl: map['imageUrl'] ?? 'assets/images/placeholder.jpg',
      description: map['description'],
    );
  }
}
