import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../widgets/flavor_count_tile.dart';
import '../utils/date_formatter.dart';
import '../utils/price_calculator.dart';
import 'order_detail.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OrderAnalysisScreen extends StatefulWidget {
  @override
  State<OrderAnalysisScreen> createState() => _OrderAnalysisScreenState();
}

class _OrderAnalysisScreenState extends State<OrderAnalysisScreen> {
  final FirestoreService _fs = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaymentMethod; // null = all, 'cod', 'pickup'

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)), // Allow future dates
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Analysis"),
        actions: [
          IconButton(
            icon: SvgIcon(
              assetPath: 'assets/icons/calendar-icon.svg',
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Display
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.getRelativeDate(_selectedDate),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Pickup/COD: ${DateFormatter.formatDate(_selectedDate)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
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
          // Payment Method Filter Tabs
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('All'),
                    selected: _selectedPaymentMethod == null,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: _selectedPaymentMethod == null ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPaymentMethod = null);
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('COD'),
                    selected: _selectedPaymentMethod == 'cod',
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: _selectedPaymentMethod == 'cod' ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPaymentMethod = 'cod');
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Pickup'),
                    selected: _selectedPaymentMethod == 'pickup',
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: _selectedPaymentMethod == 'pickup' ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPaymentMethod = 'pickup');
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Order>>(
              key: ValueKey('order_analysis_${_selectedDate.millisecondsSinceEpoch}'),
              stream: _fs.getOrdersByPickupDate(_selectedDate),
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
                
                // Filter out invalid/deleted orders
                var orders = allOrders.where((order) {
                  final hasItems = order.items.isNotEmpty;
                  final hasComboPacks = order.comboPacks.isNotEmpty && 
                      order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
                  final hasValidPcs = order.totalPcs > 0;
                  final hasValidPrice = order.totalPrice > 0;
                  return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
                }).toList();
                
                // Filter by payment method if selected
                if (_selectedPaymentMethod != null) {
                  orders = orders.where((o) => o.paymentMethod == _selectedPaymentMethod).toList();
                }
                
                // Calculate statistics
                int codCount = orders.where((o) => o.paymentMethod == 'cod').length;
                int pickupCount = orders.where((o) => o.paymentMethod == 'pickup').length;
                double codRevenue = orders.where((o) => o.paymentMethod == 'cod')
                    .fold(0.0, (sum, order) => sum + order.totalPrice);
                double pickupRevenue = orders.where((o) => o.paymentMethod == 'pickup')
                    .fold(0.0, (sum, order) => sum + order.totalPrice);
                
                // Calculate flavor counts
                Map<String, int> flavorCount = {};
                for (var order in orders) {
                  // Count flavors from single items
                  order.items.forEach((flavor, quantity) {
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
                
                if (orders.isEmpty) {
                  return EmptyState(
                    message: "No pickup/COD orders scheduled for ${DateFormatter.formatDate(_selectedDate)}${_selectedPaymentMethod != null ? ' (${_selectedPaymentMethod!.toUpperCase()})' : ''}",
                    iconPath: 'assets/icons/orders-icon.svg',
                  );
                }
                
                return Column(
                  children: [
                    // Summary Cards
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.orange[50],
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      "COD Orders",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "$codCount",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      PriceCalculator.formatPrice(codRevenue),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              color: Colors.green[50],
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      "Pickup Orders",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "$pickupCount",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[900],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      PriceCalculator.formatPrice(pickupRevenue),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
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
                    // Flavor Count Section
                    if (flavorCount.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Flavor Count",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Card(
                              child: Column(
                                children: (() {
                                  var sortedEntries = flavorCount.entries.toList()
                                    ..sort((a, b) => b.value.compareTo(a.value));
                                  return sortedEntries
                                      .map((entry) => FlavorCountTile(
                                            flavor: entry.key,
                                            count: entry.value,
                                          ))
                                      .toList();
                                })(),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                    // Orders List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return OrderCard(
                            order: order,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                            ),
                            onStatusChanged: null, // No status change in analysis view
                            onDelete: null, // No delete in analysis view
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
    );
  }
}

