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
  /// Custom bundle packages: each has "items" (itemKey -> qty) and "finalPrice". For profit tracking.
  List<Map<String, dynamic>>? bundlePackages;
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
    this.bundlePackages,
    required this.totalPcs,
    required this.totalPrice,
    required this.status,
  });

  /// Items to display and use for analytics: real product names and quantities only.
  /// Skips any "Bundle (RM x)" keys and expands bundlePackages so bundles show as real products.
  Map<String, int> get displayItems {
    final hasBundleKey = items.keys.any((k) => k.startsWith('Bundle'));
    if (hasBundleKey && bundlePackages != null && bundlePackages!.isNotEmpty) {
      final result = <String, int>{};
      for (final e in items.entries) {
        if (!e.key.startsWith('Bundle')) {
          result[e.key] = (result[e.key] ?? 0) + e.value;
        }
      }
      for (final b in bundlePackages!) {
        final bundleItems = b['items'];
        if (bundleItems is Map) {
          (bundleItems as Map<dynamic, dynamic>).forEach((k, v) {
            final key = k.toString();
            final q = v is int ? v : (v as num?)?.toInt() ?? 0;
            if (q > 0) result[key] = (result[key] ?? 0) + q;
          });
        }
      }
      return result;
    }
    // New format: items already has real products; still skip any legacy Bundle key
    final result = <String, int>{};
    for (final e in items.entries) {
      if (!e.key.startsWith('Bundle')) {
        result[e.key] = (result[e.key] ?? 0) + e.value;
      }
    }
    return result;
  }

  /// Total pieces for display/analytics (sum of displayItems). Use this instead of totalPcs when showing counts.
  int get displayTotalPcs {
    int n = 0;
    displayItems.forEach((_, qty) => n += qty);
    return n;
  }

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
      'bundlePackages': bundlePackages,
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

    // Safely parse bundlePackages (optional)
    List<Map<String, dynamic>>? bundlePackages;
    if (map['bundlePackages'] != null && map['bundlePackages'] is List) {
      final list = (map['bundlePackages'] as List).cast<dynamic>();
      bundlePackages = [];
      for (final e in list) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
        final itemsMap = m['items'];
        final Map<String, int> bundleItems = {};
        if (itemsMap is Map) {
          (itemsMap as Map<dynamic, dynamic>).forEach((k, v) {
            bundleItems[k.toString()] = v is int ? v : (v as num).toInt();
          });
        }
        final price = m['finalPrice'];
        bundlePackages.add({
          'items': bundleItems,
          'finalPrice': price is double ? price : (price as num).toDouble(),
        });
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
      bundlePackages: bundlePackages,
      totalPcs: map['totalPcs'] is int ? map['totalPcs'] : (map['totalPcs'] as num?)?.toInt() ?? 0,
      totalPrice: map['totalPrice'] is double ? map['totalPrice'] : (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
    );
  }
}
