import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../utils/date_formatter.dart';
import '../utils/navigation_helper.dart';
import '../utils/price_calculator.dart';
import '../widgets/smooth_reveal.dart';
import 'add_order.dart';
import 'order_detail.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OrdersScreen extends StatefulWidget {
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'today'; // 'today', 'all'
  String? _selectedStatus; // null = all, 'pending', 'completed'
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showSummary = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleStatusChange(BuildContext context, Order order, bool value) async {
    final newStatus = value ? 'completed' : 'pending';

    if (newStatus == 'completed' && !order.isPaid) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.payment, color: Colors.green[700]),
              ),
              SizedBox(width: 12),
              Text('Payment Confirmation'),
            ],
          ),
          content: Text(
            'Has the customer already made the payment?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Yes, Paid'),
            ),
          ],
        ),
      );

      if (result != true) {
        return;
      }
      order.isPaid = true;
    }

    order.status = newStatus;
    await _fs.updateOrder(order);
    Fluttertoast.showToast(
      msg: newStatus == 'completed' ? "Order completed! ✓" : "Order marked as pending",
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _showDeleteDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red[700]),
            ),
            SizedBox(width: 12),
            Text('Delete Order'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              _fs.deleteOrder(order.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Order deleted successfully");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text("Customer Orders"),
        actions: [
          if (_viewMode == 'today')
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: SvgIcon(
                  assetPath: 'assets/icons/calendar-icon.svg',
                  size: 22,
                  color: Colors.white,
                ),
                onPressed: () => _selectDate(context),
                tooltip: 'Select Date',
              ),
            ),
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: SvgIcon(
                assetPath: 'assets/icons/add-icon.svg',
                size: 22,
                color: Colors.white,
              ),
              onPressed: () => NavigationHelper.navigateWithBounce(context, AddOrderScreen()),
              tooltip: 'Add Order',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Date Display with gradient (only show when in 'today' mode)
            if (_viewMode == 'today')
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Colors.orange[50]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormatter.getRelativeDate(_selectedDate),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          DateFormatter.formatDate(_selectedDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 1,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              SvgIcon(
                                assetPath: 'assets/icons/calendar-icon.svg',
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // View Mode & Status Filter in one section
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // View Mode Toggle
                  Row(
                    children: [
                      Expanded(
                        child: _buildViewModeChip(
                          'Today',
                          'today',
                          Icons.today,
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildViewModeChip(
                          'All Time',
                          'all',
                          Icons.history,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Status Filter
                  Text(
                    'Filter by Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusChip('All', null, Icons.all_inclusive, Colors.blue),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusChip('Pending', 'pending', Icons.pending_actions, Colors.orange),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusChip('Completed', 'completed', Icons.check_circle, Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Divider(height: 1),
            
            Expanded(
              child: StreamBuilder<List<Order>>(
                key: ValueKey('orders_${_viewMode}_${_selectedDate.millisecondsSinceEpoch}'),
                stream: _viewMode == 'today' 
                    ? _fs.getOrdersByDate(_selectedDate)
                    : _fs.getAllOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text("Loading orders...", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(child: Text('No data'));
                  }
                  
                  var allOrders = snapshot.data!;
                  var orders = allOrders.where((order) {
                    final hasItems = order.items.isNotEmpty;
                    final hasComboPacks = order.comboPacks.isNotEmpty && 
                        order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
                    final hasValidPcs = order.totalPcs > 0;
                    final hasValidPrice = order.totalPrice > 0;
                    return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
                  }).toList();
                  
                  if (_selectedStatus != null) {
                    orders = orders.where((o) => o.status == _selectedStatus).toList();
                  }
                  
                  // Calculate summary stats
                  final totalOrders = orders.length;
                  final pendingCount = orders.where((o) => o.status == 'pending').length;
                  final completedCount = orders.where((o) => o.status == 'completed').length;
                  final totalRevenue = orders.fold(0.0, (sum, order) => sum + order.totalPrice);
                  final totalPieces = orders.fold(0, (sum, order) => sum + order.totalPcs);
                  
                  if (orders.isEmpty) {
                    return SmoothReveal(
                      child: EmptyState(
                        message: _viewMode == 'today'
                            ? "No orders for ${DateFormatter.formatDate(_selectedDate)}${_selectedStatus != null ? ' ($_selectedStatus)' : ''}"
                            : "No orders${_selectedStatus != null ? ' ($_selectedStatus)' : ''}",
                        iconPath: 'assets/icons/orders-icon.svg',
                        actionLabel: "Add Order",
                        onAction: () => NavigationHelper.navigateWithBounce(context, AddOrderScreen()),
                      ),
                    );
                  }
                  
                  return Column(
                    children: [
                      // Summary Section
                      if (_selectedStatus == null) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          color: Colors.white,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _showSummary ? Icons.expand_less : Icons.expand_more,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showSummary = !_showSummary;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_showSummary) ...[
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Pending',
                                        pendingCount.toString(),
                                        Icons.pending_actions,
                                        Colors.orange,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Completed',
                                        completedCount.toString(),
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total Revenue',
                                        PriceCalculator.formatPrice(totalRevenue),
                                        Icons.attach_money,
                                        Colors.blue,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total Pieces',
                                        '$totalPieces pcs',
                                        Icons.inventory_2,
                                        Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Divider(height: 1),
                      ],
                      
                      // Orders List Header
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        color: Colors.grey[50],
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.blue[700], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Orders (${orders.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Orders List
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: orders.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final o = orders[index];
                            return SmoothReveal(
                              delay: Duration(milliseconds: index * 30),
                              child: OrderCard(
                                order: o,
                                onTap: () => NavigationHelper.navigateWithBounce(
                                  context,
                                  OrderDetailScreen(order: o),
                                ),
                                onStatusChanged: (value) => _handleStatusChange(context, o, value),
                                onDelete: () => _showDeleteDialog(context, o),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeChip(String label, String value, IconData icon, Color color) {
    final isSelected = _viewMode == value;
    return InkWell(
      onTap: () {
        setState(() {
          _viewMode = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String? value, IconData icon, Color color) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}