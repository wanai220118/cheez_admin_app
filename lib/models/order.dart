class Order {
  String id;
  String customerName;
  String phone;
  DateTime orderDate;
  DateTime? pickupDateTime; // Pickup date and time
  String paymentMethod; // 'cod' or 'pickup'
  bool isPaid; // Payment status
  double? codFee; // COD fee amount (if any)
  String? codAddress; // COD address (if any)
  String paymentChannel; // 'cash' or 'qr'
  Map<String, int> items; // single items pcs
  Map<String, Map<String,int>> comboPacks; // combo flavor allocation
  int totalPcs;
  double totalPrice;
  String status; // pending/completed

  Order({
    required this.id,
    required this.customerName,
    this.phone = '',
    required this.orderDate,
    this.pickupDateTime,
    this.paymentMethod = 'cod',
    this.isPaid = false,
    this.codFee,
    this.codAddress,
    this.paymentChannel = 'cash',
    required this.items,
    required this.comboPacks,
    required this.totalPcs,
    required this.totalPrice,
    required this.status,
  });

  Map<String,dynamic> toMap() {
    return {
      'customerName': customerName,
      'phone': phone,
      'orderDate': orderDate,
      'pickupDateTime': pickupDateTime,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'codFee': codFee,
      'codAddress': codAddress,
      'paymentChannel': paymentChannel,
      'items': items,
      'comboPacks': comboPacks,
      'totalPcs': totalPcs,
      'totalPrice': totalPrice,
      'status': status,
    };
  }

  factory Order.fromMap(String id, Map<String,dynamic> map) {
    // Safely parse items
    Map<String, int> items = {};
    if (map['items'] != null) {
      final itemsData = map['items'];
      if (itemsData is Map) {
        final itemsMap = itemsData as Map<dynamic, dynamic>;
        itemsMap.forEach((key, value) {
          items[key.toString()] = value is int ? value : (value as num).toInt();
        });
      } else if (itemsData is List) {
        // Handle case where items might be stored as a list (legacy data)
        // Skip parsing if it's a list - this shouldn't happen but handle gracefully
      }
    }

    // Safely parse comboPacks
    Map<String, Map<String, int>> comboPacks = {};
    if (map['comboPacks'] != null) {
      final comboData = map['comboPacks'];
      if (comboData is Map) {
        final comboMap = comboData as Map<dynamic, dynamic>;
        comboMap.forEach((comboKey, allocation) {
          Map<String, int> flavorMap = {};
          if (allocation is Map) {
            (allocation as Map<dynamic, dynamic>).forEach((flavorKey, quantity) {
              flavorMap[flavorKey.toString()] = quantity is int ? quantity : (quantity as num).toInt();
            });
          } else if (allocation is List) {
            // Handle case where allocation might be a list (shouldn't happen, but handle gracefully)
            // Skip this entry if it's not a map
          }
          comboPacks[comboKey.toString()] = flavorMap;
        });
      } else if (comboData is List) {
        // Handle case where comboPacks might be stored as a list (legacy data)
        // Skip parsing if it's a list
      }
    }

    return Order(
      id: id,
      customerName: map['customerName'] ?? '',
      phone: map['phone'] ?? '',
      orderDate: map['orderDate']?.toDate() ?? DateTime.now(),
      pickupDateTime: map['pickupDateTime']?.toDate(),
      paymentMethod: map['paymentMethod'] ?? 'cod',
      isPaid: map['isPaid'] ?? false,
      codFee: map['codFee'] != null ? (map['codFee'] as num).toDouble() : null,
      codAddress: map['codAddress'],
      paymentChannel: map['paymentChannel'] ?? 'cash',
      items: items,
      comboPacks: comboPacks,
      totalPcs: map['totalPcs'] is int ? map['totalPcs'] : (map['totalPcs'] as num?)?.toInt() ?? 0,
      totalPrice: map['totalPrice'] is double ? map['totalPrice'] : (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
    );
  }
}
