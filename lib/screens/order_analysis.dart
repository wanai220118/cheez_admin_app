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

class _OrderAnalysisScreenState extends State<OrderAnalysisScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _singleExportDate;
  bool _useDateRange = false;
  bool _useSingleDate = false;
  String? _selectedPaymentMethod;
  bool _includeSummary = true;
  bool _includeFlavorCount = true;
  bool _includeOrders = true;
  bool _includeCustomerDetails = true;
  bool _showFlavorBreakdown = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

  Future<void> _showExportFilterDialog(BuildContext context) async {
    bool tempUseSingleDate = _useSingleDate;
    bool tempUseDateRange = _useDateRange;
    DateTime? tempSingleExportDate = _singleExportDate;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    bool tempIncludeSummary = _includeSummary;
    bool tempIncludeFlavorCount = _includeFlavorCount;
    bool tempIncludeOrders = _includeOrders;
    bool tempIncludeCustomerDetails = _includeCustomerDetails;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: Colors.blue[700]),
                ),
                SizedBox(width: 12),
                Text("Export Options"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection Section
                  Text(
                    "Date Range",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  
                  // Single Date Option
                  Container(
                    decoration: BoxDecoration(
                      color: tempUseSingleDate ? Colors.blue[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tempUseSingleDate ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text("Single Date Export"),
                      subtitle: tempSingleExportDate != null
                          ? Text(DateFormat('MMM dd, yyyy').format(tempSingleExportDate!))
                          : Text("Tap to select date"),
                      value: tempUseSingleDate,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onChanged: (value) {
                        setDialogState(() {
                          tempUseSingleDate = value ?? false;
                          if (tempUseSingleDate) {
                            tempUseDateRange = false;
                            tempStartDate = null;
                            tempEndDate = null;
                          }
                          if (!tempUseSingleDate) {
                            tempSingleExportDate = null;
                          }
                        });
                      },
                      secondary: tempUseSingleDate
                          ? IconButton(
                              icon: Icon(Icons.calendar_today, color: Colors.blue),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: tempSingleExportDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    tempSingleExportDate = picked;
                                  });
                                }
                              },
                            )
                          : null,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Date Range Option
                  Container(
                    decoration: BoxDecoration(
                      color: tempUseDateRange ? Colors.blue[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tempUseDateRange ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text("Date Range Export"),
                      subtitle: tempStartDate != null && tempEndDate != null
                          ? Text("${DateFormat('MMM dd').format(tempStartDate!)} - ${DateFormat('MMM dd, yyyy').format(tempEndDate!)}")
                          : Text("Tap to select range"),
                      value: tempUseDateRange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onChanged: (value) {
                        setDialogState(() {
                          tempUseDateRange = value ?? false;
                          if (tempUseDateRange) {
                            tempUseSingleDate = false;
                            tempSingleExportDate = null;
                          }
                          if (!tempUseDateRange) {
                            tempStartDate = null;
                            tempEndDate = null;
                          }
                        });
                      },
                      secondary: tempUseDateRange
                          ? IconButton(
                              icon: Icon(Icons.date_range, color: Colors.blue),
                              onPressed: () async {
                                final start = await showDatePicker(
                                  context: context,
                                  initialDate: tempStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(Duration(days: 365)),
                                );
                                if (start == null) return;
                                
                                final end = await showDatePicker(
                                  context: context,
                                  initialDate: tempEndDate ?? start,
                                  firstDate: start,
                                  lastDate: DateTime.now().add(Duration(days: 365)),
                                );
                                if (end != null) {
                                  setDialogState(() {
                                    tempStartDate = start;
                                    tempEndDate = end;
                                  });
                                }
                              },
                            )
                          : null,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 12),
                  
                  // Export Content Section
                  Text(
                    "Include in Export",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  
                  _buildOptionTile(
                    "Summary Statistics",
                    "COD & Pickup counts with revenue",
                    Icons.bar_chart,
                    tempIncludeSummary,
                    (value) => setDialogState(() => tempIncludeSummary = value ?? true),
                  ),
                  SizedBox(height: 8),
                  _buildOptionTile(
                    "Flavor Breakdown",
                    "Detailed count by flavor",
                    Icons.pie_chart,
                    tempIncludeFlavorCount,
                    (value) => setDialogState(() => tempIncludeFlavorCount = value ?? true),
                  ),
                  SizedBox(height: 8),
                  _buildOptionTile(
                    "Orders List",
                    "Customer names and items",
                    Icons.receipt_long,
                    tempIncludeOrders,
                    (value) => setDialogState(() => tempIncludeOrders = value ?? true),
                  ),
                  SizedBox(height: 8),
                  _buildOptionTile(
                    "Customer Details",
                    "Full order information",
                    Icons.person,
                    tempIncludeCustomerDetails,
                    (value) => setDialogState(() => tempIncludeCustomerDetails = value ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.file_download),
                label: Text("Export PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (tempUseDateRange && (tempStartDate == null || tempEndDate == null)) {
                    Fluttertoast.showToast(msg: "Please select both start and end dates");
                    return;
                  }
                  if (tempUseSingleDate && tempSingleExportDate == null) {
                    Fluttertoast.showToast(msg: "Please select a date");
                    return;
                  }
                  Navigator.pop(context, {
                    'useDateRange': tempUseDateRange,
                    'useSingleDate': tempUseSingleDate,
                    'startDate': tempStartDate,
                    'endDate': tempEndDate,
                    'singleExportDate': tempSingleExportDate,
                    'includeSummary': tempIncludeSummary,
                    'includeFlavorCount': tempIncludeFlavorCount,
                    'includeOrders': tempIncludeOrders,
                    'includeCustomerDetails': tempIncludeCustomerDetails,
                  });
                },
              ),
            ],
          );
        },
      ),
    );
    
    if (result != null) {
      setState(() {
        _useDateRange = result['useDateRange'] ?? false;
        _useSingleDate = result['useSingleDate'] ?? false;
        _startDate = result['startDate'];
        _endDate = result['endDate'];
        _singleExportDate = result['singleExportDate'];
        _includeSummary = result['includeSummary'] ?? true;
        _includeFlavorCount = result['includeFlavorCount'] ?? true;
        _includeOrders = result['includeOrders'] ?? true;
        _includeCustomerDetails = result['includeCustomerDetails'] ?? true;
      });
      await _exportToPDF(context);
    }
  }

  Widget _buildOptionTile(String title, String subtitle, IconData icon, bool value, Function(bool?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: value ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.blue.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: CheckboxListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: value ? Colors.blue : Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _exportToPDF(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Generating PDF..."),
              ],
            ),
          ),
        ),
      );

      List<Order> allOrders = [];
      
      if (_useSingleDate && _singleExportDate != null) {
        allOrders = await _fs.getOrdersByPickupDate(_singleExportDate!).first;
      } else if (_useDateRange && _startDate != null && _endDate != null) {
        final start = _startDate!;
        final end = _endDate!.add(Duration(days: 1));
        var currentDate = start;
        while (currentDate.isBefore(end)) {
          final dayOrders = await _fs.getOrdersByPickupDate(currentDate).first;
          allOrders.addAll(dayOrders);
          currentDate = currentDate.add(Duration(days: 1));
        }
      } else {
        allOrders = await _fs.getOrdersByPickupDate(_selectedDate).first;
      }
      
      var orders = allOrders.where((order) {
        final hasItems = order.items.isNotEmpty;
        final hasValidPcs = order.totalPcs > 0;
        final hasValidPrice = order.totalPrice > 0;
        return hasItems && hasValidPcs && hasValidPrice;
      }).toList();
      
      if (_selectedPaymentMethod != null) {
        orders = orders.where((o) => o.paymentMethod == _selectedPaymentMethod).toList();
      }
      
      Navigator.pop(context); // Close loading dialog
      
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
      
      // Calculate flavor breakdown grouped by series and size
      final seriesBreakdown = _calculateFlavorBreakdownBySeries(orders);
      
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
                    if (_useSingleDate && _singleExportDate != null)
                      pw.Text(
                        "Date: ${dateFormat.format(_singleExportDate!)}",
                        style: pw.TextStyle(fontSize: 12),
                      )
                    else if (_useDateRange && _startDate != null && _endDate != null)
                      pw.Text(
                        "Date Range: ${dateFormat.format(_startDate!)} to ${dateFormat.format(_endDate!)}",
                        style: pw.TextStyle(fontSize: 12),
                      )
                    else
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
              if (_includeFlavorCount && seriesBreakdown.isNotEmpty) ...[
                pw.Text("Flavor Breakdown by Series", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(1.5),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(2.5),
                    3: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("Series", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("Size", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("Flavor", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text("Quantity", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...(() {
                      var sortedSeries = seriesBreakdown.keys.toList()
                        ..sort((a, b) => a.compareTo(b));
                      
                      List<pw.TableRow> rows = [];
                      for (var series in sortedSeries) {
                        final sizeMap = seriesBreakdown[series]!;
                        
                        // Sort sizes: Small, Big, Combo, then others
                        var sortedSizes = sizeMap.keys.toList()
                          ..sort((a, b) {
                            if (a == 'Small') return -1;
                            if (b == 'Small') return 1;
                            if (a == 'Big') return -1;
                            if (b == 'Big') return 1;
                            if (a == 'Combo') return -1;
                            if (b == 'Combo') return 1;
                            return a.compareTo(b);
                          });
                        
                        for (var size in sortedSizes) {
                          final flavorMap = sizeMap[size]!;
                          
                          // Sort flavors alphabetically
                          var sortedFlavors = flavorMap.keys.toList()..sort();
                          
                          // Create a separate row for each flavor
                          for (var flavor in sortedFlavors) {
                            final quantity = flavorMap[flavor]!;
                            
                            rows.add(
                              pw.TableRow(
                                children: [
                                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(series)),
                                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(size)),
                                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(flavor)),
                                  pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('$quantity pcs')),
                                ],
                              ),
                            );
                          }
                        }
                      }
                      return rows;
                    })(),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
              if (_includeOrders) ...[
                pw.Text("Orders", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                () {
                  final orderList = orders.take(100).toList();
                  final rows = <pw.TableRow>[];
                  final itemColors = [
                    PdfColors.blue700, PdfColors.green700, PdfColors.orange700,
                    PdfColors.purple700, PdfColors.red700, PdfColors.teal700,
                  ];
                  
                  for (int i = 0; i < orderList.length; i += 2) {
                    final order1 = orderList[i];
                    final order2 = i + 1 < orderList.length ? orderList[i + 1] : null;
                    
                    List<pw.Widget> order1Items = [];
                    if (order1.items.isNotEmpty) {
                      int colorIndex = 0;
                      order1.items.forEach((itemName, quantity) {
                        final formattedName = _formatItemName(itemName);
                        order1Items.add(
                          pw.Text(
                            '• $formattedName: $quantity pcs',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: itemColors[colorIndex % itemColors.length],
                            ),
                          ),
                        );
                        colorIndex++;
                      });
                    }
                    // Add combo pack items for order1
                    order1.comboPacks.forEach((comboKey, allocation) {
                      allocation.forEach((flavorName, quantity) {
                        order1Items.add(
                          pw.Text(
                            '• $flavorName (Combo): $quantity pcs',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: itemColors[order1.items.length % itemColors.length],
                            ),
                          ),
                        );
                      });
                    });
                    
                    List<pw.Widget> order2Items = [];
                    if (order2 != null && order2.items.isNotEmpty) {
                      int colorIndex = 0;
                      order2.items.forEach((itemName, quantity) {
                        final formattedName = _formatItemName(itemName);
                        order2Items.add(
                          pw.Text(
                            '• $formattedName: $quantity pcs',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: itemColors[colorIndex % itemColors.length],
                            ),
                          ),
                        );
                        colorIndex++;
                      });
                    }
                    // Add combo pack items for order2
                    if (order2 != null) {
                      order2.comboPacks.forEach((comboKey, allocation) {
                        allocation.forEach((flavorName, quantity) {
                          order2Items.add(
                            pw.Text(
                              '• $flavorName (Combo): $quantity pcs',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: itemColors[order2.items.length % itemColors.length],
                              ),
                            ),
                          );
                        });
                      });
                    }
                    
                    rows.add(
                      pw.TableRow(
                        children: [
                          pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  order1.customerName,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                ...order1Items,
                              ],
                            ),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                            ),
                            child: order2 != null
                                ? pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        order2.customerName,
                                        style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.grey800,
                                        ),
                                      ),
                                      pw.SizedBox(height: 4),
                                      ...order2Items,
                                    ],
                                  )
                                : pw.SizedBox(),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                    columnWidths: {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(1),
                    },
                    children: rows,
                  );
                }(),
              ],
            ];
          },
        ),
      );
      
      final output = await getTemporaryDirectory();
      final fileName = _useSingleDate && _singleExportDate != null
          ? "order_analysis_${dateFormat.format(_singleExportDate!)}_${DateTime.now().millisecondsSinceEpoch}.pdf"
          : _useDateRange && _startDate != null && _endDate != null
              ? "order_analysis_${dateFormat.format(_startDate!)}_to_${dateFormat.format(_endDate!)}_${DateTime.now().millisecondsSinceEpoch}.pdf"
              : "order_analysis_${dateFormat.format(_selectedDate)}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());
      
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Order Analysis Report');
      
      Fluttertoast.showToast(msg: "PDF exported successfully");
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if error
      Fluttertoast.showToast(msg: "Error exporting PDF: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text("Order Analysis"),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: () => _showExportFilterDialog(context),
              tooltip: 'Export to PDF',
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
                assetPath: 'assets/icons/calendar-icon.svg',
                size: 22,
                color: Colors.white,
              ),
              onPressed: () => _selectDate(context),
              tooltip: 'Select Date',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Enhanced Date Display
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
            
            // Payment Method Filter with Modern Chips
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildPaymentChip('All', null, Icons.all_inclusive, Colors.blue),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildPaymentChip('COD', 'cod', Icons.delivery_dining, Colors.orange),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildPaymentChip('Pickup', 'pickup', Icons.store, Colors.green),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1),
            
            Expanded(
              child: StreamBuilder<List<Order>>(
                key: ValueKey('order_analysis_${_selectedDate.millisecondsSinceEpoch}'),
                stream: _fs.getOrdersByPickupDate(_selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.orange),
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
                    final hasValidPcs = order.totalPcs > 0;
                    final hasValidPrice = order.totalPrice > 0;
                    return hasItems && hasValidPcs && hasValidPrice;
                  }).toList();
                  
                  if (_selectedPaymentMethod != null) {
                    orders = orders.where((o) => o.paymentMethod == _selectedPaymentMethod).toList();
                  }
                  
                  int codCount = orders.where((o) => o.paymentMethod == 'cod').length;
                  int pickupCount = orders.where((o) => o.paymentMethod == 'pickup').length;
                  double codRevenue = orders.where((o) => o.paymentMethod == 'cod')
                      .fold(0.0, (sum, order) => sum + order.totalPrice);
                  double pickupRevenue = orders.where((o) => o.paymentMethod == 'pickup')
                      .fold(0.0, (sum, order) => sum + order.totalPrice);
                  
                  // Calculate flavor breakdown grouped by series and size
                  final seriesBreakdown = _calculateFlavorBreakdownBySeries(orders);
                  
                  if (orders.isEmpty) {
                    return EmptyState(
                      message: "No orders scheduled for ${DateFormatter.formatDate(_selectedDate)}${_selectedPaymentMethod != null ? ' (${_selectedPaymentMethod!.toUpperCase()})' : ''}",
                      iconPath: 'assets/icons/orders-icon.svg',
                    );
                  }
                  
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Summary Cards - only show when "All" is selected
                        if (_selectedPaymentMethod == null) ...[
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'COD Orders',
                                    codCount.toString(),
                                    PriceCalculator.formatPrice(codRevenue),
                                    Icons.delivery_dining,
                                    Colors.orange,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Pickup Orders',
                                    pickupCount.toString(),
                                    PriceCalculator.formatPrice(pickupRevenue),
                                    Icons.store,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Flavor Count Section
                          if (seriesBreakdown.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.pie_chart, color: Colors.purple[700], size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "Flavor Breakdown",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _showFlavorBreakdown ? Icons.expand_less : Icons.expand_more,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showFlavorBreakdown = !_showFlavorBreakdown;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_showFlavorBreakdown) ...[
                                    SizedBox(height: 8),
                                    _buildSeriesBreakdownTable(seriesBreakdown),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                        
                        // Orders List Header
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt_long, color: Colors.blue[700], size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Orders (${orders.length})",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Orders List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: orders.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12),
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String label, String? value, IconData icon, Color color) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
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
              size: 24,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, String revenue, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            revenue,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to format item name: "ProductName (Variant, Size)" -> "ProductName (S)" or "ProductName (L)"
  String _formatItemName(String itemName) {
    // Try to parse format: "ProductName (Variant, Size)" or "ProductName (Variant)"
    final matchWithSize = RegExp(r'^(.+?)\s*\((.+?),\s*(.+?)\)$').firstMatch(itemName);
    final matchWithoutSize = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(itemName);
    
    if (matchWithSize != null) {
      // New format with size: extract product name and size
      final productName = matchWithSize.group(1)!.trim();
      final size = matchWithSize.group(3)!.trim();
      // Convert size to S/L format: small -> S, big -> L
      String sizeDisplay = '';
      if (size.toLowerCase() == 'small') {
        sizeDisplay = 'S';
      } else if (size.toLowerCase() == 'big') {
        sizeDisplay = 'L';
      } else {
        // If size is already S or L, use it as is
        sizeDisplay = size.toUpperCase();
      }
      return '$productName ($sizeDisplay)';
    } else if (matchWithoutSize != null) {
      // Old format without size: just return product name
      return matchWithoutSize.group(1)!.trim();
    } else {
      // No parentheses, return as is
      return itemName;
    }
  }

  // Helper function to extract product name and size for flavor breakdown
  // Returns a map with 'name' (formatted as "ProductName (S)") and 'size'
  Map<String, String> _extractProductInfo(String itemName) {
    final matchWithSize = RegExp(r'^(.+?)\s*\((.+?),\s*(.+?)\)$').firstMatch(itemName);
    final matchWithoutSize = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(itemName);
    
    if (matchWithSize != null) {
      final productName = matchWithSize.group(1)!.trim();
      final size = matchWithSize.group(3)!.trim();
      String sizeDisplay = '';
      if (size.toLowerCase() == 'small') {
        sizeDisplay = 'S';
      } else if (size.toLowerCase() == 'big') {
        sizeDisplay = 'L';
      } else {
        sizeDisplay = size.toUpperCase();
      }
      return {
        'name': '$productName ($sizeDisplay)',
        'size': sizeDisplay,
      };
    } else if (matchWithoutSize != null) {
      final productName = matchWithoutSize.group(1)!.trim();
      return {
        'name': productName,
        'size': '',
      };
    } else {
      return {
        'name': itemName,
        'size': '',
      };
    }
  }

  // Helper function to extract series (variant) and size from item name
  // Returns a map with 'series' and 'size'
  Map<String, String> _extractSeriesAndSize(String itemName) {
    final matchWithSize = RegExp(r'^(.+?)\s*\((.+?),\s*(.+?)\)$').firstMatch(itemName);
    final matchWithoutSize = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(itemName);
    
    if (matchWithSize != null) {
      final series = matchWithSize.group(2)!.trim(); // Variant is the series
      final size = matchWithSize.group(3)!.trim();
      String sizeDisplay = '';
      if (size.toLowerCase() == 'small') {
        sizeDisplay = 'Small';
      } else if (size.toLowerCase() == 'big') {
        sizeDisplay = 'Big';
      } else {
        sizeDisplay = size;
      }
      return {
        'series': series,
        'size': sizeDisplay,
      };
    } else if (matchWithoutSize != null) {
      final series = matchWithoutSize.group(2)!.trim();
      return {
        'series': series,
        'size': 'Unknown',
      };
    } else {
      return {
        'series': 'Other',
        'size': 'Unknown',
      };
    }
  }

  // Helper function to extract product name (flavor), series, and size from item name
  // Returns a map with 'flavor', 'series', and 'size'
  Map<String, String> _extractFlavorSeriesAndSize(String itemName) {
    final matchWithSize = RegExp(r'^(.+?)\s*\((.+?),\s*(.+?)\)$').firstMatch(itemName);
    final matchWithoutSize = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(itemName);
    
    if (matchWithSize != null) {
      final flavor = matchWithSize.group(1)!.trim(); // Product name is the flavor
      final series = matchWithSize.group(2)!.trim(); // Variant is the series
      final size = matchWithSize.group(3)!.trim();
      String sizeDisplay = '';
      if (size.toLowerCase() == 'small') {
        sizeDisplay = 'Small';
      } else if (size.toLowerCase() == 'big') {
        sizeDisplay = 'Big';
      } else {
        sizeDisplay = size;
      }
      return {
        'flavor': flavor,
        'series': series,
        'size': sizeDisplay,
      };
    } else if (matchWithoutSize != null) {
      final flavor = matchWithoutSize.group(1)!.trim();
      final series = matchWithoutSize.group(2)!.trim();
      return {
        'flavor': flavor,
        'series': series,
        'size': 'Unknown',
      };
    } else {
      return {
        'flavor': itemName,
        'series': 'Other',
        'size': 'Unknown',
      };
    }
  }

  // Helper function to calculate flavor breakdown grouped by series, size, and flavor
  // Returns Map<series, Map<size, Map<flavor, quantity>>>
  Map<String, Map<String, Map<String, int>>> _calculateFlavorBreakdownBySeries(List<Order> orders) {
    Map<String, Map<String, Map<String, int>>> seriesBreakdown = {};
    
    for (var order in orders) {
      // Process single items
      order.items.forEach((itemName, quantity) {
        final info = _extractFlavorSeriesAndSize(itemName);
        final series = info['series']!;
        final size = info['size']!;
        final flavor = info['flavor']!;
        
        if (!seriesBreakdown.containsKey(series)) {
          seriesBreakdown[series] = {};
        }
        if (!seriesBreakdown[series]!.containsKey(size)) {
          seriesBreakdown[series]![size] = {};
        }
        if (!seriesBreakdown[series]![size]!.containsKey(flavor)) {
          seriesBreakdown[series]![size]![flavor] = 0;
        }
        seriesBreakdown[series]![size]![flavor] = seriesBreakdown[series]![size]![flavor]! + quantity;
      });
      
      // Process combo packs - add to a separate "Combo" size
      order.comboPacks.forEach((comboKey, allocation) {
        allocation.forEach((flavorName, quantity) {
          // For combo packs, we'll add them under the flavor name as a series
          // with size "Combo"
          final series = flavorName;
          final size = 'Combo';
          final flavor = flavorName;
          
          if (!seriesBreakdown.containsKey(series)) {
            seriesBreakdown[series] = {};
          }
          if (!seriesBreakdown[series]!.containsKey(size)) {
            seriesBreakdown[series]![size] = {};
          }
          if (!seriesBreakdown[series]![size]!.containsKey(flavor)) {
            seriesBreakdown[series]![size]![flavor] = 0;
          }
          seriesBreakdown[series]![size]![flavor] = seriesBreakdown[series]![size]![flavor]! + quantity;
        });
      });
    }
    
    return seriesBreakdown;
  }

  // Build widgets for series breakdown display in table format
  Widget _buildSeriesBreakdownTable(Map<String, Map<String, Map<String, int>>> seriesBreakdown) {
    List<TableRow> rows = [];
    
    // Header row
    rows.add(
      TableRow(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 1)),
        ),
        children: [
          _buildTableCell('Series', isHeader: true),
          _buildTableCell('Size', isHeader: true),
          _buildTableCell('Flavor', isHeader: true),
          _buildTableCell('Quantity', isHeader: true),
        ],
      ),
    );
    
    // Sort series alphabetically
    var sortedSeries = seriesBreakdown.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    for (var series in sortedSeries) {
      final sizeMap = seriesBreakdown[series]!;
      
      // Sort sizes: Small, Big, Combo, then others
      var sortedSizes = sizeMap.keys.toList()
        ..sort((a, b) {
          if (a == 'Small') return -1;
          if (b == 'Small') return 1;
          if (a == 'Big') return -1;
          if (b == 'Big') return 1;
          if (a == 'Combo') return -1;
          if (b == 'Combo') return 1;
          return a.compareTo(b);
        });
      
      for (var size in sortedSizes) {
        final flavorMap = sizeMap[size]!;
        
        // Sort flavors alphabetically
        var sortedFlavors = flavorMap.keys.toList()..sort();
        
        // Create a separate row for each flavor
        for (var flavor in sortedFlavors) {
          final quantity = flavorMap[flavor]!;
          
          rows.add(
            TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
              ),
              children: [
                _buildTableCell(series),
                _buildTableCell(size),
                _buildTableCell(flavor),
                _buildTableCell('$quantity pcs'),
              ],
            ),
          );
        }
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Table(
        columnWidths: {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(2.5),
          3: FlexColumnWidth(1),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        children: rows,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 14 : 13,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.grey[800] : Colors.grey[700],
        ),
      ),
    );
  }

  // Helper to get series color
  Color _getSeriesColor(String series) {
    if (series == 'Tiramisu') {
      return Color(0xFF783D2E); // Brown color
    } else if (series == 'Cheesekut') {
      return Color(0xFFF5E6D3); // Cream color
    }
    return Colors.blueGrey[100]!;
  }

  // Helper to get series text color
  Color _getSeriesTextColor(String series) {
    if (series == 'Tiramisu') {
      return Colors.white; // White text on brown background
    } else if (series == 'Cheesekut') {
      return Color(0xFF783D2E); // Brown text on cream background
    }
    return Colors.blueGrey[800]!;
  }
}