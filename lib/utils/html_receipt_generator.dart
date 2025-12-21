import '../models/order.dart';
import '../models/product.dart';
import 'price_calculator.dart';
import 'package:intl/intl.dart';

class HtmlReceiptGenerator {
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
  
  static String generateHtmlReceipt(Order order, double orderPrice, double codFee, {List<Product>? products}) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    // Build order items HTML grouped by series
    String itemsHtml = '';
    
    // Group items by series
    Map<String, Map<String, int>> tiramisuItems = {};
    Map<String, Map<String, int>> cheesekutItems = {};
    Map<String, Map<String, int>> otherItems = {};
    
    // Build table rows for all items with prices
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
      
      // Debug output
      if (price == 0.0) {
        print('Warning: Price is 0.0 for item: $itemName');
      }
      
      allItemsList.add({
        'name': displayName,
        'quantity': quantity,
        'price': price,
      });
    });
    
    // Generate HTML table
    if (allItemsList.isNotEmpty) {
      itemsHtml += '''
        <table style="width: 100%; border-collapse: collapse; margin-top: 8px;">
          <tbody>
      ''';
      
      allItemsList.forEach((item) {
        final name = item['name'] as String;
        final quantity = item['quantity'] as int;
        final price = item['price'] as double;
        final quantityText = '$quantity ${quantity == 1 ? 'pc' : 'pcs'}';
        final priceText = PriceCalculator.formatPrice(price);
        itemsHtml += '''
            <tr style="border-bottom: 1px solid #e0e0e0;">
              <td style="padding: 8px; color: #333;">$name</td>
              <td style="padding: 8px; text-align: right; color: #333;">$quantityText</td>
              <td style="padding: 8px; text-align: right; color: #333;">$priceText</td>
            </tr>
        ''';
      });
      
      itemsHtml += '''
          </tbody>
        </table>
      ''';
    }
    
    
    // Payment method text
    String paymentMethodText = order.paymentMethod == 'pickup' ? 'AMBIL' : 'COD';
    String paymentStatus = order.isPaid 
        ? '<span class="status-badge">✅ DIBAYAR</span>' 
        : '<span class="status-badge">⏳ BAYARAN BELUM DITERIMA</span>';
    String channelText = order.paymentChannel == 'qr' ? 'QR' : 'TUNAI';
    
    // Pickup schedule section
    String pickupScheduleHtml = '';
    if (order.pickupDateTime != null) {
      pickupScheduleHtml = '''
        <div class="divider"></div>
        
        <div class="section">
          <div class="section-title">Jadual Ambil</div>
          <div class="info-row">
            <span class="info-label">📅 Tarikh</span>
            <span class="info-value">${dateFormat.format(order.pickupDateTime!)}</span>
          </div>
          <div class="info-row">
            <span class="info-label">🕐 Masa</span>
            <span class="info-value">${timeFormat.format(order.pickupDateTime!)}</span>
          </div>
        </div>
      ''';
    }
    
    // COD fee row
    String codFeeRow = '';
    if (order.paymentMethod == 'cod' && codFee > 0) {
      codFeeRow = '''
        <div class="total-row">
          <span>Yuran COD:</span>
          <span style="font-weight: 600;">${PriceCalculator.formatPrice(codFee)}</span>
        </div>
      ''';
    }
    
    // COD address section
    String codAddressHtml = '';
    if (order.paymentMethod == 'cod' && order.codAddress != null && order.codAddress!.isNotEmpty) {
      codAddressHtml = '''
        <div class="info-row">
          <span class="info-label">📍 Alamat</span>
          <span class="info-value">${order.codAddress}</span>
        </div>
      ''';
    }
    
    return '''
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resit Pesanan</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap');
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #783D2E 0%, #B18552 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: flex-start;
            padding: 20px;
            overflow-y: auto;
        }
        
        .receipt {
            background: white;
            width: 100%;
            max-width: 420px;
            max-height: 100vh;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            animation: slideIn 0.5s ease-out;
            display: flex;
            flex-direction: column;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .header {
            background: linear-gradient(135deg, #783D2E 0%, #B18552 100%);
            padding: 30px 20px;
            text-align: center;
            color: white;
            position: relative;
            overflow: hidden;
        }
        
        .header::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
            animation: pulse 3s ease-in-out infinite;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.1); }
        }
        
        .header h1 {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 5px;
            position: relative;
            z-index: 1;
        }
        
        .header .subtitle {
            font-size: 14px;
            font-weight: 300;
            opacity: 0.9;
            position: relative;
            z-index: 1;
        }
        
        .content {
            padding: 30px 25px;
            max-height: calc(100vh - 200px);
            overflow-y: auto;
        }
        
        .section {
            margin-bottom: 25px;
        }
        
        .section-title {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: #783D2E;
            margin-bottom: 12px;
            letter-spacing: 1px;
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px dashed #e0e0e0;
        }
        
        .info-row:last-child {
            border-bottom: none;
        }
        
        .info-label {
            color: #666;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .info-value {
            color: #333;
            font-weight: 600;
            font-size: 14px;
            text-align: right;
        }
        
        .divider {
            height: 2px;
            background: linear-gradient(to right, #783D2E, #B18552);
            margin: 20px 0;
            border-radius: 2px;
        }
        
        .item-card {
            background: linear-gradient(135deg, #f5e6d3 0%, #e8d4b8 100%);
            padding: 15px;
            border-radius: 12px;
            margin-bottom: 15px;
        }
        
        .item-name {
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
            font-size: 15px;
        }
        
        .item-detail {
            color: #666;
            font-size: 13px;
        }
        
        .total-section {
            background: linear-gradient(135deg, #e8d4b8 0%, #d4c0a4 100%);
            padding: 20px;
            border-radius: 12px;
            margin: 20px 0;
        }
        
        .total-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            font-size: 14px;
        }
        
        .total-row:last-child {
            margin-bottom: 0;
        }
        
        .grand-total {
            font-size: 24px;
            font-weight: 700;
            color: #783D2E;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 2px solid rgba(120, 61, 46, 0.3);
        }
        
        .payment-section {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 12px;
            margin-bottom: 20px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 6px 12px;
            background: #B18552;
            color: white;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 5px;
        }
        
        .footer {
            text-align: center;
            padding: 20px;
            background: linear-gradient(135deg, #783D2E 0%, #B18552 100%);
            color: white;
        }
        
        .footer p {
            font-size: 16px;
            font-weight: 600;
        }
        
        .emoji {
            font-size: 18px;
            margin-right: 5px;
        }
        
        @media print {
            body {
                background: white;
            }
            .receipt {
                box-shadow: none;
                max-width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="receipt">
        <div class="header">
            <h1>🍰 CHEEZ N' CREAM CO.</h1>
            <p class="subtitle">Resit Pesanan</p>
        </div>
        
        <div class="content">
            <div class="section">
                <div class="section-title">Butiran Pesanan</div>
                <div class="info-row">
                    <span class="info-label">👤 Pelanggan</span>
                    <span class="info-value">${order.customerName}</span>
                </div>
                ${order.phone.isNotEmpty ? '''
                <div class="info-row">
                    <span class="info-label">📱 Telefon</span>
                    <span class="info-value">${order.phone}</span>
                </div>
                ''' : ''}
                <div class="info-row">
                    <span class="info-label">📅 Tarikh</span>
                    <span class="info-value">${dateFormat.format(order.orderDate)}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">🕐 Masa</span>
                    <span class="info-value">${timeFormat.format(order.orderDate)}</span>
                </div>
            </div>
            
            $pickupScheduleHtml
            
            <div class="divider"></div>
            
            <div class="section">
                <div class="section-title">Item Pesanan</div>
                $itemsHtml
            </div>
            
            <div class="total-section">
                <div class="total-row">
                    <span>Jumlah Pcs:</span>
                    <span style="font-weight: 600;">${order.totalPcs} pcs</span>
                </div>
                <div class="total-row">
                    <span>Jumlah:</span>
                    <span style="font-weight: 600;">${PriceCalculator.formatPrice(orderPrice)}</span>
                </div>
                $codFeeRow
                <div class="total-row grand-total">
                    <span>JUMLAH:</span>
                    <span>${PriceCalculator.formatPrice(order.totalPrice)}</span>
                </div>
            </div>
            
            <div class="payment-section">
                <div class="section-title">Maklumat Pembayaran</div>
                <div class="info-row">
                    <span class="info-label">Kaedah</span>
                    <span class="info-value">$paymentMethodText</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Status</span>
                    <span class="info-value">
                        $paymentStatus
                    </span>
                </div>
                <div class="info-row">
                    <span class="info-label">Saluran</span>
                    <span class="info-value">$channelText</span>
                </div>
                $codAddressHtml
            </div>
        </div>
        
        <div class="footer">
            <p>✨ Terima kasih atas pesanan anda! ✨</p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}

