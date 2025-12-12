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
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class OrderAnalysisScreen extends StatefulWidget {
  @override
  State<OrderAnalysisScreen> createState() => _OrderAnalysisScreenState();
}

class _OrderAnalysisScreenState extends State<OrderAnalysisScreen> {
  final FirestoreService _fs = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaymentMethod; // null = all, 'cod', 'pickup'
  bool _includeSummary = true;
  bool _includeFlavorCount = true;
  bool _includeOrders = true;

  Future<void> _showExportFilterDialog(BuildContext context) async {
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Export Options"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text("Include Summary"),
                  value: _includeSummary,
                  onChanged: (value) {
                    setState(() {
                      _includeSummary = value ?? true;
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text("Include Flavor Count"),
                  value: _includeFlavorCount,
                  onChanged: (value) {
                    setState(() {
                      _includeFlavorCount = value ?? true;
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text("Include Orders List"),
                  value: _includeOrders,
                  onChanged: (value) {
                    setState(() {
                      _includeOrders = value ?? true;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'includeSummary': _includeSummary,
                'includeFlavorCount': _includeFlavorCount,
                'includeOrders': _includeOrders,
              });
            },
            child: Text("Export"),
          ),
        ],
      ),
    );
    
    if (result != null) {
      _includeSummary = result['includeSummary'] ?? true;
      _includeFlavorCount = result['includeFlavorCount'] ?? true;
      _includeOrders = result['includeOrders'] ?? true;
      await _exportToPDF(context);
    }
  }

  Future<void> _exportToPDF(BuildContext context) async {
    try {
      final allOrders = await _fs.getOrdersByPickupDate(_selectedDate).first;
      
      var orders = allOrders.where((order) {
        final hasItems = order.items.isNotEmpty;
        final hasComboPacks = order.comboPacks.isNotEmpty && 
            order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
        final hasValidPcs = order.totalPcs > 0;
        final hasValidPrice = order.totalPrice > 0;
        return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
      }).toList();
      
      if (_selectedPaymentMethod != null) {
        orders = orders.where((o) => o.paymentMethod == _selectedPaymentMethod).toList();
      }
      
      if (orders.isEmpty) {
        Fluttertoast.showToast(msg: "No orders to export");
        return;
      }
      
      int codCount = orders.where((o) => o.paymentMethod == 'cod').length;
      int pickupCount = orders.where((o) => o.paymentMethod == 'pickup').length;
      double codRevenue = orders.where((o) => o.paymentMethod == 'cod')
          .fold(0.0, (sum, order) => sum + order.totalPrice);
      double pickupRevenue = orders.where((o) => o.paymentMethod == 'pickup')
          .fold(0.0, (sum, order) => sum + order.totalPrice);
      
      Map<String, int> flavorCount = {};
      for (var order in orders) {
        order.items.forEach((flavor, quantity) {
          flavorCount[flavor] = (flavorCount[flavor] ?? 0) + quantity;
        });
        order.comboPacks.forEach((combo, allocation) {
          allocation.forEach((flavor, quantity) {
            flavorCount[flavor] = (flavorCount[flavor] ?? 0) + quantity;
          });
        });
      }
      
      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Cheez n' Cream Co.",
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Order Analysis Report",
                      style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      "Date: ${dateFormat.format(_selectedDate)}",
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    if (_selectedPaymentMethod != null)
                      pw.Text(
                        "Payment Method: ${_selectedPaymentMethod!.toUpperCase()}",
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    pw.Text(
                      "Generated: ${dateTimeFormat.format(DateTime.now())}",
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              if (_includeSummary) ...[
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text("COD Orders", style: pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text("$codCount", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(PriceCalculator.formatPrice(codRevenue), style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text("Pickup Orders", style: pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text("$pickupCount", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(PriceCalculator.formatPrice(pickupRevenue), style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
              if (_includeFlavorCount && flavorCount.isNotEmpty) ...[
                pw.Text("Flavor Count", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("Flavor", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("Count", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...(() {
                      var sortedEntries = flavorCount.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      return sortedEntries.map((entry) => pw.TableRow(
                        children: [
                          pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(entry.key)),
                          pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("${entry.value} pcs")),
                        ],
                      ));
                    })(),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
              if (_includeOrders) ...[
                pw.Text("Orders", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...orders.take(50).map((order) => pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 8),
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("${order.customerName} - ${order.paymentMethod.toUpperCase()}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("${order.totalPcs} pcs - ${PriceCalculator.formatPrice(order.totalPrice)}"),
                    ],
                  ),
                )),
              ],
            ];
          },
        ),
      );
      
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/order_analysis_${dateFormat.format(_selectedDate)}_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Order Analysis Report');
      
      Fluttertoast.showToast(msg: "PDF exported successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error exporting PDF: $e");
    }
  }

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
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => _showExportFilterDialog(context),
            tooltip: 'Export to PDF',
          ),
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
                    // Summary Cards - only show when "All" is selected
                    if (_selectedPaymentMethod == null) Padding(
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
                    // Flavor Count Section - only show when "All" is selected
                    if (_selectedPaymentMethod == null && flavorCount.isNotEmpty) ...[
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
                            onStatusChanged: null,
                            onDelete: null,
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

