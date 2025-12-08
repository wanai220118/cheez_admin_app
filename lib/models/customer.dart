class Customer {
  String id;
  String name;
  String contactNo;
  String address;
  DateTime createdAt;
  DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.contactNo,
    required this.address,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactNo': contactNo,
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      contactNo: map['contactNo'] ?? '',
      address: map['address'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }
}

