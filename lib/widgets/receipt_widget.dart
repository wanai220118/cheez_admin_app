import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../utils/price_calculator.dart';
import '../utils/app_theme.dart';

class ReceiptWidget extends StatelessWidget {
  final Order order;
  final double orderPrice;
  final double codFee;

  const ReceiptWidget({
    Key? key,
    required this.order,
    required this.orderPrice,
    required this.codFee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.colorDarkBrown, AppTheme.colorGoldenBrown],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                children: [
                  // Logo and Company Name in same row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/logoresit.png',
                            fit: BoxFit.contain,
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading logo: $error');
                              return Icon(
                                Icons.store,
                                size: 30,
                                color: AppTheme.colorDarkBrown,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHEEZ N\' CREAM CO.',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Resit Pesanan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Details Section
                _buildSection(
                  'Butiran Pesanan',
                  [
                    _buildInfoRow('👤 Pelanggan', order.customerName),
                    if (order.phone.isNotEmpty)
                      _buildInfoRow('📱 Telefon', order.phone),
                    _buildInfoRow('📅 Tarikh', dateFormat.format(order.orderDate)),
                    _buildInfoRow('🕐 Masa', timeFormat.format(order.orderDate)),
                  ],
                ),

                // Pickup Schedule Section
                if (order.pickupDateTime != null) ...[
                  SizedBox(height: 8),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.colorDarkBrown, AppTheme.colorGoldenBrown],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildSection(
                    'Jadual Ambil',
                    [
                      _buildInfoRow('📅 Tarikh', dateFormat.format(order.pickupDateTime!)),
                      _buildInfoRow('🕐 Masa', timeFormat.format(order.pickupDateTime!)),
                    ],
                  ),
                ],

                SizedBox(height: 8),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.colorDarkBrown, AppTheme.colorGoldenBrown],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                SizedBox(height: 8),

                // Order Items Section
                _buildSection(
                  'Item Pesanan',
                  _buildOrderItems(),
                ),

                SizedBox(height: 8),

                // Total Section
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFe8d4b8),
                        Color(0xFFd4c0a4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildTotalRow('Jumlah Pcs:', '${order.totalPcs} pcs'),
                      SizedBox(height: 4),
                      _buildTotalRow('Jumlah:', PriceCalculator.formatPrice(orderPrice)),
                      if (order.paymentMethod == 'cod') ...[
                        SizedBox(height: 4),
                        _buildTotalRow('Cas COD:', PriceCalculator.formatPrice(codFee)),
                      ],
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.colorDarkBrown.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: _buildTotalRow(
                          'JUMLAH:',
                          PriceCalculator.formatPrice(order.totalPrice),
                          isGrandTotal: true,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                // Payment Section
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Maklumat Pembayaran'),
                      SizedBox(height: 6),
                      _buildInfoRow(
                        'Kaedah',
                        order.paymentMethod == 'pickup' ? 'AMBIL' : 'COD',
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.colorGoldenBrown,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.isPaid ? '✅ DIBAYAR' : '⏳ BELUM DITERIMA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      _buildInfoRow(
                        'Saluran',
                        order.paymentChannel == 'qr' ? 'QR' : 'TUNAI',
                      ),
                      if (order.paymentMethod == 'cod' &&
                          order.codAddress != null &&
                          order.codAddress!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        _buildInfoRow('📍 Alamat', order.codAddress!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.colorDarkBrown, AppTheme.colorGoldenBrown],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Text(
              '✨ Terima kasih atas pesanan anda! ✨',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        SizedBox(height: 6),
        ...children,
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.colorDarkBrown,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderItems() {
    List<Widget> items = [];

    // Single items - simple text format
    order.items.forEach((itemName, quantity) {
      items.add(
        Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            '$itemName: $quantity pcs',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      );
    });

    // Combo packs - simple text format
    order.comboPacks.forEach((comboType, allocation) {
      String comboName;
      if (comboType.toLowerCase().contains('small')) {
        comboName = 'Small Combo';
      } else if (comboType.toLowerCase().contains('standard')) {
        comboName = 'Standard Combo';
      } else {
        comboName = comboType.replaceAll('_', ' ').split(' ').map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
      }

      allocation.forEach((flavor, quantity) {
        items.add(
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              '$comboName - $flavor: $quantity pcs',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        );
      });
    });

    return items;
  }

  Widget _buildTotalRow(String label, String value, {bool isGrandTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 13,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
            color: isGrandTotal ? AppTheme.colorDarkBrown : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 13,
            fontWeight: FontWeight.w600,
            color: isGrandTotal ? AppTheme.colorDarkBrown : Colors.black87,
          ),
        ),
      ],
    );
  }
}

