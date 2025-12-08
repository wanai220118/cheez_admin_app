class DailySummary {
  String id;
  DateTime date;
  int totalOrders;
  int totalPcs;
  Map<String, int> flavorCount; // flavor name -> quantity
  double totalRevenue;
  double totalExpenses;
  double netProfit;

  DailySummary({
    required this.id,
    required this.date,
    required this.totalOrders,
    required this.totalPcs,
    required this.flavorCount,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalOrders': totalOrders,
      'totalPcs': totalPcs,
      'flavorCount': flavorCount,
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
    };
  }

  factory DailySummary.fromMap(String id, Map<String, dynamic> map) {
    // Safely convert flavorCount from Map<String, dynamic> to Map<String, int>
    Map<String, int> flavorCount = {};
    if (map['flavorCount'] != null) {
      final flavorMap = map['flavorCount'] as Map<dynamic, dynamic>;
      flavorMap.forEach((key, value) {
        flavorCount[key.toString()] = value is int ? value : (value as num).toInt();
      });
    }
    
    return DailySummary(
      id: id,
      date: map['date'] is DateTime ? map['date'] : map['date'].toDate(),
      totalOrders: map['totalOrders'] is int ? map['totalOrders'] : (map['totalOrders'] as num).toInt(),
      totalPcs: map['totalPcs'] is int ? map['totalPcs'] : (map['totalPcs'] as num).toInt(),
      flavorCount: flavorCount,
      totalRevenue: map['totalRevenue'] is double ? map['totalRevenue'] : map['totalRevenue'].toDouble(),
      totalExpenses: map['totalExpenses'] is double ? map['totalExpenses'] : map['totalExpenses'].toDouble(),
      netProfit: map['netProfit'] is double ? map['netProfit'] : map['netProfit'].toDouble(),
    );
  }
}

