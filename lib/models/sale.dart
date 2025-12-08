class Sale {
  String id;
  String productName;
  String variant;
  int quantity;
  double totalPrice;
  DateTime date;

  Sale({
    required this.id,
    required this.productName,
    required this.variant,
    required this.quantity,
    required this.totalPrice,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'variant': variant,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'date': date,
    };
  }

  factory Sale.fromMap(String id, Map<String, dynamic> map) {
    return Sale(
      id: id,
      productName: map['productName'],
      variant: map['variant'],
      quantity: map['quantity'],
      totalPrice: map['totalPrice'].toDouble(),
      date: map['date'].toDate(),
    );
  }
}
