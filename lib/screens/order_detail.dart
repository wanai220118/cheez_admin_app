import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';
import '../utils/date_formatter.dart';
import '../utils/price_calculator.dart';
import '../widgets/flavor_count_tile.dart';
import 'receipt_viewer.dart';
import 'add_order.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final FirestoreService _fs = FirestoreService();
  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _editOrderItems(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrderScreen(existingOrder: _order),
      ),
    );
    
    if (result != null && result is Order) {
      setState(() {
        _order = result;
      });
    }
  }

  Future<void> _editPickupDateTime() async {
    final DateTime initialDate = _order.pickupDateTime ?? _order.orderDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (pickedDate == null) return;

    final TimeOfDay initialTime =
        _order.pickupDateTime != null ? TimeOfDay.fromDateTime(_order.pickupDateTime!) : TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null) return;

    final updatedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _order = Order(
        id: _order.id,
        customerName: _order.customerName,
        phone: _order.phone,
        orderDate: _order.orderDate,
        pickupDateTime: updatedDateTime,
        paymentMethod: _order.paymentMethod,
        isPaid: _order.isPaid,
        codFee: _order.codFee,
        codAddress: _order.codAddress,
        paymentChannel: _order.paymentChannel,
        items: _order.items,
        comboPacks: _order.comboPacks,
        bundlePackages: _order.bundlePackages,
        totalPcs: _order.totalPcs,
        totalPrice: _order.totalPrice,
        status: _order.status,
      );
    });

    await _fs.updateOrder(_order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Details"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Edit Order Items',
            onPressed: () => _editOrderItems(context),
          ),
          IconButton(
            icon: Icon(Icons.receipt),
            tooltip: 'View Receipt',
            onPressed: () {
              // Calculate order price (without COD fee)
              final orderPrice = _order.totalPrice - (_order.codFee ?? 0.0);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptViewerScreen(
                    order: _order,
                    orderPrice: orderPrice,
                    codFee: _order.codFee ?? 0.0,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.edit_calendar),
            tooltip: 'Edit Pickup/COD DateTime',
            onPressed: _editPickupDateTime,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Customer Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(Icons.person, "Name", _order.customerName),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.phone, "Phone", _order.phone),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.calendar_today,
                      "Order Date",
                      DateFormatter.formatDateTime(_order.orderDate),
                    ),
                    if (_order.pickupDateTime != null) ...[
                      SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.access_time,
                        _order.paymentMethod == 'cod' ? "COD DateTime" : "Pickup DateTime",
                        DateFormat('yyyy-MM-dd HH:mm').format(_order.pickupDateTime!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Order Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _order.status == 'completed'
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _order.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _order.status == 'completed'
                              ? Colors.green[900]
                              : Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Payment Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.payment,
                      "Method",
                      _order.paymentMethod.toUpperCase(),
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.account_balance_wallet,
                      "Channel",
                      _order.paymentChannel.toUpperCase(),
                    ),
                    SizedBox(height: 8),
                    if (_order.status != 'completed')
                      _buildEditablePaymentRow()
                    else
                      _buildInfoRow(
                        Icons.check_circle,
                        "Paid",
                        _order.isPaid ? "YES" : "NO",
                      ),
                    if (_order.status != 'completed') ...[
                      SizedBox(height: 8),
                      _buildEditablePaymentChannelRow(),
                    ],
                    if (_order.codFee != null) ...[
                      SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.delivery_dining,
                        "COD Fee",
                        PriceCalculator.formatPrice(_order.codFee ?? 0),
                      ),
                    ],
                    if (_order.codAddress != null && _order.codAddress!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on,
                        "COD Address",
                        _order.codAddress!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Order Items (real product names and quantities; bundles expanded)
            if (_order.displayItems.isNotEmpty) ...[
              Text(
                "Order Items",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Card(
                child: Column(
                  children: _order.displayItems.entries
                      .where((e) => e.value > 0)
                      .map((entry) => FlavorCountTile(
                            flavor: entry.key,
                            count: entry.value,
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: 16),
            ],


            // Summary Card
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow("Total Pieces", "${_order.displayTotalPcs} pcs"),
                    Divider(),
                    _buildSummaryRow(
                      "Total Price",
                      PriceCalculator.formatPrice(_order.totalPrice),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Text(
          "$label: ",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditablePaymentRow() {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Text(
          "Paid: ",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Checkbox(
                value: _order.isPaid,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _order = Order(
                        id: _order.id,
                        customerName: _order.customerName,
                        phone: _order.phone,
                        orderDate: _order.orderDate,
                        pickupDateTime: _order.pickupDateTime,
                        paymentMethod: _order.paymentMethod,
                        isPaid: value,
                        codFee: _order.codFee,
                        codAddress: _order.codAddress,
                        paymentChannel: _order.paymentChannel,
                        items: _order.items,
                        comboPacks: _order.comboPacks,
                        bundlePackages: _order.bundlePackages,
                        totalPcs: _order.totalPcs,
                        totalPrice: _order.totalPrice,
                        status: _order.status,
                      );
                    });
                    await _fs.updateOrder(_order);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditablePaymentChannelRow() {
    return Row(
      children: [
        Icon(Icons.account_balance_wallet, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Text(
          "Payment Type: ",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: _order.paymentChannel,
                items: [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Text('Cash'),
                  ),
                  DropdownMenuItem(
                    value: 'qr',
                    child: Text('QR'),
                  ),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _order = Order(
                        id: _order.id,
                        customerName: _order.customerName,
                        phone: _order.phone,
                        orderDate: _order.orderDate,
                        pickupDateTime: _order.pickupDateTime,
                        paymentMethod: _order.paymentMethod,
                        isPaid: _order.isPaid,
                        codFee: _order.codFee,
                        codAddress: _order.codAddress,
                        paymentChannel: value,
                        items: _order.items,
                        comboPacks: _order.comboPacks,
                        bundlePackages: _order.bundlePackages,
                        totalPcs: _order.totalPcs,
                        totalPrice: _order.totalPrice,
                        status: _order.status,
                      );
                    });
                    await _fs.updateOrder(_order);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
