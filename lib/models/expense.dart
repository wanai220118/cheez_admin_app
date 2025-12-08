class ExpenseItem {
  String itemName;
  double quantity;
  double pricePerItem;
  double totalCost;
  String? supplier;

  ExpenseItem({
    required this.itemName,
    required this.quantity,
    required this.pricePerItem,
    required this.totalCost,
    this.supplier,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'pricePerItem': pricePerItem,
      'totalCost': totalCost,
      'supplier': supplier,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      itemName: map['itemName'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      pricePerItem: map['pricePerItem']?.toDouble() ?? 0.0,
      totalCost: map['totalCost']?.toDouble() ?? 0.0,
      supplier: map['supplier'],
    );
  }
}

class Expense {
  String id;
  String category; // packaging, ingredients, utilities, commission, expense, etc
  String? subcategory;
  List<ExpenseItem> items;
  double totalCost;
  DateTime date;
  String? supplier; // Overall supplier if all items from same supplier

  Expense({
    required this.id,
    required this.category,
    this.subcategory,
    required this.items,
    required this.totalCost,
    required this.date,
    this.supplier,
  });

  Map<String,dynamic> toMap(){
    return {
      'category': category,
      'subcategory': subcategory,
      'items': items.map((item) => item.toMap()).toList(),
      'totalCost': totalCost,
      'date': date,
      'supplier': supplier,
    };
  }

  factory Expense.fromMap(String id, Map<String,dynamic> map){
    List<ExpenseItem> itemsList = [];
    if (map['items'] != null) {
      final itemsData = map['items'] as List<dynamic>;
      itemsList = itemsData.map((item) => ExpenseItem.fromMap(item as Map<String, dynamic>)).toList();
    }
    
    return Expense(
      id: id,
      category: map['category'] ?? 'expense',
      subcategory: map['subcategory'],
      items: itemsList,
      totalCost: map['totalCost']?.toDouble() ?? (map['cost']?.toDouble() ?? 0.0), // Support old format
      date: map['date']?.toDate() ?? DateTime.now(),
      supplier: map['supplier'],
    );
  }
}
