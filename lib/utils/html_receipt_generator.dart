import '../models/order.dart';
import 'price_calculator.dart';
import 'package:intl/intl.dart';

class HtmlReceiptGenerator {
  static String generateHtmlReceipt(Order order, double orderPrice, double codFee) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    // Build order items HTML
    String itemsHtml = '';
    int itemNumber = 1;
    
    // Single items
    if (order.items.isNotEmpty) {
      order.items.forEach((itemName, quantity) {
        itemsHtml += '''
          <div class="item-card">
            <div class="item-name">$itemNumber. $itemName</div>
            <div class="item-detail">• $itemName: $quantity pcs</div>
          </div>
        ''';
        itemNumber++;
      });
    }
    
    // Combo packs
    if (order.comboPacks.isNotEmpty) {
      order.comboPacks.forEach((comboType, allocation) {
        // Format combo name
        String comboName;
        if (comboType.toLowerCase().contains('small')) {
          comboName = 'Small Combo';
        } else if (comboType.toLowerCase().contains('standard')) {
          comboName = 'Standard Combo';
        } else {
          comboName = comboType.replaceAll('_', ' ').split(' ').map((word) => 
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
          ).join(' ');
        }
        
        String comboDetails = '';
        allocation.forEach((flavor, quantity) {
          comboDetails += '<div class="item-detail">• $flavor: $quantity pcs</div>';
        });
        
        itemsHtml += '''
          <div class="item-card">
            <div class="item-name">$itemNumber. $comboName Combo Pack</div>
            $comboDetails
          </div>
        ''';
        itemNumber++;
      });
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
            align-items: center;
            padding: 20px;
        }
        
        .receipt {
            background: white;
            width: 100%;
            max-width: 420px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            animation: slideIn 0.5s ease-out;
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

