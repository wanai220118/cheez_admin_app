import 'package:flutter/material.dart';
import 'products.dart';
import 'orders.dart';
import 'daily_summary.dart';
import 'sales.dart';
import 'expenses.dart';
import 'order_analysis.dart';
import 'customers.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/summary_service.dart';
import '../widgets/svg_icon.dart';
import '../utils/price_calculator.dart';
import '../utils/date_formatter.dart';
import '../utils/navigation_helper.dart';
import 'login.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _fs = FirestoreService();
  final SummaryService _summaryService = SummaryService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _authService.signOut();
      Fluttertoast.showToast(msg: "Logged out successfully");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Cheez n' Cream Co. Dashboard"),
        actions: [
          IconButton(
            icon: SvgIcon(
              assetPath: 'assets/icons/logout-icon.svg',
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Swipeable Overview Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentPage == 0 ? "Today's Overview" : "All Time Overview",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPageIndicator(0),
                          SizedBox(width: 8),
                          _buildPageIndicator(1),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Swipeable PageView
                  SizedBox(
                    height: 280,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        // Today's Overview Page
                        _buildTodayOverview(today),
                        // All Time Overview Page
                        _buildAllTimeOverview(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            // Navigation Grid
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick Access",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      dashboardButton(context, "Products", 'assets/icons/products-icon.svg', ProductsScreen()),
                      dashboardButton(context, "Orders", 'assets/icons/orders-icon.svg', OrdersScreen()),
                      dashboardButton(context, "Daily Summary", 'assets/icons/summary-icon.svg', DailySummaryScreen()),
                      dashboardButton(context, "Sales", 'assets/icons/sales-icon.svg', SalesScreen()),
                      dashboardButton(context, "Expenses", 'assets/icons/expenses-icon.svg', ExpensesScreen()),
                      dashboardButton(context, "Order Analysis", 'assets/icons/moped.svg', OrderAnalysisScreen()),
                      dashboardButton(context, "Customers", 'assets/icons/people-group.svg', CustomersScreen()),
                      _scanToPayButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: _currentPage == index ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _currentPage == index
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildTodayOverview(DateTime today) {
    return StreamBuilder(
      stream: _fs.getOrdersByDate(today),
      builder: (context, ordersSnapshot) {
        return FutureBuilder(
          future: _summaryService.generateDailySummary(today),
          builder: (context, summarySnapshot) {
            int totalOrdersToday = 0;
            int totalPcsToday = 0;
            double totalRevenue = 0.0;
            double totalProfit = 0.0;

            if (ordersSnapshot.hasData) {
              final allOrders = ordersSnapshot.data!;
              // Filter out invalid/deleted orders (orders with no items, zero pieces, or zero price)
              final orders = allOrders.where((order) {
                final hasItems = order.items.isNotEmpty;
                final hasComboPacks = order.comboPacks.isNotEmpty && 
                    order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
                final hasValidPcs = order.totalPcs > 0;
                final hasValidPrice = order.totalPrice > 0;
                return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
              }).toList();
              
              totalOrdersToday = orders.length;
              totalPcsToday = orders.fold(0, (sum, order) => sum + order.totalPcs);
              totalRevenue = orders.fold(0.0, (sum, order) => sum + order.totalPrice);
            }

            if (summarySnapshot.hasData) {
              final summary = summarySnapshot.data!;
              totalRevenue = summary.totalRevenue;
              totalProfit = summary.netProfit;
            }

            return GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  context,
                  "Total Order",
                  PriceCalculator.formatPrice(totalRevenue),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  "Order Today",
                  "$totalPcsToday pcs",
                  Icons.inventory_2,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  "Profit",
                  PriceCalculator.formatPrice(totalProfit),
                  Icons.trending_up,
                  Colors.purple,
                ),
                _buildStatCard(
                  context,
                  "Total Orders",
                  totalOrdersToday.toString(),
                  Icons.receipt_long,
                  Colors.orange,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAllTimeOverview() {
    return StreamBuilder(
      stream: _fs.getAllOrders(),
      builder: (context, ordersSnapshot) {
        int totalOrdersAll = 0;
        int totalPcsAll = 0;
        double totalRevenueAll = 0.0;
        double totalProfitAll = 0.0;
        double totalExpensesAll = 0.0;

        if (ordersSnapshot.hasData) {
          final allOrders = ordersSnapshot.data!;
          // Filter out invalid/deleted orders (orders with no items, zero pieces, or zero price)
          final orders = allOrders.where((order) {
            final hasItems = order.items.isNotEmpty;
            final hasComboPacks = order.comboPacks.isNotEmpty && 
                order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
            final hasValidPcs = order.totalPcs > 0;
            final hasValidPrice = order.totalPrice > 0;
            return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
          }).toList();
          
          totalOrdersAll = orders.length;
          totalPcsAll = orders.fold(0, (sum, order) => sum + order.totalPcs);
          totalRevenueAll = orders.fold(0.0, (sum, order) => sum + order.totalPrice);
        }

        return StreamBuilder(
          stream: _fs.getAllExpenses(),
          builder: (context, expensesSnapshot) {
            if (expensesSnapshot.hasData) {
              final expenses = expensesSnapshot.data!;
              totalExpensesAll = expenses.fold(0.0, (sum, expense) => sum + expense.totalCost);
            }
            totalProfitAll = totalRevenueAll - totalExpensesAll;

            return GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  context,
                  "Total Revenue",
                  PriceCalculator.formatPrice(totalRevenueAll),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  "Total Pieces",
                  "$totalPcsAll pcs",
                  Icons.inventory_2,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  "Net Profit",
                  PriceCalculator.formatPrice(totalProfitAll),
                  Icons.trending_up,
                  Colors.purple,
                ),
                _buildStatCard(
                  context,
                  "Total Orders",
                  totalOrdersAll.toString(),
                  Icons.receipt_long,
                  Colors.orange,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
              ],
            ),
            SizedBox(height: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardButton(BuildContext context, String title, String iconPath, Widget screen) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => NavigationHelper.navigateWithBounce(context, screen),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(
              assetPath: iconPath,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanToPayButton(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          NavigationHelper.selectionClick();
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return Dialog(
                insetPadding: EdgeInsets.all(24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            "Scan To Pay",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/qr-payment.jpg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(
              assetPath: 'assets/icons/qr.svg',
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 12),
            Text(
              "Scan To Pay",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
