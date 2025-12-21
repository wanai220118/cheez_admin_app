import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../widgets/custom_textfield.dart';
import '../utils/price_calculator.dart';
import '../utils/receipt_image_generator.dart';
import 'receipt_viewer.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Receipt Preview Screen Widget
class _ReceiptPreviewScreen extends StatefulWidget {
  final String imagePath;
  final String phoneForWhatsApp;

  const _ReceiptPreviewScreen({
    required this.imagePath,
    required this.phoneForWhatsApp,
  });

  @override
  State<_ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<_ReceiptPreviewScreen> {
  bool _isDownloading = false;

  Future<void> _downloadAndOpenWhatsApp() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final imageFile = File(widget.imagePath);
      if (!await imageFile.exists()) {
        Fluttertoast.showToast(
          msg: "Receipt image file not found",
          toastLength: Toast.LENGTH_LONG,
        );
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      Fluttertoast.showToast(msg: "Saving receipt to gallery...");
      
      if (Platform.isAndroid) {
        try {
          const platform = MethodChannel('com.example.cheez_admin_app/gallery');
          final imageBytes = await imageFile.readAsBytes();
          
          final result = await platform.invokeMethod('saveImageToGallery', {
            'imageBytes': imageBytes,
            'fileName': 'Receipt_${DateTime.now().millisecondsSinceEpoch}.png',
          });
          
          if (result == true) {
            Fluttertoast.showToast(
              msg: "Receipt saved to gallery!",
              toastLength: Toast.LENGTH_SHORT,
            );
            
            await Future.delayed(Duration(milliseconds: 500));
            Navigator.of(context).pop();
            await _openWhatsAppChat();
            return;
          }
        } catch (e) {
          print('Error saving via platform channel: $e');
        }
        
        final appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          final downloadsPath = '/storage/emulated/0/Download/CheezReceipts';
          final downloadsDir = Directory(downloadsPath);
          
          if (!await downloadsDir.exists()) {
            try {
              await downloadsDir.create(recursive: true);
            } catch (e) {
              print('Could not create Downloads directory: $e');
              final fileName = "Receipt_${DateTime.now().millisecondsSinceEpoch}.png";
              await imageFile.copy('${appDir.path}/$fileName');
              Fluttertoast.showToast(
                msg: "Receipt saved to app folder",
                toastLength: Toast.LENGTH_SHORT,
              );
            }
          }
          
          if (await downloadsDir.exists()) {
            final fileName = "Receipt_${DateTime.now().millisecondsSinceEpoch}.png";
            final savedFile = File(path.join(downloadsDir.path, fileName));
            await imageFile.copy(savedFile.path);
            
            try {
              const platform = MethodChannel('com.example.cheez_admin_app/gallery');
              await platform.invokeMethod('scanFile', {'path': savedFile.path});
            } catch (e) {
              print('Could not scan file: $e');
            }
            
            Fluttertoast.showToast(
              msg: "Receipt saved to Downloads!",
              toastLength: Toast.LENGTH_SHORT,
            );
          }
        }
      } else if (Platform.isIOS) {
        final appDir = await getApplicationDocumentsDirectory();
        final receiptsDir = Directory(path.join(appDir.path, 'Receipts'));
        
        if (!await receiptsDir.exists()) {
          await receiptsDir.create(recursive: true);
        }
        
        final fileName = "Receipt_${DateTime.now().millisecondsSinceEpoch}.png";
        final savedFile = File(path.join(receiptsDir.path, fileName));
        await imageFile.copy(savedFile.path);
        
        Fluttertoast.showToast(
          msg: "Receipt saved!",
          toastLength: Toast.LENGTH_SHORT,
        );
      }
      
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.of(context).pop();
      await _openWhatsAppChat();
      
      Fluttertoast.showToast(
        msg: "Receipt saved to gallery!",
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      print('Error downloading image: $e');
      Fluttertoast.showToast(
        msg: "Error saving receipt: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _openWhatsAppChat() async {
    try {
      Fluttertoast.showToast(msg: "Opening WhatsApp...");
      final whatsappUrl = 'https://wa.me/${widget.phoneForWhatsApp}';
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Fluttertoast.showToast(
          msg: "WhatsApp opened. Attach the receipt from your gallery.",
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Cannot open WhatsApp. Please check if WhatsApp is installed.",
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      Fluttertoast.showToast(
        msg: "Error opening WhatsApp: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.imagePath);
    
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: Text(
          'Receipt Preview',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Image.file(
            imageFile,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading receipt image',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.brown[700],
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isDownloading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadAndOpenWhatsApp,
                icon: _isDownloading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.download),
                label: Text(_isDownloading ? 'Downloading...' : 'Download & Open WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddOrderScreen extends StatefulWidget {
  final Order? existingOrder;
  
  const AddOrderScreen({Key? key, this.existingOrder}) : super(key: key);
  
  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirestoreService _fs = FirestoreService();
  String? _selectedCustomerId;
  
  Map<String, Map<String, int>> singleItems = {};
  
  List<Product> allProducts = [];
  String selectedSeriesFilter = 'all';
  String selectedSizeFilter = 'all';
  DateTime? orderDate;
  DateTime? pickupDateTime;
  String paymentMethod = 'cod';
  bool isPaid = false;
  String paymentChannel = 'cash';
  final _codAmountController = TextEditingController();
  final _codAddressController = TextEditingController();
  
  final Map<String, String> productImages = {
    'tiramisu': 'assets/images/placeholder.jpg',
    'cheesekut': 'assets/images/placeholder.jpg',
    'oreo cheesekut': 'assets/images/placeholder.jpg',
    'bahumisu': 'assets/images/placeholder.jpg',
  };

  @override
  void initState() {
    super.initState();
    _loadProducts();
    orderDate = DateTime.now();
    
    if (widget.existingOrder != null) {
      final order = widget.existingOrder!;
      _nameController.text = order.customerName;
      _phoneController.text = order.phone;
      orderDate = order.orderDate;
      pickupDateTime = order.pickupDateTime;
      paymentMethod = order.paymentMethod;
      isPaid = order.isPaid;
      paymentChannel = order.paymentChannel;
      if (order.codFee != null) {
        _codAmountController.text = order.codFee!.toStringAsFixed(2);
      }
      if (order.codAddress != null) {
        _codAddressController.text = order.codAddress!;
      }
      
      order.items.forEach((itemName, quantity) {
        // Try to parse format: "ProductName (Variant, Size)" or "ProductName (Variant)"
        final matchWithSize = RegExp(r'^(.+?)\s*\((.+?),\s*(.+?)\)$').firstMatch(itemName);
        final matchWithoutSize = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(itemName);
        
        if (matchWithSize != null) {
          // New format with size: "ProductName (Variant, Size)"
          final productName = matchWithSize.group(1)!.trim();
          final variant = matchWithSize.group(2)!.trim();
          final size = matchWithSize.group(3)!.trim();
          if (!singleItems.containsKey(productName)) {
            singleItems[productName] = {};
          }
          // Use composite key: variant|size
          singleItems[productName]!['$variant|$size'] = quantity;
        } else if (matchWithoutSize != null) {
          // Old format without size: "ProductName (Variant)"
          final productName = matchWithoutSize.group(1)!.trim();
          final variant = matchWithoutSize.group(2)!.trim();
          if (!singleItems.containsKey(productName)) {
            singleItems[productName] = {};
          }
          // For backward compatibility, try to infer size from product
          try {
            final product = allProducts.firstWhere(
              (p) => p.name.toLowerCase() == productName.toLowerCase() && p.variant == variant,
            );
            final size = _getProductSize(product);
            singleItems[productName]!['$variant|$size'] = quantity;
          } catch (e) {
            // Fallback: use variant only (old behavior)
            singleItems[productName]![variant] = quantity;
          }
        }
      });
    }
  }

  void _loadProducts() {
    _fs.getProducts(activeOnly: true).listen((products) {
      setState(() {
        allProducts = products;
        for (var product in products) {
          if (product.variant != 'combo') {
            if (!singleItems.containsKey(product.name)) {
              singleItems[product.name] = {};
            }
            // Use composite key: variant|size to separate small and big
            final size = _getProductSize(product);
            final variantKey = '${product.variant}|$size';
            if (!singleItems[product.name]!.containsKey(variantKey)) {
              singleItems[product.name]![variantKey] = 0;
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _codAmountController.dispose();
    _codAddressController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    double total = 0.0;
    int totalCheesekutPcs = 0;
    Map<String, double> nonCheesekutItems = {};

    singleItems.forEach((productName, variants) {
      variants.forEach((variantKey, quantity) {
        if (quantity > 0) {
          // Parse variantKey: could be "variant|size" or just "variant" (old format)
          String variant;
          String? size;
          if (variantKey.contains('|')) {
            final parts = variantKey.split('|');
            variant = parts[0];
            size = parts.length > 1 ? parts[1] : null;
          } else {
            variant = variantKey;
            size = null;
          }
          
          // Find the matching product
          Product? product;
          try {
            if (size != null) {
              // Try to find product with matching name, variant, and size
              final sizeLower = size!.toLowerCase();
              product = allProducts.firstWhere(
                (p) {
                  final pSize = _getProductSize(p);
                  return p.name.toLowerCase() == productName.toLowerCase() && 
                         p.variant == variant && 
                         pSize == sizeLower;
                },
              );
            } else {
              // Fallback: find by name and variant only
              product = allProducts.firstWhere(
                (p) => p.name.toLowerCase() == productName.toLowerCase() && p.variant == variant,
              );
            }
          } catch (e) {
            // Final fallback: find by name only
            try {
              product = allProducts.firstWhere(
                (p) => p.name.toLowerCase() == productName.toLowerCase(),
              );
            } catch (e) {
              return; // Skip if product not found
            }
          }
          
          final productSize = size ?? _getProductSize(product!);

          if (product.variant == 'Cheesekut' && productSize == 'small' && (product.price - 1.50).abs() < 0.01) {
            totalCheesekutPcs += quantity;
          } else {
            final itemKey = size != null ? '$productName ($variant, $size)' : '$productName ($variant)';
            nonCheesekutItems[itemKey] = (nonCheesekutItems[itemKey] ?? 0) + (quantity * product.price);
          }
        }
      });
    });

    if (totalCheesekutPcs > 0) {
      int bulkPacks = totalCheesekutPcs ~/ 7;
      int remainingPcs = totalCheesekutPcs % 7;
      total += bulkPacks * 10.0;
      total += remainingPcs * 1.50;
    }

    nonCheesekutItems.forEach((itemKey, price) {
      total += price;
    });

    return total;
  }

  int _calculateTotalPcs() {
    int totalPcs = 0;
    singleItems.forEach((productName, variants) {
      variants.forEach((variant, quantity) {
        if (quantity > 0) {
          totalPcs += quantity;
        }
      });
    });
    return totalPcs;
  }

  Future<void> _selectOrderDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: orderDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 30)),
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
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: orderDate != null
            ? TimeOfDay.fromDateTime(orderDate!)
            : TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          orderDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectPickupDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: pickupDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
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
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: pickupDateTime != null
            ? TimeOfDay.fromDateTime(pickupDateTime!)
            : TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          pickupDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatOrderReceipt(Order order, double orderPrice, double codFee) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final buffer = StringBuffer();
    
    buffer.writeln('══════════════════════');
    buffer.writeln('    🍰 *CHEEZ N\' CREAM CO.*');
    buffer.writeln('══════════════════════');
    buffer.writeln('');
    buffer.writeln('📋 *RESIT PESANAN*');
    buffer.writeln('');
    buffer.writeln('*Butiran Pesanan:*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 Pelanggan: *${order.customerName}*');
    if (order.phone.isNotEmpty) {
      buffer.writeln('📱 Telefon: ${order.phone}');
    }
    buffer.writeln('📅 Tarikh: ${dateFormat.format(order.orderDate)}');
    buffer.writeln('🕐 Masa: ${timeFormat.format(order.orderDate)}');
    buffer.writeln('');
    
    if (order.pickupDateTime != null) {
      buffer.writeln('*Jadual Ambil:*');
      buffer.writeln('📅 Tarikh: ${dateFormat.format(order.pickupDateTime!)}');
      buffer.writeln('🕐 Masa: ${timeFormat.format(order.pickupDateTime!)}');
      buffer.writeln('');
    }
    
    buffer.writeln('*Item Pesanan:*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    
    // Collect all items with prices
    List<Map<String, dynamic>> itemsList = [];
    order.items.forEach((itemName, quantity) {
      // Parse format: "ProductName (Variant, Size)" or "ProductName (Variant)"
      String displayName = itemName;
      String? variant;
      String? size;
      double itemPrice = 0.0;
      
      final matchWithSize = RegExp(r'^(.+?)\s*\((.+?),\s*(.+?)\)$').firstMatch(itemName);
      final matchWithoutSize = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(itemName);
      
      if (matchWithSize != null) {
        // New format with size: extract product name, variant, and size
        final productName = matchWithSize.group(1)!.trim();
        variant = matchWithSize.group(2)!.trim();
        size = matchWithSize.group(3)!.trim();
        // Convert size to S/L format: small -> S, big -> L
        String sizeDisplay = '';
        if (size!.toLowerCase() == 'small') {
          sizeDisplay = 'S';
        } else if (size.toLowerCase() == 'big') {
          sizeDisplay = 'L';
        } else {
          // If size is already S or L, use it as is
          sizeDisplay = size.toUpperCase();
        }
        displayName = '$productName ($sizeDisplay)';
      } else if (matchWithoutSize != null) {
        // Old format without size: extract product name and variant
        displayName = matchWithoutSize.group(1)!.trim();
        variant = matchWithoutSize.group(2)!.trim();
      }
      
      // Find the product to get price
      try {
        Product? product;
        if (variant != null && size != null) {
          // Try to find product with matching name, variant, and size
          final sizeLower = size!.toLowerCase();
          product = allProducts.firstWhere(
            (p) {
              final pSize = _getProductSize(p);
              return p.name.toLowerCase() == displayName.toLowerCase() && 
                     p.variant == variant && 
                     pSize == sizeLower;
            },
            orElse: () => allProducts.firstWhere(
              (p) => p.name.toLowerCase() == displayName.toLowerCase() && p.variant == variant,
              orElse: () => allProducts.firstWhere(
                (p) => p.name.toLowerCase() == displayName.toLowerCase(),
              ),
            ),
          );
        } else if (variant != null) {
          product = allProducts.firstWhere(
            (p) => p.name.toLowerCase() == displayName.toLowerCase() && p.variant == variant,
            orElse: () => allProducts.firstWhere(
              (p) => p.name.toLowerCase() == displayName.toLowerCase(),
            ),
          );
        } else {
          product = allProducts.firstWhere(
            (p) => p.name.toLowerCase() == displayName.toLowerCase(),
          );
        }
        itemPrice = product.price;
      } catch (e) {
        // If product not found, use 0.0
        itemPrice = 0.0;
      }
      
      itemsList.add({
        'name': displayName,
        'quantity': quantity,
        'price': itemPrice,
      });
    });
    
    if (itemsList.isNotEmpty) {
      // Find the longest item name for table alignment
      int maxNameLength = itemsList.map((e) => (e['name'] as String).length).reduce((a, b) => a > b ? a : b);
      maxNameLength = maxNameLength > 20 ? maxNameLength : 20; // Minimum width
      
      // Helper function to repeat string
      String repeatString(String str, int times) {
        return List.filled(times, str).join('');
      }
      
      // Add table rows (no header)
      itemsList.forEach((item) {
        final name = item['name'] as String;
        final quantity = item['quantity'] as int;
        final price = item['price'] as double;
        final quantityText = '$quantity ${quantity == 1 ? 'pc' : 'pcs'}';
        final priceText = PriceCalculator.formatPrice(price);
        final namePadding = repeatString(' ', maxNameLength - name.length);
        final quantityPadding = repeatString(' ', 8 - quantityText.length);
        buffer.writeln('$name$namePadding│ $quantityText$quantityPadding│ $priceText');
      });
      buffer.writeln('');
    }
    
    buffer.writeln('*Ringkasan:*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Jumlah Keping: *${order.totalPcs} pcs*');
    buffer.writeln('Jumlah: ${PriceCalculator.formatPrice(orderPrice)}');
    if (paymentMethod == 'cod' && codFee > 0) {
      buffer.writeln('Yuran COD: ${PriceCalculator.formatPrice(codFee)}');
    }
    buffer.writeln('');
    buffer.writeln('*JUMLAH: ${PriceCalculator.formatPrice(order.totalPrice)}*');
    buffer.writeln('');
    
    buffer.writeln('*Maklumat Pembayaran:*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    String paymentMethodText = order.paymentMethod == 'pickup' ? 'AMBIL' : 'COD';
    buffer.writeln('Kaedah: *$paymentMethodText*');
    String paymentStatus = order.isPaid ? '✅ *DIBAYAR*' : '⏳ *BAYARAN BELUM DITERIMA*';
    buffer.writeln('Status: $paymentStatus');
    if (order.paymentChannel.isNotEmpty) {
      String channelText = order.paymentChannel == 'qr' ? 'QR' : 'TUNAI';
      buffer.writeln('Saluran: *$channelText*');
    }
    if (paymentMethod == 'cod' && order.codAddress != null && order.codAddress!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('*Alamat Penghantaran:*');
      buffer.writeln(order.codAddress!);
    }
    buffer.writeln('');
    buffer.writeln('✨ *Terima kasih atas pesanan anda!* ✨');
    buffer.writeln('');
    
    return buffer.toString();
  }

  Future<void> _showReceiptPreview(String imagePath, String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }
      cleanPhone = '+60$cleanPhone';
    }

    String phoneForWhatsApp = cleanPhone.replaceAll('+', '');

    final imageFile = File(imagePath);
    final fileExists = await imageFile.exists();
    
    if (!fileExists) {
      Fluttertoast.showToast(
        msg: "Receipt image file not found",
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ReceiptPreviewScreen(
          imagePath: imagePath,
          phoneForWhatsApp: phoneForWhatsApp,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _sendWhatsAppReceipt(Order order, double orderPrice, double codFee) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    try {
      Fluttertoast.showToast(msg: "Generating receipt image...");
      
      final imagePath = await ReceiptImageGenerator.saveReceiptImage(
        order,
        orderPrice,
        codFee,
        products: allProducts,
      );

      if (imagePath == null) {
        Fluttertoast.showToast(
          msg: "Error generating receipt image",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        Fluttertoast.showToast(
          msg: "Receipt image file not found",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      await Future.delayed(Duration(milliseconds: 300));
      Fluttertoast.showToast(msg: "Receipt image generated successfully!");
      await _showReceiptPreview(imagePath, phone);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error generating receipt: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (pickupDateTime == null) {
      Fluttertoast.showToast(
        msg: "Please select pickup date and time",
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    final totalPcs = _calculateTotalPcs();
    if (totalPcs == 0) {
      Fluttertoast.showToast(
        msg: "Please add at least one item to the order",
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    double codFee = 0.0;
    String? codAddress;
    if (paymentMethod == 'cod') {
      final codAmountText = _codAmountController.text.trim();
      if (codAmountText.isEmpty) {
        codFee = 0.0;
      } else {
        codFee = double.tryParse(codAmountText) ?? 0.0;
        if (codFee < 0) {
          Fluttertoast.showToast(
            msg: "COD amount cannot be negative",
            toastLength: Toast.LENGTH_LONG,
          );
          return;
        }
      }
      codAddress = _codAddressController.text.trim().isNotEmpty
          ? _codAddressController.text.trim()
          : null;
    }

    Map<String, int> orderItems = {};
    singleItems.forEach((productName, variants) {
      variants.forEach((variantKey, quantity) {
        if (quantity > 0) {
          // Check if variantKey includes size (format: "variant|size")
          if (variantKey.contains('|')) {
            final parts = variantKey.split('|');
            final variant = parts[0];
            final size = parts.length > 1 ? parts[1] : '';
            // Save with size: "ProductName (Variant, Size)"
            orderItems['$productName ($variant, $size)'] = quantity;
          } else {
            // Old format without size (backward compatibility)
            orderItems['$productName ($variantKey)'] = quantity;
          }
        }
      });
    });

    final orderPrice = _calculateTotal();
    final order = Order(
      id: widget.existingOrder?.id ?? '',
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      orderDate: orderDate ?? DateTime.now(),
      pickupDateTime: pickupDateTime,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      codFee: codFee > 0 ? codFee : null,
      codAddress: codAddress,
      paymentChannel: paymentChannel,
      items: orderItems,
      comboPacks: {},
      totalPcs: totalPcs,
      totalPrice: orderPrice + (paymentMethod == 'cod' ? codFee : 0.0),
      status: widget.existingOrder?.status ?? 'pending',
    );

    if (widget.existingOrder != null) {
      _fs.updateOrder(order);
      Fluttertoast.showToast(msg: "Order updated successfully");
      Navigator.pop(context, order);
    } else {
      _fs.addOrder(order);
      Fluttertoast.showToast(msg: "Order saved successfully");
      
      // Show dialog to ask if admin wants to view receipt FIRST
      final shouldViewReceipt = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Order Created Successfully',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Text(
              'Would you like to view the receipt?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text(
                  'Yes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
      
      final phone = _phoneController.text.trim();
      
      if (shouldViewReceipt == true) {
        // User chose "Yes" - generate receipt, show preview, and redirect to WhatsApp
        if (phone.isNotEmpty) {
          // Generate receipt and show preview with WhatsApp redirect
          await _sendWhatsAppReceipt(order, orderPrice, codFee);
        } else {
          // No phone number, just show receipt viewer
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptViewerScreen(
                order: order,
                orderPrice: orderPrice,
                codFee: codFee,
              ),
            ),
          );
        }
        // After WhatsApp flow, go back to previous screen
        Navigator.pop(context, order);
      } else {
        // User chose "Skip" - send WhatsApp in background if phone exists, then go back
        if (phone.isNotEmpty) {
          // Send WhatsApp receipt in background (don't await to avoid blocking)
          _sendWhatsAppReceipt(order, orderPrice, codFee);
        }
        // Just go back
        Navigator.pop(context, order);
      }
    }
  }

  Future<void> _showAddCustomerDialog(BuildContext context, List<Customer> existingCustomers) async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Customer?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 12),
            Text("Add New Customer"),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: "Name",
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                CustomTextField(
                  controller: contactController,
                  label: "Contact Number",
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                CustomTextField(
                  controller: addressController,
                  label: "Address",
                  prefixIcon: Icons.location_on,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final customer = Customer(
                  id: '',
                  name: nameController.text.trim(),
                  contactNo: contactController.text.trim(),
                  address: addressController.text.trim(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                Navigator.pop(context, customer);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text("Add"),
          ),
        ],
      ),
    );

    if (result != null) {
      await _fs.addCustomer(result);
      Fluttertoast.showToast(msg: "Customer added successfully");
      
      setState(() {
        _nameController.text = result.name;
        _phoneController.text = result.contactNo;
        _codAddressController.text = result.address;
      });
      
      await Future.delayed(Duration(milliseconds: 300));
      
      try {
        final customers = await _fs.getAllCustomers().first;
        final newCustomer = customers.firstWhere(
          (c) => c.name == result.name && c.contactNo == result.contactNo,
        );
        
        setState(() {
          _selectedCustomerId = newCustomer.id;
        });
      } catch (e) {
        // Form fields already populated
      }
    }

    nameController.dispose();
    contactController.dispose();
    addressController.dispose();
  }

  // Helper function to determine product size consistently
  String _getProductSize(Product product) {
    // Always use size field if available
    if (product.size != null && product.size!.isNotEmpty) {
      return product.size!.toLowerCase().trim();
    }
    
    // Infer size from price based on variant
    if (product.variant == 'Tiramisu') {
      // Tiramisu: small is RM 2.0, big is RM 7.0
      if ((product.price - 2.0).abs() < 0.01) {
        return 'small';
      } else if ((product.price - 7.0).abs() < 0.01) {
        return 'big';
      } else {
        // Fallback for any other price
        return product.price <= 2.0 ? 'small' : 'big';
      }
    } else if (product.variant == 'Cheesekut') {
      // Cheesekut: small is RM 1.50, big is typically > 2.0
      if ((product.price - 1.50).abs() < 0.01) {
        return 'small';
      } else {
        return 'big';
      }
    } else {
      // Default: use price threshold
      return product.price <= 2.0 ? 'small' : 'big';
    }
  }

  Widget _buildProductCardFromProduct(Product product, int quantity, Function(int) onQuantityChanged) {
    // Use the product directly - no need to search
    return _buildProductCard(product.name, product.variant, product, quantity, onQuantityChanged);
  }

  Widget _buildProductCard(String productName, String variant, Product product, int quantity, Function(int) onQuantityChanged) {
    // Product is already provided, use it directly
    double displayPrice = product.price;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: quantity > 0 ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: quantity > 0 
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
          : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image with badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: product.imageUrl != null && !product.imageUrl!.startsWith('assets/')
                        ? Image.file(
                            File(product.imageUrl!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.image_not_supported, color: Colors.grey);
                            },
                          )
                        : Image.asset(
                            product.imageUrl ?? productImages[productName.toLowerCase()] ?? 'assets/images/placeholder.jpg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.image_not_supported, color: Colors.grey);
                            },
                          ),
                  ),
                ),
                if (quantity > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: variant == 'Tiramisu' ? Colors.brown[100] : Colors.yellow[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      variant,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: variant == 'Tiramisu' ? Colors.brown[800] : Colors.orange[900],
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    PriceCalculator.formatPrice(displayPrice),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity Controls - Compact design
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onQuantityChanged(quantity + 1);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.add, size: 20, color: Colors.green[700]),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: quantity > 0
                          ? () {
                              onQuantityChanged(quantity - 1);
                              setState(() {});
                            }
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.remove,
                          size: 20,
                          color: quantity > 0 ? Colors.red[700] : Colors.grey[400],
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final orderPrice = _calculateTotal();
    final codFeeForDisplay = paymentMethod == 'cod' 
        ? (double.tryParse(_codAmountController.text.trim()) ?? 0.0) 
        : 0.0;
    final totalPrice = orderPrice + codFeeForDisplay;
    final totalPcs = _calculateTotalPcs();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.existingOrder != null ? "Edit Order" : "New Order"),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Section Header
                    _buildSectionHeader(
                      icon: Icons.person_rounded,
                      title: "Customer Details",
                      color: Colors.blue,
                    ),
                    SizedBox(height: 12),
                    
                    // Customer Selection
                    StreamBuilder<List<Customer>>(
                      stream: _fs.getAllCustomers(),
                      builder: (context, snapshot) {
                        List<Customer> customers = snapshot.data ?? [];
                        
                        String? validCustomerId = _selectedCustomerId;
                        if (validCustomerId != null && !customers.any((c) => c.id == validCustomerId)) {
                          validCustomerId = null;
                        }
                        
                        return Container(
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
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  value: validCustomerId,
                                  decoration: InputDecoration(
                                    labelText: "Select Customer",
                                    prefixIcon: Icon(Icons.people_rounded, color: Colors.blue),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text("-- Select or add new --"),
                                    ),
                                    ...customers.map((customer) => DropdownMenuItem<String?>(
                                      value: customer.id,
                                      child: Text(customer.name),
                                    )),
                                  ],
                                  onChanged: (String? customerId) {
                                    setState(() {
                                      _selectedCustomerId = customerId;
                                      if (customerId != null) {
                                        final customer = customers.firstWhere((c) => c.id == customerId);
                                        _nameController.text = customer.name;
                                        _phoneController.text = customer.contactNo;
                                        _codAddressController.text = customer.address;
                                      } else {
                                        _nameController.clear();
                                        _phoneController.clear();
                                        _codAddressController.clear();
                                      }
                                    });
                                  },
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(right: 8, left: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.add_rounded, color: Colors.white),
                                  tooltip: 'Add New Customer',
                                  onPressed: () => _showAddCustomerDialog(context, customers),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Customer Info Fields
                    CustomTextField(
                      controller: _nameController,
                      label: "Customer Name",
                      prefixIcon: Icons.person_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    CustomTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 24),
                    
                    // Order Details Header
                    _buildSectionHeader(
                      icon: Icons.event_note_rounded,
                      title: "Order Details",
                      color: Colors.orange,
                    ),
                    SizedBox(height: 12),
                    
                    // Date/Time pickers in a card
                    Container(
                      padding: EdgeInsets.all(16),
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
                      child: Column(
                        children: [
                          // Order Date & Time
                          InkWell(
                            onTap: () => _selectOrderDate(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.event_rounded, color: Colors.orange[700]),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Order Date & Time",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          orderDate != null
                                              ? DateFormat('dd MMM yyyy, hh:mm a').format(orderDate!)
                                              : 'Tap to select',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: orderDate != null ? Colors.black87 : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          // Pickup DateTime
                          InkWell(
                            onTap: () => _selectPickupDateTime(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: pickupDateTime == null ? Colors.red[300]! : Colors.grey[300]!,
                                  width: pickupDateTime == null ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: pickupDateTime == null ? Colors.red[50] : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: pickupDateTime == null ? Colors.red[700] : Colors.green[700],
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "Pickup Date & Time",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            if (pickupDateTime == null) ...[
                                              SizedBox(width: 4),
                                              Text(
                                                "*Required",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.red[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          pickupDateTime != null
                                              ? DateFormat('dd MMM yyyy, hh:mm a').format(pickupDateTime!)
                                              : 'Tap to select pickup time',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: pickupDateTime != null ? Colors.black87 : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Payment Section
                    _buildSectionHeader(
                      icon: Icons.payment_rounded,
                      title: "Payment Details",
                      color: Colors.green,
                    ),
                    SizedBox(height: 12),
                    
                    Container(
                      padding: EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Payment Method",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentMethodChip(
                                  label: 'COD',
                                  icon: Icons.delivery_dining_rounded,
                                  selected: paymentMethod == 'cod',
                                  onTap: () => setState(() => paymentMethod = 'cod'),
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildPaymentMethodChip(
                                  label: 'Pickup',
                                  icon: Icons.store_rounded,
                                  selected: paymentMethod == 'pickup',
                                  onTap: () => setState(() => paymentMethod = 'pickup'),
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Payment Status Row
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isPaid,
                                      onChanged: (value) => setState(() => isPaid = value ?? false),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Text(
                                      'Payment Received',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Payment Channel",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentChannelChip(
                                  label: 'Cash',
                                  icon: Icons.money_rounded,
                                  selected: paymentChannel == 'cash',
                                  onTap: () => setState(() => paymentChannel = 'cash'),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildPaymentChannelChip(
                                  label: 'QR Code',
                                  icon: Icons.qr_code_rounded,
                                  selected: paymentChannel == 'qr',
                                  onTap: () => setState(() => paymentChannel = 'qr'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // COD Details
                    if (paymentMethod == 'cod') ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.delivery_dining_rounded, color: Colors.blue[700], size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "COD Details",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            CustomTextField(
                              controller: _codAmountController,
                              label: "Delivery Fee (RM)",
                              prefixIcon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                            SizedBox(height: 12),
                            CustomTextField(
                              controller: _codAddressController,
                              label: "Delivery Address",
                              prefixIcon: Icons.location_on_rounded,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 24),
                    
                    // Products Section
                    _buildSectionHeader(
                      icon: Icons.shopping_basket_rounded,
                      title: "Select Products",
                      color: Colors.purple,
                    ),
                    SizedBox(height: 12),
                    
                    // Filters in a compact card
                    Container(
                      padding: EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Series",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                DropdownButton<String>(
                                  value: selectedSeriesFilter,
                                  isExpanded: true,
                                  underline: SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'all', child: Text('All')),
                                    DropdownMenuItem(value: 'Tiramisu', child: Text('Tiramisu')),
                                    DropdownMenuItem(value: 'Cheesekut', child: Text('Cheesekut')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSeriesFilter = value ?? 'all';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Size",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                DropdownButton<String>(
                                  value: selectedSizeFilter,
                                  isExpanded: true,
                                  underline: SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'all', child: Text('All')),
                                    DropdownMenuItem(value: 'small', child: Text('Small')),
                                    DropdownMenuItem(value: 'big', child: Text('Big')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSizeFilter = value ?? 'all';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Product List - Filter and display products
                    ...() {
                      // Map to track unique products by name+variant+size
                      Map<String, Product> uniqueProducts = {};
                      
                      for (var product in allProducts) {
                        // Skip combo products
                        if (product.variant == 'combo') continue;
                        
                        // Filter by series
                        if (selectedSeriesFilter != 'all' && product.variant != selectedSeriesFilter) {
                          continue;
                        }
                        
                        // Determine product size using consistent helper function
                        final productSize = _getProductSize(product);
                        
                        // Apply size filter - must match exactly
                        if (selectedSizeFilter != 'all') {
                          final filterSize = selectedSizeFilter.toLowerCase().trim();
                          if (productSize != filterSize) {
                            continue; // Skip products that don't match the size filter
                          }
                        }
                        
                        // Create unique key: name+variant+size+price
                        // Include price to ensure products with same name+variant+size but different prices are shown separately
                        // This prevents losing products due to incorrect deduplication
                        final uniqueKey = '${product.name.toLowerCase().trim()}_${product.variant.toLowerCase().trim()}_${productSize}_${product.price.toStringAsFixed(2)}';
                        
                        // Only keep one product per unique combination
                        // Prefer products with size field set over inferred ones
                        if (!uniqueProducts.containsKey(uniqueKey)) {
                          uniqueProducts[uniqueKey] = product;
                        } else {
                          final existingProduct = uniqueProducts[uniqueKey]!;
                          // Replace if current has size field and existing doesn't
                          if (product.size != null && product.size!.isNotEmpty && 
                              (existingProduct.size == null || existingProduct.size!.isEmpty)) {
                            uniqueProducts[uniqueKey] = product;
                          }
                          // If both have size fields or both don't, keep the existing one
                          // (This prevents duplicates while preserving products)
                        }
                      }
                      
                      // Sort products: first by name, then by size (small before big)
                      final sortedProducts = uniqueProducts.values.toList()
                        ..sort((a, b) {
                          // First sort by name
                          final nameCompare = a.name.compareTo(b.name);
                          if (nameCompare != 0) return nameCompare;
                          
                          // Then sort by size (small before big)
                          final sizeA = _getProductSize(a);
                          final sizeB = _getProductSize(b);
                          
                          if (sizeA == 'small' && sizeB == 'big') return -1;
                          if (sizeA == 'big' && sizeB == 'small') return 1;
                          return 0;
                        });
                      
                      return sortedProducts.map((product) {
                        final productName = product.name;
                        if (!singleItems.containsKey(productName)) {
                          singleItems[productName] = {};
                        }
                        final currentVariant = product.variant;
                        final productSize = _getProductSize(product);
                        // Use composite key: variant|size to separate small and big
                        final variantKey = '$currentVariant|$productSize';
                        if (!singleItems[productName]!.containsKey(variantKey)) {
                          singleItems[productName]![variantKey] = 0;
                        }
                        final currentQuantity = singleItems[productName]![variantKey] ?? 0;
                        
                        // Pass the actual product object to ensure correct matching
                        return _buildProductCardFromProduct(
                          product,
                          currentQuantity,
                          (newQuantity) {
                            singleItems[productName]![variantKey] = newQuantity;
                          },
                        );
                      }).toList();
                    }(),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // Enhanced Summary Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Summary Row
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[50]!, Colors.orange[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_bag_rounded, size: 20, color: Colors.orange[800]),
                                    SizedBox(width: 8),
                                    Text(
                                      "Total Items:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "$totalPcs pcs",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Order Total:",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  PriceCalculator.formatPrice(orderPrice),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            if (paymentMethod == 'cod' && codFeeForDisplay > 0) ...[
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Delivery Fee:",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    PriceCalculator.formatPrice(codFeeForDisplay),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.cancel_outlined),
                              label: Text("Cancel"),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _saveOrder,
                              icon: Icon(Icons.check_circle_outline),
                              label: Text(widget.existingOrder != null ? "Update Order" : "Create Order"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? color : Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey[700],
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChannelChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.green.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.green : Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.green : Colors.grey[700],
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}