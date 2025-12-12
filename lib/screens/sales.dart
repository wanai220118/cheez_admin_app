import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import '../services/firestore_service.dart';
import '../models/order.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../utils/date_formatter.dart';
import '../utils/price_calculator.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatefulWidget {
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final FirestoreService _fs = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'today'; // 'today', 'all'
  bool _includeSummary = true;
  bool _includeTopProducts = true;
  DateTime? _exportStartDate;
  DateTime? _exportEndDate;
  String _exportDateMode = 'current'; // 'current', 'range', 'all'

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

  Future<void> _showExportFilterDialog(BuildContext context) async {
    // Initialize export dates if not set
    if (_exportStartDate == null) {
      _exportStartDate = _selectedDate;
      _exportEndDate = _selectedDate;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Export Options"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Date Range:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  RadioListTile<String>(
                    title: Text("Current Date"),
                    value: 'current',
                    groupValue: _exportDateMode,
                    onChanged: (value) {
                      setState(() {
                        _exportDateMode = value!;
                        _exportStartDate = _selectedDate;
                        _exportEndDate = _selectedDate;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text("Date Range"),
                    value: 'range',
                    groupValue: _exportDateMode,
                    onChanged: (value) {
                      setState(() {
                        _exportDateMode = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text("All Time"),
                    value: 'all',
                    groupValue: _exportDateMode,
                    onChanged: (value) {
                      setState(() {
                        _exportDateMode = value!;
                      });
                    },
                  ),
                  if (_exportDateMode == 'range') ...[
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _exportStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _exportStartDate = picked;
                            if (_exportEndDate != null && _exportEndDate!.isBefore(picked)) {
                              _exportEndDate = picked;
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Start Date",
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _exportStartDate != null
                              ? DateFormat('yyyy-MM-dd').format(_exportStartDate!)
                              : 'Select start date',
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _exportEndDate ?? (_exportStartDate ?? DateTime.now()),
                          firstDate: _exportStartDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _exportEndDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "End Date",
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _exportEndDate != null
                              ? DateFormat('yyyy-MM-dd').format(_exportEndDate!)
                              : 'Select end date',
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 8),
                  Text(
                    "Content:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
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
                    title: Text("Include Top Products"),
                    value: _includeTopProducts,
                    onChanged: (value) {
                      setState(() {
                        _includeTopProducts = value ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_exportDateMode == 'range' && (_exportStartDate == null || _exportEndDate == null)) {
                    Fluttertoast.showToast(msg: "Please select start and end dates");
                    return;
                  }
                  Navigator.pop(context, {
                    'includeSummary': _includeSummary,
                    'includeTopProducts': _includeTopProducts,
                    'dateMode': _exportDateMode,
                    'startDate': _exportStartDate,
                    'endDate': _exportEndDate,
                  });
                },
                child: Text("Export"),
              ),
            ],
          );
        },
      ),
    );
    
    if (result != null) {
      _includeSummary = result['includeSummary'] ?? true;
      _includeTopProducts = result['includeTopProducts'] ?? true;
      _exportDateMode = result['dateMode'] ?? 'current';
      _exportStartDate = result['startDate'];
      _exportEndDate = result['endDate'];
      await _exportToPDF(context);
    }
  }

  Future<void> _exportToPDF(BuildContext context) async {
    try {
      // Get orders data based on export date mode
      List<Order> allOrders = [];
      
      if (_exportDateMode == 'all') {
        allOrders = await _fs.getAllOrders().first;
      } else if (_exportDateMode == 'range' && _exportStartDate != null && _exportEndDate != null) {
        // Get orders for date range
        final startDate = DateTime(_exportStartDate!.year, _exportStartDate!.month, _exportStartDate!.day);
        final endDate = DateTime(_exportEndDate!.year, _exportEndDate!.month, _exportEndDate!.day).add(Duration(days: 1));
        
        // Get all orders and filter by date range
        final allOrdersList = await _fs.getAllOrders().first;
        allOrders = allOrdersList.where((order) {
          final orderDate = DateTime(order.orderDate.year, order.orderDate.month, order.orderDate.day);
          return orderDate.isAfter(startDate.subtract(Duration(days: 1))) && 
                 orderDate.isBefore(endDate);
        }).toList();
      } else {
        // Current date mode
        allOrders = await _fs.getOrdersByDate(_exportStartDate ?? _selectedDate).first;
      }

      // Filter out invalid/deleted orders (orders with no items, zero pieces, or zero price)
      final orders = allOrders.where((order) {
        // Check if order has valid data
        final hasItems = order.items.isNotEmpty;
        final hasComboPacks = order.comboPacks.isNotEmpty && 
            order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
        final hasValidPcs = order.totalPcs > 0;
        final hasValidPrice = order.totalPrice > 0;
        
        // Include order only if it has items/comboPacks AND valid pieces AND valid price
        return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
      }).toList();

      if (orders.isEmpty) {
        Fluttertoast.showToast(msg: "No sales data to export");
        return;
      }

      // Calculate sales data
      double totalSales = 0.0;
      int totalPcs = 0;
      int totalOrders = orders.length;
      Map<String, int> productSales = {};
      Map<String, double> productRevenue = {};

      for (var order in orders) {
        int orderPcs = 0;
        order.items.forEach((itemName, quantity) {
          productSales[itemName] = (productSales[itemName] ?? 0) + quantity;
          orderPcs += quantity;
        });
        order.comboPacks.forEach((_, allocation) {
          allocation.forEach((flavor, quantity) {
            final key = '$flavor (combo)';
            productSales[key] = (productSales[key] ?? 0) + quantity;
            orderPcs += quantity;
          });
        });
        totalPcs += orderPcs;
        totalSales += order.totalPrice;

        if (orderPcs > 0) {
          final pricePerPc = order.totalPrice / orderPcs;
          order.items.forEach((itemName, quantity) {
            productRevenue[itemName] = (productRevenue[itemName] ?? 0.0) + (quantity * pricePerPc);
          });
          order.comboPacks.forEach((_, allocation) {
            allocation.forEach((flavor, quantity) {
              final key = '$flavor (combo)';
              productRevenue[key] = (productRevenue[key] ?? 0.0) + (quantity * pricePerPc);
            });
          });
        }
      }

      final sortedProducts = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Create PDF
      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
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
                      "Sales Report",
                      style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      _exportDateMode == 'all'
                          ? "All Time Report"
                          : _exportDateMode == 'range' && _exportStartDate != null && _exportEndDate != null
                              ? "Date Range: ${dateFormat.format(_exportStartDate!)} to ${dateFormat.format(_exportEndDate!)}"
                              : "Date: ${dateFormat.format(_exportStartDate ?? _selectedDate)}",
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
              
              // Summary Section
              if (_includeSummary) pw.Container(
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
                        pw.Text("Total Sales", style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          PriceCalculator.formatPrice(totalSales),
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text("Total Orders", style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "$totalOrders",
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text("Total Pieces", style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "$totalPcs pcs",
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_includeSummary) pw.SizedBox(height: 20),

              // Top Products Section
              if (_includeTopProducts) pw.Text(
                "Top Selling Products",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              if (_includeTopProducts) pw.SizedBox(height: 10),
              if (_includeTopProducts) pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text("Product", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text("Quantity Sold", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...sortedProducts.take(20).map((entry) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(entry.key),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text("${entry.value} pcs"),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      // Save and share PDF
      final output = await getTemporaryDirectory();
      String fileName;
      if (_exportDateMode == 'all') {
        fileName = 'sales_report_all_time_${DateTime.now().millisecondsSinceEpoch}.pdf';
      } else if (_exportDateMode == 'range' && _exportStartDate != null && _exportEndDate != null) {
        fileName = 'sales_report_${dateFormat.format(_exportStartDate!)}_to_${dateFormat.format(_exportEndDate!)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      } else {
        fileName = 'sales_report_${dateFormat.format(_exportStartDate ?? _selectedDate)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Sales Report');

      Fluttertoast.showToast(msg: "PDF exported successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error exporting PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sales"),
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
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: () => _showExportFilterDialog(context),
              tooltip: 'Export to PDF',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: StreamBuilder<List<Order>>(
              key: ValueKey('sales_${_viewMode}_${_selectedDate.millisecondsSinceEpoch}'),
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
                final allOrders = snapshot.data!;
                
                // Filter out invalid/deleted orders (orders with no items, zero pieces, or zero price)
                final orders = allOrders.where((order) {
                  // Check if order has valid data
                  final hasItems = order.items.isNotEmpty;
                  final hasComboPacks = order.comboPacks.isNotEmpty && 
                      order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
                  final hasValidPcs = order.totalPcs > 0;
                  final hasValidPrice = order.totalPrice > 0;
                  
                  // Include order only if it has items/comboPacks AND valid pieces AND valid price
                  return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
                }).toList();
                
                if (orders.isEmpty) {
                  return EmptyState(
                    message: _viewMode == 'today' 
                        ? "No sales for ${DateFormatter.formatDate(_selectedDate)}"
                        : "No sales recorded",
                    iconPath: 'assets/icons/sales-icon.svg',
                  );
                }
                
                // Calculate sales from orders
                double totalSales = 0.0;
                int totalPcs = 0;
                int totalOrders = orders.length;
                
                // Calculate sales by product
                Map<String, int> productSales = {};
                Map<String, double> productRevenue = {};
                for (var order in orders) {
                  // Recalculate pieces per order
                  int orderPcs = 0;
                  order.items.forEach((itemName, quantity) {
                    productSales[itemName] = (productSales[itemName] ?? 0) + quantity;
                    orderPcs += quantity;
                  });
                  order.comboPacks.forEach((_, allocation) {
                    allocation.forEach((flavor, quantity) {
                      final key = '$flavor (combo)';
                      productSales[key] = (productSales[key] ?? 0) + quantity;
                      orderPcs += quantity;
                    });
                  });
                  
                  totalPcs += orderPcs;
                  // Include COD fee in total sales (order.totalPrice already includes COD fee when order was saved)
                  totalSales += order.totalPrice;
                  
                  // Estimate revenue per product using this order's average price per piece
                  if (orderPcs > 0) {
                    final pricePerPc = order.totalPrice / orderPcs;
                    order.items.forEach((itemName, quantity) {
                      productRevenue[itemName] = (productRevenue[itemName] ?? 0.0) + (quantity * pricePerPc);
                    });
                    order.comboPacks.forEach((_, allocation) {
                      allocation.forEach((flavor, quantity) {
                        final key = '$flavor (combo)';
                        productRevenue[key] = (productRevenue[key] ?? 0.0) + (quantity * pricePerPc);
                      });
                    });
                  }
                }
                
                final sortedProducts = productSales.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                
                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.green[50],
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      "Total Sales",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      PriceCalculator.formatPrice(totalSales),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[900],
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
                              color: Colors.blue[50],
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      "Total Orders",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "$totalOrders",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
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
                              color: Colors.orange[50],
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      "Total Pieces",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "$totalPcs pcs",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      if (sortedProducts.isNotEmpty) ...[
                        Text(
                          "Top Selling Products",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        ...sortedProducts.take(10).map((entry) {
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(entry.key),
                              trailing: Text(
                                "${entry.value} pcs",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
