import '../models/product.dart';
import '../models/order.dart';

class PriceCalculator {
  // Calculate total price for a list of products with quantities
  static double calculateTotalPrice(Map<String, int> items, List<Product> products) {
    double total = 0.0;
    items.forEach((name, quantity) {
      if (quantity > 0) {
        final product = products.firstWhere(
          (p) => p.name == name,
          orElse: () => Product(id: '', name: name, variant: 'normal', price: 0, cost: 0),
        );
        total += quantity * product.price;
      }
    });
    return total;
  }

  // Calculate total pieces
  static int calculateTotalPcs(Map<String, int> items) {
    return items.values.fold(0, (sum, quantity) => sum + quantity);
  }

  // Calculate order total including combo packs
  static double calculateOrderTotal(Order order, List<Product> products) {
    double total = 0.0;

    // Add single items
    order.items.forEach((name, quantity) {
      if (quantity > 0) {
        final product = products.firstWhere(
          (p) => p.name == name,
          orElse: () => Product(id: '', name: name, variant: 'normal', price: 0, cost: 0),
        );
        total += quantity * product.price;
      }
    });

    // Add combo packs
    order.comboPacks.forEach((comboType, allocation) {
      // Find combo pack product
      final comboProduct = products.firstWhere(
        (p) => p.variant == 'combo' || p.variant == 'combo_small',
        orElse: () => Product(id: '', name: comboType, variant: 'combo', price: 0, cost: 0),
      );

      // Calculate total pieces in combo allocation
      int comboPcs = allocation.values.fold(0, (sum, qty) => sum + qty);
      
      // Calculate number of combo packs needed
      int comboCount = (comboPcs / (comboType.contains('6') ? 6 : 3)).ceil();
      total += comboCount * comboProduct.price;
    });

    return total;
  }

  // Format price with currency symbol
  static String formatPrice(double price) {
    return 'RM ${price.toStringAsFixed(2)}';
  }

  // Calculate profit (revenue - cost)
  static double calculateProfit(double revenue, double cost) {
    return revenue - cost;
  }

  // Calculate profit margin percentage
  static double calculateProfitMargin(double revenue, double cost) {
    if (revenue == 0) return 0.0;
    return ((revenue - cost) / revenue) * 100;
  }
}

