import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../utils/date_formatter.dart';
import '../utils/navigation_helper.dart';
import '../widgets/smooth_reveal.dart';
import 'add_order.dart';
import 'order_detail.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OrdersScreen extends StatefulWidget {
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirestoreService _fs = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'today'; // 'today', 'all'
  String? _selectedStatus; // null = all, 'pending', 'completed'

  Future<void> _handleStatusChange(BuildContext context, Order order, bool value) async {
    final newStatus = value ? 'completed' : 'pending';

    if (newStatus == 'completed' && !order.isPaid) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Payment Confirmation'),
          content: Text('Has the customer already made the payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes'),
            ),
          ],
        ),
      );

      // If dialog dismissed or admin answered "No", do NOT mark as completed
      if (result != true) {
        // Just return; UI will rebuild with status still pending
        return;
      }

      // Admin confirmed payment; mark as paid
      order.isPaid = true;
    }

    order.status = newStatus;
    await _fs.updateOrder(order);
  }

  Future<void> _handlePaymentChange(BuildContext context, Order order, bool value) async {
    order.isPaid = value;
    await _fs.updateOrder(order);
    Fluttertoast.showToast(
      msg: value ? "Payment marked as received" : "Payment marked as not received",
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showDeleteDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Order'),
        content: Text('Are you sure you want to delete this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _fs.deleteOrder(order.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Order deleted successfully");
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customer Orders"),
        actions: [
          if (_viewMode == 'today')
            IconButton(
              icon: SvgIcon(
                assetPath: 'assets/icons/calendar-icon.svg',
                size: 24,
                color: Colors.white,
              ),
              onPressed: () => _selectDate(context),
              tooltip: 'Select Date',
            ),
          IconButton(
            icon: SvgIcon(
              assetPath: 'assets/icons/add-icon.svg',
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => NavigationHelper.navigateWithBounce(context, AddOrderScreen()),
          )
        ],
      ),
      body: Column(
        children: [
          // Date Display (only show when in 'today' mode)
          if (_viewMode == 'today')
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.orange[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.getRelativeDate(_selectedDate),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: SvgIcon(
                      assetPath: 'assets/icons/calendar-icon.svg',
                      size: 20,
                    ),
                    label: Text('Change Date'),
                  ),
                ],
              ),
            ),
          // View Mode Toggle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Today'),
                    selected: _viewMode == 'today',
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: _viewMode == 'today' ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _viewMode = 'today');
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('All Time'),
                    selected: _viewMode == 'all',
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: _viewMode == 'all' ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _viewMode = 'all');
                    },
                  ),
                ),
              ],
            ),
          ),
          // Status Filter Tabs
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('All'),
                    selected: _selectedStatus == null,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: _selectedStatus == null ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatus = null);
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Pending'),
                    selected: _selectedStatus == 'pending',
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'pending' ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatus = 'pending');
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Completed'),
                    selected: _selectedStatus == 'completed',
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'completed' ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatus = 'completed');
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Order>>(
              key: ValueKey('orders_${_viewMode}_${_selectedDate.millisecondsSinceEpoch}'),
              stream: _viewMode == 'today' 
                  ? _fs.getOrdersByDate(_selectedDate)
                  : _fs.getAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('No data'));
                }
                var allOrders = snapshot.data!;
                
                // Filter out invalid/deleted orders (orders with no items, zero pieces, or zero price)
                var orders = allOrders.where((order) {
                  final hasItems = order.items.isNotEmpty;
                  final hasComboPacks = order.comboPacks.isNotEmpty && 
                      order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
                  final hasValidPcs = order.totalPcs > 0;
                  final hasValidPrice = order.totalPrice > 0;
                  
                  // Include order only if it has items/comboPacks AND valid pieces AND valid price
                  return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
                }).toList();
                
                if (_selectedStatus != null) {
                  orders = orders.where((o) => o.status == _selectedStatus).toList();
                }
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
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return SmoothReveal(
                      delay: Duration(milliseconds: index * 50),
                      child: OrderCard(
                        order: o,
                        onTap: () => NavigationHelper.navigateWithBounce(
                          context,
                          OrderDetailScreen(order: o),
                        ),
                        onStatusChanged: (value) => _handleStatusChange(context, o, value),
                        onPaymentChanged: (value) => _handlePaymentChange(context, o, value),
                        onDelete: () => _showDeleteDialog(context, o),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
