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
import '../models/order.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _fs = FirestoreService();
  final SummaryService _summaryService = SummaryService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout'),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cheez n' Cream Co.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(today),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: SvgIcon(
                assetPath: 'assets/icons/logout-icon.svg',
                size: 22,
                color: Colors.white,
              ),
              onPressed: () => _handleLogout(context),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Enhanced Overview Section
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    children: [
                      // Title and Page Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPage == 0 ? "Today's Overview" 
                                      : _currentPage == 1 ? "Weekly Overview" 
                                      : "All Time Overview",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _currentPage == 0 ? "Real-time updates" 
                                      : _currentPage == 1 ? "Last 7 days" 
                                      : "Complete history",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPageIndicator(0),
                                SizedBox(width: 6),
                                _buildPageIndicator(1),
                                SizedBox(width: 6),
                                _buildPageIndicator(2),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Swipeable PageView with improved stats cards
                      SizedBox(
                        height: 150,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          children: [
                            _buildTodayOverview(today),
                            _buildWeeklyOverview(today),
                            _buildAllTimeOverview(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Navigation Grid
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.dashboard_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Quick Access",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Grid layout with 2 columns
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                      children: [
                        _dashboardGridButton(context, "Products", 'assets/icons/products-icon.svg', ProductsScreen(), Colors.blue),
                        _dashboardGridButton(context, "Orders", 'assets/icons/orders-icon.svg', OrdersScreen(), Colors.orange),
                        _dashboardGridButton(context, "Daily Summary", 'assets/icons/summary-icon.svg', DailySummaryScreen(), Colors.purple),
                        _dashboardGridButton(context, "Sales", 'assets/icons/sales-icon.svg', SalesScreen(), Colors.green),
                        _dashboardGridButton(context, "Expenses", 'assets/icons/expenses-icon.svg', ExpensesScreen(), Colors.red),
                        _dashboardGridButton(context, "Order Analysis", 'assets/icons/moped.svg', OrderAnalysisScreen(), Colors.teal),
                        _dashboardGridButton(context, "Customers", 'assets/icons/people-group.svg', CustomersScreen(), Colors.indigo),
                        _scanToPayGridButton(context),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: _currentPage == index ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
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

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatCard(
                          "Revenue",
                          PriceCalculator.formatPrice(totalRevenue),
                          Icons.attach_money_rounded,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildEnhancedStatCard(
                          "Orders",
                          totalOrdersToday.toString(),
                          Icons.receipt_long_rounded,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatCard(
                          "Profit",
                          PriceCalculator.formatPrice(totalProfit),
                          Icons.trending_up_rounded,
                          Colors.purple,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildEnhancedStatCard(
                          "Pieces",
                          "$totalPcsToday pcs",
                          Icons.inventory_2_rounded,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeeklyOverview(DateTime today) {
    int daysFromMonday = today.weekday - 1;
    DateTime monday = today.subtract(Duration(days: daysFromMonday));
    
    return StreamBuilder(
      stream: _fs.getAllOrders(),
      builder: (context, ordersSnapshot) {
        if (!ordersSnapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        final allOrders = ordersSnapshot.data!;
        final orders = allOrders.where((order) {
          final hasItems = order.items.isNotEmpty;
          final hasComboPacks = order.comboPacks.isNotEmpty && 
              order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
          final hasValidPcs = order.totalPcs > 0;
          final hasValidPrice = order.totalPrice > 0;
          return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
        }).toList();
        
        Map<int, List<Order>> ordersByDay = {};
        for (int i = 0; i < 7; i++) {
          ordersByDay[i] = [];
        }
        
        for (var order in orders) {
          final orderDate = order.orderDate;
          final daysDiff = orderDate.difference(monday).inDays;
          if (daysDiff >= 0 && daysDiff < 7) {
            ordersByDay[daysDiff]!.add(order);
          }
        }
        
        List<Map<String, dynamic>> weeklyStats = [];
        
        for (int i = 0; i < 7; i++) {
          final dayOrders = ordersByDay[i] ?? [];
          final revenue = dayOrders.fold(0.0, (sum, order) => sum + order.totalPrice);
          final pcs = dayOrders.fold(0, (sum, order) => sum + order.totalPcs) as int;
          final orderCount = dayOrders.length;
          
          weeklyStats.add({
            'revenue': revenue,
            'pcs': pcs,
            'orders': orderCount,
          });
        }
        
        final totalRevenue = weeklyStats.fold(0.0, (sum, day) => sum + (day['revenue'] as double));
        final totalPcs = weeklyStats.fold(0, (sum, day) => sum + (day['pcs'] as int)) as int;
        final totalOrders = weeklyStats.fold(0, (sum, day) => sum + (day['orders'] as int)) as int;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedStatCard(
                      "Revenue",
                      PriceCalculator.formatPrice(totalRevenue),
                      Icons.attach_money_rounded,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildEnhancedStatCard(
                      "Orders",
                      totalOrders.toString(),
                      Icons.receipt_long_rounded,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedStatCard(
                      "Avg/Day",
                      PriceCalculator.formatPrice(totalRevenue / 7),
                      Icons.trending_up_rounded,
                      Colors.purple,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildEnhancedStatCard(
                      "Pieces",
                      "$totalPcs pcs",
                      Icons.inventory_2_rounded,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatCard(
                          "Revenue",
                          PriceCalculator.formatPrice(totalRevenueAll),
                          Icons.attach_money_rounded,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildEnhancedStatCard(
                          "Orders",
                          totalOrdersAll.toString(),
                          Icons.receipt_long_rounded,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatCard(
                          "Profit",
                          PriceCalculator.formatPrice(totalProfitAll),
                          Icons.trending_up_rounded,
                          Colors.purple,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildEnhancedStatCard(
                          "Pieces",
                          "$totalPcsAll pcs",
                          Icons.inventory_2_rounded,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 54,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardButton(BuildContext context, String title, String iconPath, Widget screen, Color color) {
    return Hero(
      tag: title,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 80, // Fixed height for rectangular shape (width > height)
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => NavigationHelper.navigateWithBounce(context, screen),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgIcon(
                      assetPath: iconPath,
                      size: 28,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashboardGridButton(BuildContext context, String title, String iconPath, Widget screen, Color color) {
    return Hero(
      tag: title,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => NavigationHelper.navigateWithBounce(context, screen),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgIcon(
                      assetPath: iconPath,
                      size: 32,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scanToPayButton(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[600]!,
            Colors.orange[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            NavigationHelper.selectionClick();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 8),
                              Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.orange[600]),
                              SizedBox(height: 12),
                              Text(
                                "Scan To Pay",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 20),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
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
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgIcon(
                    assetPath: 'assets/icons/qr.svg',
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Scan To Pay",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scanToPayGridButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[600]!,
            Colors.orange[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            NavigationHelper.selectionClick();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 8),
                              Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.orange[600]),
                              SizedBox(height: 12),
                              Text(
                                "Scan To Pay",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 20),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
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
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgIcon(
                    assetPath: 'assets/icons/qr.svg',
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Scan To Pay",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}