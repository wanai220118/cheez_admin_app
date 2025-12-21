class Product {
  String id;
  String name;
  String variant; // normal, small, combo
  double price;
  double cost;
  String? imageUrl; // Product image URL
  String? description; // Product description
  bool isActive; // Product active status
  String? size; // Product size: 'small' or 'big'

  Product({
    required this.id,
    required this.name,
    required this.variant,
    required this.price,
    required this.cost,
    this.imageUrl,
    this.description,
    this.isActive = true, // Default to active
    this.size,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'variant': variant,
      'price': price,
      'cost': cost,
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
      'size': size,
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
      isActive: map['isActive'] ?? true, // Default to true for backward compatibility
      size: map['size'], // May be null for old documents
    );
  }
}
