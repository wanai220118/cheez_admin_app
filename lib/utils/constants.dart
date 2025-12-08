import '../models/product.dart';

class AppConstants {
  // Products list
  static List<Product> defaultProducts = [
    Product(id: "", name: "Tiramisu", variant: "normal", price: 3.50, cost: 0),
    Product(id: "", name: "Tiramisu", variant: "small", price: 1.80, cost: 0),
    Product(id: "", name: "Cheesekut", variant: "normal", price: 3.50, cost: 0),
    Product(id: "", name: "Cheesekut", variant: "small", price: 1.80, cost: 0),
    Product(id: "", name: "Oreo Cheesekut", variant: "normal", price: 3.50, cost: 0),
    Product(id: "", name: "Oreo Cheesekut", variant: "small", price: 1.80, cost: 0),
    Product(id: "", name: "Bahumisu", variant: "normal", price: 3.50, cost: 0),
    // Combo packs as products (optional for reference)
    Product(id: "", name: "3 Bekas", variant: "combo", price: 10.0, cost: 0),
    Product(id: "", name: "6 Bekas", variant: "combo_small", price: 10.0, cost: 0),
  ];

  // Flavor options for combo packs
  static List<String> flavors = [
    "Tiramisu",
    "Cheesekut",
    "Oreo Cheesekut",
    "Bahumisu"
  ];

  // Combo pack mapping
  static Map<String, int> comboPackCount = {
    "3 Bekas": 3,
    "6 Bekas": 6,
  };
}
