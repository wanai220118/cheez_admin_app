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
  String _viewMode = 'today';
  bool _includeSummary = true;
  bool _includeTopProducts = true;
  DateTime? _exportStartDate;
  DateTime? _exportEndDate;
  String _exportDateMode = 'current';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      });
    }
  }

  Future<void> _showExportFilterDialog(BuildContext context) async {
    if (_exportStartDate == null) {
      _exportStartDate = _selectedDate;
      _exportEndDate = _selectedDate;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.file_download_rounded, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Text("Export Options"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Date Range:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
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
                          prefixIcon: Icon(Icons.calendar_today_rounded),
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
                          prefixIcon: Icon(Icons.calendar_today_rounded),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
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
              ElevatedButton.icon(
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
                icon: Icon(Icons.download_rounded),
                label: Text("Export"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
      List<Order> allOrders = [];
      
      if (_exportDateMode == 'all') {
        allOrders = await _fs.getAllOrders().first;
      } else if (_exportDateMode == 'range' && _exportStartDate != null && _exportEndDate != null) {
        final startDate = DateTime(_exportStartDate!.year, _exportStartDate!.month, _exportStartDate!.day);
        final endDate = DateTime(_exportEndDate!.year, _exportEndDate!.month, _exportEndDate!.day).add(Duration(days: 1));
        
        final allOrdersList = await _fs.getAllOrders().first;
        allOrders = allOrdersList.where((order) {
          final orderDate = DateTime(order.orderDate.year, order.orderDate.month, order.orderDate.day);
          return orderDate.isAfter(startDate.subtract(Duration(days: 1))) && 
                 orderDate.isBefore(endDate);
        }).toList();
      } else {
        allOrders = await _fs.getOrdersByDate(_exportStartDate ?? _selectedDate).first;
      }

      final orders = allOrders.where((order) {
        final hasItems = order.items.isNotEmpty;
        final hasComboPacks = order.comboPacks.isNotEmpty && 
            order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
        final hasValidPcs = order.totalPcs > 0;
        final hasValidPrice = order.totalPrice > 0;
        return (hasItems || hasComboPacks) && hasValidPcs && hasValidPrice;
      }).toList();

      if (orders.isEmpty) {
        Fluttertoast.showToast(msg: "No sales data to export");
        return;
      }

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

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Sales Report');

      Fluttertoast.showToast(msg: "PDF exported successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error exporting PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Sales Report"),
        elevation: 0,
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
              icon: Icon(Icons.picture_as_pdf_rounded),
              onPressed: () => _showExportFilterDialog(context),
              tooltip: 'Export to PDF',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Date Display
          if (_viewMode == 'today')
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    Colors.green[50]!,
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
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
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
          
          // Enhanced View Mode Toggle
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentedButton(
                    label: 'Today',
                    isSelected: _viewMode == 'today',
                    onTap: () => setState(() => _viewMode = 'today'),
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildSegmentedButton(
                    label: 'All Time',
                    isSelected: _viewMode == 'all',
                    onTap: () => setState(() => _viewMode = 'all'),
                    color: Colors.teal,
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading sales data...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
                        SizedBox(height: 16),
                        Text('Error loading data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('${snapshot.error}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('No data'));
                }
                
                final allOrders = snapshot.data!;
                final orders = allOrders.where((order) {
                  final hasItems = order.items.isNotEmpty;
                  final hasComboPacks = order.comboPacks.isNotEmpty && 
                      order.comboPacks.values.any((allocation) => allocation.isNotEmpty);
                  final hasValidPcs = order.totalPcs > 0;
                  final hasValidPrice = order.totalPrice > 0;
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
                
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Summary Cards
                      _buildSummaryCard(
                        "Total Sales",
                        PriceCalculator.formatPrice(totalSales),
                        Icons.monetization_on_rounded,
                        Colors.green,
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactSummaryCard(
                              "Orders",
                              "$totalOrders",
                              Icons.receipt_long_rounded,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactSummaryCard(
                              "Pieces",
                              "$totalPcs pcs",
                              Icons.inventory_2_rounded,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Top Products Section
                      if (sortedProducts.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Top Selling Products",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...sortedProducts.take(10).toList().asMap().entries.map((mapEntry) {
                          final index = mapEntry.key;
                          final entry = mapEntry.value;
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: index == 0
                                        ? [Colors.amber[400]!, Colors.amber[600]!]
                                        : index == 1
                                        ? [Colors.grey[400]!, Colors.grey[600]!]
                                        : index == 2
                                        ? [Colors.brown[400]!, Colors.brown[600]!]
                                        : [Colors.blue[400]!, Colors.blue[600]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '#${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${entry.value} pcs",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                  ),
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

  Widget _buildSegmentedButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}