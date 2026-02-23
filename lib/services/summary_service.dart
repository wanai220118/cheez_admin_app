import '../models/daily_summary.dart';
import '../services/firestore_service.dart';

class SummaryService {
  final FirestoreService _fs = FirestoreService();

  // Generate daily summary from orders and expenses
  Future<DailySummary> generateDailySummary(DateTime date) async {
    // Get orders for the date
    final allOrders = await _fs.getOrdersByDate(date).first;

    // Filter out invalid/deleted orders (orders with no items, zero pieces, or zero price)
    final orders = allOrders.where((order) {
      final display = order.displayItems;
      final hasItems = display.isNotEmpty;
      final hasComboPacks = order.comboPacks.isNotEmpty && 
          order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
      final hasValidPcs = order.displayTotalPcs > 0;
      final hasValidPrice = order.totalPrice > 0;
      return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
    }).toList();

    // Get expenses for the date (if available)
    final expenses = await _fs.getExpensesByDate(date).first;

    // Calculate totals
    int totalOrders = orders.length;
    int totalPcs = 0;
    Map<String, int> flavorCount = {};
    double totalRevenue = 0.0;
    double totalExpenses = 0.0;

    // Process orders
    for (var order in orders) {
      int orderPcs = order.displayTotalPcs;
      order.comboPacks.forEach((_, allocation) {
        allocation.forEach((_, quantity) {
          orderPcs += quantity;
        });
      });

      totalPcs += orderPcs;
      totalRevenue += order.totalPrice;

      order.displayItems.forEach((flavor, quantity) {
        final currentCount = flavorCount[flavor] ?? 0;
        flavorCount[flavor] = currentCount + quantity;
      });

      // Count flavors from combo packs
      order.comboPacks.forEach((combo, allocation) {
        allocation.forEach((flavor, quantity) {
          final currentCount = flavorCount[flavor] ?? 0;
          flavorCount[flavor] = currentCount + quantity;
        });
      });
    }

    // Process expenses
    for (var expense in expenses) {
      totalExpenses += expense.totalCost;
    }

    // Calculate net profit
    double netProfit = totalRevenue - totalExpenses;

    return DailySummary(
      id: '',
      date: date,
      totalOrders: totalOrders,
      totalPcs: totalPcs,
      flavorCount: flavorCount,
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
    );
  }

  // Generate all-time summary from all orders and expenses
  Future<DailySummary> generateAllTimeSummary() async {
    // Get all orders
    final allOrders = await _fs.getAllOrders().first;

    // Filter out invalid/deleted orders (orders with no items, zero pieces, or zero price)
    final orders = allOrders.where((order) {
      final display = order.displayItems;
      final hasItems = display.isNotEmpty;
      final hasComboPacks = order.comboPacks.isNotEmpty && 
          order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
      final hasValidPcs = order.displayTotalPcs > 0;
      final hasValidPrice = order.totalPrice > 0;
      return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
    }).toList();

    // Get all expenses
    final expenses = await _fs.getAllExpenses().first;

    // Calculate totals
    int totalOrders = orders.length;
    int totalPcs = 0;
    Map<String, int> flavorCount = {};
    double totalRevenue = 0.0;
    double totalExpenses = 0.0;

    // Process orders
    for (var order in orders) {
      int orderPcs = order.displayTotalPcs;
      order.comboPacks.forEach((_, allocation) {
        allocation.forEach((_, quantity) {
          orderPcs += quantity;
        });
      });

      totalPcs += orderPcs;
      totalRevenue += order.totalPrice;

      order.displayItems.forEach((flavor, quantity) {
        final currentCount = flavorCount[flavor] ?? 0;
        flavorCount[flavor] = currentCount + quantity;
      });

      // Count flavors from combo packs
      order.comboPacks.forEach((combo, allocation) {
        allocation.forEach((flavor, quantity) {
          final currentCount = flavorCount[flavor] ?? 0;
          flavorCount[flavor] = currentCount + quantity;
        });
      });
    }

    // Process expenses
    for (var expense in expenses) {
      totalExpenses += expense.totalCost;
    }

    // Calculate net profit
    double netProfit = totalRevenue - totalExpenses;

    return DailySummary(
      id: '',
      date: DateTime.now(), // Use current date for all-time summary
      totalOrders: totalOrders,
      totalPcs: totalPcs,
      flavorCount: flavorCount,
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
    );
  }
}

