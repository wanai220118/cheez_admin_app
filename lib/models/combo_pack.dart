class ComboPack {
  String id;
  String name; // e.g., "3 Bekas", "6 Bekas"
  int count; // number of pieces in the combo
  double price;
  String variant; // normal, small

  ComboPack({
    required this.id,
    required this.name,
    required this.count,
    required this.price,
    required this.variant,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'count': count,
      'price': price,
      'variant': variant,
    };
  }

  factory ComboPack.fromMap(String id, Map<String, dynamic> map) {
    return ComboPack(
      id: id,
      name: map['name'],
      count: map['count'],
      price: map['price'].toDouble(),
      variant: map['variant'],
    );
  }
}

