import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../utils/price_calculator.dart';
import '../utils/app_theme.dart';

class ReceiptWidget extends StatelessWidget {
  // Helper function to get product size
  static String _getProductSize(Product product) {
    if (product.size != null && product.size!.isNotEmpty) {
      return product.size!.toLowerCase().trim();
    }
    
    if (product.variant == 'Tiramisu') {
      if ((product.price - 2.0).abs() < 0.01) {
        return 'small';
      } else if ((product.price - 7.0).abs() < 0.01) {
        return 'big';
      }
      return product.price <= 2.0 ? 'small' : 'big';
    } else if (product.variant == 'Cheesekut') {
      if ((product.price - 1.50).abs() < 0.01) {
        return 'small';
      }
      return 'big';
    }
    
    return product.price <= 2.0 ? 'small' : 'big';
  }
  
  // Helper function to find product price from products list
  static double _findProductPrice(String itemName, List<Product>? products) {
    // Try to find from products list first (source of truth)
    if (products == null || products.isEmpty) {
      print('WARNING: Products list is null or empty for item: $itemName');
      // Fallback to hardcoded prices
      double hardcodedPrice = _getItemPrice(itemName);
      return hardcodedPrice > 0.0 ? hardcodedPrice : 0.0;
    }
    
      // Parse format: "ProductName (Variant, Size)" or "ProductName (Variant)"
      String? productName;
      String? variant;
      String? size;
      
      final matchWithSize = RegExp(r'^(.+?)\s*\(\s*([^,]+)\s*,\s*([^)]+)\s*\)$').firstMatch(itemName);
      final matchWithoutSize = RegExp(r'^(.+?)\s*\(\s*([^)]+)\s*\)$').firstMatch(itemName);
      
      if (matchWithSize != null) {
        productName = matchWithSize.group(1)!.trim();
        variant = matchWithSize.group(2)!.trim();
        size = matchWithSize.group(3)!.trim().toLowerCase();
      } else if (matchWithoutSize != null) {
        productName = matchWithoutSize.group(1)!.trim();
        variant = matchWithoutSize.group(2)!.trim();
      }
      
      // Debug: print what we're looking for
      print('Looking for product: name="$productName", variant="$variant", size="$size"');
      print('Available products count: ${products?.length ?? 0}');
      
      if (productName != null && variant != null) {
        // Try to find the product in the products list
        try {
          Product? product;
          // Store variant in non-nullable variable since we've already checked it's not null
          final variantLower = variant!.toLowerCase();
          final productNameLower = productName!.toLowerCase();
          
          if (size != null) {
            final sizeLower = size.toLowerCase();
            // First try exact match with size
            try {
              product = products.firstWhere(
                (p) {
                  final pSize = _getProductSize(p);
                  final match = p.name.toLowerCase() == productNameLower && 
                         p.variant.toLowerCase() == variantLower && 
                         pSize == sizeLower;
                  if (match) {
                    print('Exact match found: ${p.name} (${p.variant}), size: $pSize, price: ${p.price}');
                  }
                  return match;
                },
              );
            } catch (e) {
              // If exact match fails, try to find by name and variant, then filter by expected price for size
              print('Exact match failed for $itemName, trying flexible matching...');
              final matchingProducts = products.where(
                (p) => p.name.toLowerCase() == productNameLower && 
                       p.variant.toLowerCase() == variantLower
              ).toList();
              
              print('Found ${matchingProducts.length} matching products for $productName ($variantLower)');
              for (var p in matchingProducts) {
                print('  - ${p.name} (${p.variant}), size: ${_getProductSize(p)}, price: ${p.price}');
              }
              
              if (matchingProducts.isNotEmpty) {
                // For Cheesekut big, look for price > 1.50 (not small)
                if (variantLower == 'cheesekut' && sizeLower == 'big') {
                  final bigProducts = matchingProducts.where(
                    (p) => (p.price - 1.50).abs() > 0.01 // Not small price
                  ).toList();
                  if (bigProducts.isNotEmpty) {
                    product = bigProducts.first;
                    print('Selected Cheesekut big product: ${product.name}, price: ${product.price}');
                  } else {
                    // If no big product found, try to find by size field
                    final sizeProducts = matchingProducts.where(
                      (p) => p.size?.toLowerCase() == 'big'
                    ).toList();
                    if (sizeProducts.isNotEmpty) {
                      product = sizeProducts.first;
                      print('Selected by size field: ${product.name}, price: ${product.price}');
                    } else {
                      throw Exception('No Cheesekut big product found');
                    }
                  }
                } else if (variantLower == 'cheesekut' && sizeLower == 'small') {
                  product = matchingProducts.firstWhere(
                    (p) => (p.price - 1.50).abs() < 0.01, // Small price
                    orElse: () => matchingProducts.first,
                  );
                } else {
                  // For other variants, use first match
                  product = matchingProducts.first;
                }
              } else {
                throw Exception('No matching products found');
              }
            }
          } else {
            product = products.firstWhere(
              (p) => p.name.toLowerCase() == productNameLower && p.variant.toLowerCase() == variantLower,
              orElse: () => products.firstWhere(
                (p) => p.name.toLowerCase() == productNameLower,
              ),
            );
          }
          print('Found product for $itemName: ${product.name} (${product.variant}), size: ${_getProductSize(product)}, price: ${product.price}');
          return product.price;
        } catch (e) {
          // If product not found, fall back to hardcoded prices
          print('Product not found in list for: $itemName (productName: $productName, variant: $variant, size: $size) - $e');
          print('All available products:');
          for (var p in products) {
            print('  - ${p.name} (variant: ${p.variant}, size: ${p.size ?? "null"}, price: ${p.price})');
          }
        }
      }
    
    // Fallback to hardcoded prices if products list not available or product not found
    double hardcodedPrice = _getItemPrice(itemName);
    if (hardcodedPrice > 0.0) {
      print('Using hardcoded price for $itemName: $hardcodedPrice');
      return hardcodedPrice;
    }
    
    // Last resort: try to find ANY product with matching name (case-insensitive partial match)
    if (products != null && products.isNotEmpty && productName != null) {
      try {
        final productNameLower = productName!.toLowerCase();
        final matchingProducts = products.where(
          (p) => p.name.toLowerCase().contains(productNameLower) || 
                 productNameLower.contains(p.name.toLowerCase())
        ).toList();
        
        if (matchingProducts.isNotEmpty) {
          // For Cheesekut big, prefer products with price > 1.50
          if (variant != null && variant!.toLowerCase() == 'cheesekut' && 
              size != null && size!.toLowerCase() == 'big') {
            final bigProducts = matchingProducts.where(
              (p) => (p.price - 1.50).abs() > 0.01
            ).toList();
            if (bigProducts.isNotEmpty) {
              print('Found Cheesekut big by partial name match: ${bigProducts.first.name}, price: ${bigProducts.first.price}');
              return bigProducts.first.price;
            }
          }
          // Otherwise use first match
          print('Found product by partial name match: ${matchingProducts.first.name}, price: ${matchingProducts.first.price}');
          return matchingProducts.first.price;
        }
      } catch (e) {
        print('Error in partial match fallback: $e');
      }
    }
    
    print('Could not determine price for: $itemName');
    return 0.0;
  }
  // Helper function to calculate price from item name
  static double _getItemPrice(String itemName) {
    try {
      // Simple approach: check if item name contains variant and size keywords
      final itemLower = itemName.toLowerCase();
      
      // Check for Tiramisu
      if (itemLower.contains('tiramisu')) {
        if (itemLower.contains(', small') || itemLower.contains('(tiramisu, small')) {
          return 2.0;
        } else if (itemLower.contains(', big') || itemLower.contains('(tiramisu, big')) {
          return 7.0;
        }
        // Default for Tiramisu without explicit size
        return 2.0;
      }
      
      // Check for Cheesekut
      if (itemLower.contains('cheesekut')) {
        if (itemLower.contains(', small') || itemLower.contains('(cheesekut, small')) {
          return 1.50;
        } else if (itemLower.contains(', big') || itemLower.contains('(cheesekut, big')) {
          // Don't use hardcoded price for Cheesekut big - should come from database
          // Return 0.0 to force product lookup
          return 0.0;
        }
        // Default for Cheesekut without explicit size
        return 1.50;
      }
      
      // Try regex parsing as fallback
      final matchWithSize = RegExp(r'\(([^,]+),\s*([^)]+)\)').firstMatch(itemName);
      if (matchWithSize != null) {
        final variant = matchWithSize.group(1)!.trim().toLowerCase();
        final size = matchWithSize.group(2)!.trim().toLowerCase();
        
        if (variant == 'tiramisu') {
          return size == 'small' ? 2.0 : 7.0;
        } else if (variant == 'cheesekut') {
          return size == 'small' ? 1.50 : 0.0; // Don't use hardcoded for big
        }
      }
      
      // Try format without size
      final matchWithoutSize = RegExp(r'\(([^)]+)\)').firstMatch(itemName);
      if (matchWithoutSize != null) {
        final variant = matchWithoutSize.group(1)!.trim().toLowerCase();
        if (variant == 'tiramisu') {
          return 2.0;
        } else if (variant == 'cheesekut') {
          return 1.50;
        }
      }
      
      print('Could not determine price for item: $itemName');
    } catch (e) {
      print('Error parsing item price for: $itemName - $e');
    }
    
    // Default price if unknown
    return 0.0;
  }
  final Order order;
  final double orderPrice;
  final double codFee;
  final List<Product>? products;

  const ReceiptWidget({
    Key? key,
    required this.order,
    required this.orderPrice,
    required this.codFee,
    this.products,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

            // Content - wrapped in SingleChildScrollView to prevent overflow
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                    SizedBox(height: 8), // Extra padding at bottom to prevent overflow
                  ],
                ),
              ),
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

    // Build list of all items for table with prices
    List<Map<String, dynamic>> allItemsList = [];
    
    order.items.forEach((itemName, quantity) {
      // Parse format: "ProductName (Variant, Size)" or "ProductName (Variant)"
      String displayName = itemName;
      String? size;
      final matchWithSize = RegExp(r'^(.+?)\s*\(([^,]+),\s*([^)]+)\)$').firstMatch(itemName);
      final matchWithoutSize = RegExp(r'^(.+?)\s*\(([^)]+)\)$').firstMatch(itemName);
      
      if (matchWithSize != null) {
        final productName = matchWithSize.group(1)!.trim();
        size = matchWithSize.group(3)!.trim().toLowerCase();
        // Convert size to S/L format: small -> S, big -> L
        String sizeDisplay = '';
        if (size == 'small') {
          sizeDisplay = 'S';
        } else if (size == 'big') {
          sizeDisplay = 'L';
        } else {
          // If size is already S or L, use it as is
          sizeDisplay = size.toUpperCase();
        }
        displayName = '$productName ($sizeDisplay)';
      } else if (matchWithoutSize != null) {
        displayName = matchWithoutSize.group(1)!.trim();
      }
      
      // Get price from products list if available, otherwise use hardcoded prices
      double price = _findProductPrice(itemName, products);
      
      allItemsList.add({
        'name': displayName,
        'quantity': quantity,
        'price': price,
      });
    });
    
    // Create table widget
    if (allItemsList.isNotEmpty) {
      items.add(
        Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey[300]!, width: 1),
              bottom: BorderSide(color: AppTheme.colorDarkBrown, width: 2),
            ),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
            },
            children: [
              // Table rows (no header)
              ...allItemsList.map((item) {
                final name = item['name'] as String;
                final quantity = item['quantity'] as int;
                final price = item['price'] as double;
                final quantityText = '$quantity ${quantity == 1 ? 'pc' : 'pcs'}';
                final priceText = PriceCalculator.formatPrice(price);
                return TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        quantityText,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        priceText,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      );
    }

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

