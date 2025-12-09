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
      // Read the image file
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
        // For Android, use platform channel to save directly to gallery via MediaStore
        try {
          const platform = MethodChannel('com.example.cheez_admin_app/gallery');
          final imageBytes = await imageFile.readAsBytes();
          
          // Save via platform channel which handles MediaStore
          final result = await platform.invokeMethod('saveImageToGallery', {
            'imageBytes': imageBytes,
            'fileName': 'Receipt_${DateTime.now().millisecondsSinceEpoch}.png',
          });
          
          if (result == true) {
            Fluttertoast.showToast(
              msg: "Receipt saved to gallery!",
              toastLength: Toast.LENGTH_SHORT,
            );
            
            // Wait a moment for toast to show
            await Future.delayed(Duration(milliseconds: 500));
            
            // Close the preview screen
            Navigator.of(context).pop();
            
            // Open WhatsApp chat
            await _openWhatsAppChat();
            return;
          }
        } catch (e) {
          print('Error saving via platform channel: $e');
          // Fall through to fallback method
        }
        
        // Fallback: Save to Downloads folder
        final appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          // Try to save to Downloads
          final downloadsPath = '/storage/emulated/0/Download/CheezReceipts';
          final downloadsDir = Directory(downloadsPath);
          
          if (!await downloadsDir.exists()) {
            try {
              await downloadsDir.create(recursive: true);
            } catch (e) {
              print('Could not create Downloads directory: $e');
              // Use app directory as fallback
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
            
            // Scan file to make it visible
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
        // For iOS, use application documents directory
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
      
      // Wait a moment for toast to show
      await Future.delayed(Duration(milliseconds: 500));
      
      // Close the preview screen
      Navigator.of(context).pop();
      
      // Open WhatsApp chat
      await _openWhatsAppChat();
      
      Fluttertoast.showToast(
        msg: "Receipt saved to gallery!",
        toastLength: Toast.LENGTH_SHORT,
      );
      
      // Wait a moment for toast to show
      await Future.delayed(Duration(milliseconds: 500));
      
      // Close the preview screen
      Navigator.of(context).pop();
      
      // Open WhatsApp chat
      await _openWhatsAppChat();
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
    print('_ReceiptPreviewScreen build called with path: ${widget.imagePath}');
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
              print('Image.file error: $error');
              print('Image path: ${widget.imagePath}');
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
                    SizedBox(height: 8),
                    Text(
                      'Path: ${widget.imagePath}',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                print('Image loaded synchronously');
                return child;
              }
              if (frame != null) {
                print('Image frame loaded');
                return child;
              }
              print('Image loading...');
              return Container(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
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
  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirestoreService _fs = FirestoreService();
  String? _selectedCustomerId;
  
  // Product selections
  Map<String, Map<String, int>> singleItems = {}; // productName -> {variant: quantity}
  Map<String, Map<String, int>> comboItems = {}; // comboType -> {flavor: quantity}
  
  List<Product> allProducts = [];
  String selectedComboType = 'small'; // 'small' or 'standard'
  String selectedVariantFilter = 'small'; // 'all', 'small', or 'normal' for filtering menu items
  DateTime? pickupDateTime;
  String paymentMethod = 'cod'; // 'cod' or 'pickup'
  bool isPaid = false;
  String paymentChannel = 'cash'; // 'cash' or 'qr'
  final _codAmountController = TextEditingController();
  final _codAddressController = TextEditingController();
  
  // Available flavors for combos
  final List<String> smallComboFlavors = ['tiramisu', 'cheesekut', 'oreo cheesekut'];
  final List<String> standardComboFlavors = ['tiramisu', 'cheesekut', 'oreo cheesekut', 'bahumisu'];
  
  // Product images mapping
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
  }

  void _loadProducts() {
    _fs.getProducts().listen((products) {
      setState(() {
        allProducts = products;
        // Initialize single items
        for (var product in products) {
          if (product.variant != 'combo') {
            if (!singleItems.containsKey(product.name)) {
              singleItems[product.name] = {'normal': 0, 'small': 0};
            }
          }
        }
        // Initialize combo items
        for (var flavor in smallComboFlavors) {
          if (!comboItems.containsKey('small')) {
            comboItems['small'] = {};
          }
          comboItems['small']![flavor] = 0;
        }
        for (var flavor in standardComboFlavors) {
          if (!comboItems.containsKey('standard')) {
            comboItems['standard'] = {};
          }
          comboItems['standard']![flavor] = 0;
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

    // Collect all single items by variant with their prices
    List<MapEntry<String, double>> smallItemsList = []; // List of (productName, price) pairs
    List<MapEntry<String, double>> standardItemsList = []; // List of (productName, price) pairs

    // Collect all single items by variant
    singleItems.forEach((productName, variants) {
      variants.forEach((variant, quantity) {
        if (quantity > 0) {
          final product = allProducts.firstWhere(
            (p) => p.name.toLowerCase() == productName.toLowerCase() && p.variant == variant,
            orElse: () => allProducts.firstWhere(
              (p) => p.name.toLowerCase() == productName.toLowerCase(),
            ),
          );
          
          if (variant == 'small') {
            // Add this item quantity times to the list
            for (int i = 0; i < quantity; i++) {
              smallItemsList.add(MapEntry(productName, product.price));
            }
          } else if (variant == 'normal') {
            // Add this item quantity times to the list
            for (int i = 0; i < quantity; i++) {
              standardItemsList.add(MapEntry(productName, product.price));
            }
          }
        }
      });
    });

    // Calculate small items with combo pricing: 6 small items = RM 10
    if (smallItemsList.isNotEmpty) {
      int totalSmallItems = smallItemsList.length;
      int smallComboPacks = totalSmallItems ~/ 6; // number of full combo packs
      int remainingSmallItems = totalSmallItems % 6; // remaining items
      
      // Add combo pack price (RM 10 per pack of 6)
      total += smallComboPacks * 10.0;
      
      // Add remaining small items at their individual prices
      if (remainingSmallItems > 0) {
        // Take the last remaining items (they weren't part of combo packs)
        for (int i = totalSmallItems - remainingSmallItems; i < totalSmallItems; i++) {
          total += smallItemsList[i].value;
        }
      }
    }

    // Calculate standard items with combo pricing: 3 standard items = RM 10
    if (standardItemsList.isNotEmpty) {
      int totalStandardItems = standardItemsList.length;
      int standardComboPacks = totalStandardItems ~/ 3; // number of full combo packs
      int remainingStandardItems = totalStandardItems % 3; // remaining items
      
      // Add combo pack price (RM 10 per pack of 3)
      total += standardComboPacks * 10.0;
      
      // Add remaining standard items at their individual prices
      if (remainingStandardItems > 0) {
        // Take the last remaining items (they weren't part of combo packs)
        for (int i = totalStandardItems - remainingStandardItems; i < totalStandardItems; i++) {
          total += standardItemsList[i].value;
        }
      }
    }

    // Calculate combo items with tiered pricing (from combo section)
    final smallComboCount = _getComboTotalCount('small');
    final standardComboCount = _getComboTotalCount('standard');

    // Small size: 6 pcs = RM10, 12 pcs = RM20, ... up to 60 pcs = RM100
    if (smallComboCount > 0) {
      int smallPacks = smallComboCount ~/ 6; // full packs of 6
      double smallPrice = (smallPacks * 10).toDouble();
      if (smallPrice > 100.0) smallPrice = 100.0; // cap at RM100
      total += smallPrice;
    }

    // Standard size: 3 pcs = RM10, 6 pcs = RM20, ... up to 30 pcs = RM100
    if (standardComboCount > 0) {
      int standardPacks = standardComboCount ~/ 3; // full packs of 3
      double standardPrice = (standardPacks * 10).toDouble();
      if (standardPrice > 100.0) standardPrice = 100.0; // cap at RM100
      total += standardPrice;
    }

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

    comboItems.forEach((comboType, flavors) {
      int comboCount = flavors.values.fold(0, (sum, qty) => sum + (qty > 0 ? qty : 0));
      // Each combo unit counts as 1 piece
      totalPcs += comboCount;
    });

    return totalPcs;
  }

  int _getComboTotalCount(String comboType) {
    final flavors = comboItems[comboType] ?? {};
    return flavors.values.fold(0, (sum, qty) => sum + (qty > 0 ? qty : 0));
  }

  Future<void> _selectPickupDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: pickupDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
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
    
    // Header with company branding
    buffer.writeln('══════════════════════');
    buffer.writeln('    🍰 *CHEEZ N\' CREAM CO.*');
    buffer.writeln('══════════════════════');
    buffer.writeln('');
    buffer.writeln('📋 *RESIT PESANAN*');
    buffer.writeln('');
    
    // Order Information Section
    buffer.writeln('*Butiran Pesanan:*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 Pelanggan: *${order.customerName}*');
    if (order.phone.isNotEmpty) {
      buffer.writeln('📱 Telefon: ${order.phone}');
    }
    buffer.writeln('📅 Tarikh: ${dateFormat.format(order.orderDate)}');
    buffer.writeln('🕐 Masa: ${timeFormat.format(order.orderDate)}');
    buffer.writeln('');
    
    // Pickup Schedule Section
    if (order.pickupDateTime != null) {
      buffer.writeln('*Jadual Ambil:*');
      buffer.writeln('📅 Tarikh: ${dateFormat.format(order.pickupDateTime!)}');
      buffer.writeln('🕐 Masa: ${timeFormat.format(order.pickupDateTime!)}');
      buffer.writeln('');
    }
    
    // Order Items Section
    buffer.writeln('*Item Pesanan:*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    
    int itemNumber = 1;
    
    // Single items
    if (order.items.isNotEmpty) {
      order.items.forEach((itemName, quantity) {
        buffer.writeln('$itemNumber. *$itemName*');
        buffer.writeln('   • $itemName: $quantity pcs');
        buffer.writeln('');
        itemNumber++;
      });
    }
    
    // Combo packs
    if (order.comboPacks.isNotEmpty) {
      order.comboPacks.forEach((comboType, allocation) {
        // Format combo name: "small" -> "Small Combo", "standard" -> "Standard Combo"
        String comboName;
        if (comboType.toLowerCase() == 'small') {
          comboName = 'Small Combo';
        } else if (comboType.toLowerCase() == 'standard') {
          comboName = 'Standard Combo';
        } else {
          comboName = comboType.replaceAll('_', ' ').split(' ').map((word) => 
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
          ).join(' ');
        }
        buffer.writeln('$itemNumber. *$comboName Combo Pack*');
        allocation.forEach((flavor, quantity) {
          buffer.writeln('   • $flavor: $quantity pcs');
        });
        buffer.writeln('');
        itemNumber++;
      });
    }
    
    // Summary Section
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
    
    // Payment Information
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
    
    // Footer
    buffer.writeln('✨ *Terima kasih atas pesanan anda!* ✨');
    buffer.writeln('');
    
    return buffer.toString();
  }

  Future<void> _showReceiptPreview(String imagePath, String phone) async {
    print('_showReceiptPreview called with path: $imagePath');
    
    // Clean phone number (remove spaces, dashes, etc.)
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If phone doesn't start with +, assume it's a local number and add country code
    // Malaysia country code is +60
    if (!cleanPhone.startsWith('+')) {
      // Remove leading 0 if present
      if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }
      cleanPhone = '+60$cleanPhone';
    }

    // Remove the + sign for WhatsApp share
    String phoneForWhatsApp = cleanPhone.replaceAll('+', '');

    // Verify image file exists before showing dialog
    final imageFile = File(imagePath);
    final fileExists = await imageFile.exists();
    print('Image file exists: $fileExists at path: $imagePath');
    
    if (!fileExists) {
      Fluttertoast.showToast(
        msg: "Receipt image file not found at: $imagePath",
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    if (!mounted) {
      print('Widget not mounted, cannot show preview');
      return;
    }

    // Use Navigator.push instead of showDialog for more reliable display
    print('Navigating to receipt preview screen...');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ReceiptPreviewScreen(
          imagePath: imagePath,
          phoneForWhatsApp: phoneForWhatsApp,
        ),
        fullscreenDialog: true,
      ),
    );
    print('Receipt preview screen returned: $result');
  }

  Future<void> _sendWhatsAppReceipt(Order order, double orderPrice, double codFee) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      return; // No phone number, skip WhatsApp
    }

    try {
      Fluttertoast.showToast(msg: "Generating receipt image...");
      
      // Step 1: Generate receipt image completely first
      final imagePath = await ReceiptImageGenerator.saveReceiptImage(
        order,
        orderPrice,
        codFee,
      );

      if (imagePath == null) {
        Fluttertoast.showToast(
          msg: "Error generating receipt image",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Step 2: Verify the image file exists and is readable
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        Fluttertoast.showToast(
          msg: "Receipt image file not found",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Wait a moment to ensure file is fully written
      await Future.delayed(Duration(milliseconds: 300));
      
      Fluttertoast.showToast(msg: "Receipt image generated successfully!");

      // Step 3: Show preview dialog
      await _showReceiptPreview(imagePath, phone);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error generating receipt: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _saveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate pickup date/time is required
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

    // COD validation
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

    // Prepare order items
    Map<String, int> orderItems = {};
    singleItems.forEach((productName, variants) {
      variants.forEach((variant, quantity) {
        if (quantity > 0) {
          orderItems['$productName ($variant)'] = quantity;
        }
      });
    });

    // Prepare combo packs
    Map<String, Map<String, int>> comboPacks = {};
    comboItems.forEach((comboType, flavors) {
      Map<String, int> flavorMap = {};
      flavors.forEach((flavor, quantity) {
        if (quantity > 0) {
          flavorMap[flavor] = quantity;
        }
      });
      if (flavorMap.isNotEmpty) {
        comboPacks['${comboType}_combo'] = flavorMap;
      }
    });

    final orderPrice = _calculateTotal();
    final order = Order(
      id: '',
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      orderDate: DateTime.now(),
      pickupDateTime: pickupDateTime,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      codFee: codFee > 0 ? codFee : null,
      codAddress: codAddress,
      paymentChannel: paymentChannel,
      items: orderItems,
      comboPacks: comboPacks,
      totalPcs: totalPcs,
      totalPrice: orderPrice + (paymentMethod == 'cod' ? codFee : 0.0),
      status: 'pending',
    );

    _fs.addOrder(order);
    Fluttertoast.showToast(msg: "Order saved successfully");
    
    // Auto-send WhatsApp receipt if phone number is provided
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      await _sendWhatsAppReceipt(order, orderPrice, codFee);
    }
    
    Navigator.pop(context);
  }

  Future<void> _showAddCustomerDialog(BuildContext context, List<Customer> existingCustomers) async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Customer?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Customer"),
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
            child: Text("Add"),
          ),
        ],
      ),
    );

    if (result != null) {
      // Save the customer to Firestore
      await _fs.addCustomer(result);
      Fluttertoast.showToast(msg: "Customer added successfully");
      
      // Populate form fields with the new customer data immediately
      setState(() {
        _nameController.text = result.name;
        _phoneController.text = result.contactNo;
        _codAddressController.text = result.address;
      });
      
      // Wait a bit for Firestore to update, then find the new customer in the stream
      await Future.delayed(Duration(milliseconds: 300));
      
      // Get the first update from the stream to find the new customer
      try {
        final customers = await _fs.getAllCustomers().first;
        final newCustomer = customers.firstWhere(
          (c) => c.name == result.name && c.contactNo == result.contactNo,
        );
        
        setState(() {
          _selectedCustomerId = newCustomer.id;
        });
      } catch (e) {
        // If customer not found, that's okay - form fields are already populated
        // The StreamBuilder will update the dropdown automatically
      }
    }

    // Dispose controllers
    nameController.dispose();
    contactController.dispose();
    addressController.dispose();
  }

  Widget _buildProductCard(String productName, String variant, int quantity, Function(int) onQuantityChanged) {
    // Find product with matching variant, or fallback to any variant of the same name
    Product? product;
    try {
      product = allProducts.firstWhere(
      (p) => p.name.toLowerCase() == productName.toLowerCase() && p.variant == variant,
      );
    } catch (e) {
      try {
        product = allProducts.firstWhere(
        (p) => p.name.toLowerCase() == productName.toLowerCase(),
        );
      } catch (e) {
        product = Product(
          id: '',
          name: productName,
          variant: variant,
          price: 0,
          cost: 0,
        );
      }
    }

    // Get price for current variant
    double displayPrice = product.price;
    if (product.variant != variant) {
      // Try to find the correct variant price
      try {
        final variantProduct = allProducts.firstWhere(
          (p) => p.name.toLowerCase() == productName.toLowerCase() && p.variant == variant,
    );
        displayPrice = variantProduct.price;
      } catch (e) {
        displayPrice = product.price;
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl != null && !product.imageUrl!.startsWith('assets/')
                  ? Image.file(
                      File(product.imageUrl!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : Image.asset(
                      product.imageUrl ?? productImages[productName.toLowerCase()] ?? 'assets/images/placeholder.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: Icon(Icons.image_not_supported),
                        );
                      },
                    ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    PriceCalculator.formatPrice(displayPrice),
                    style: TextStyle(fontSize: 16, color: Colors.orange[900], fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: Text('Small'),
                        selected: variant == 'small',
                        labelStyle: TextStyle(
                          color: variant == 'small' ? Colors.white : Colors.black87,
                        ),
                        selectedColor: Colors.green,
                        onSelected: (selected) {
                          if (selected) {
                            final currentQty = singleItems[productName]![variant] ?? 0;
                            singleItems[productName]!['small'] = currentQty;
                            singleItems[productName]!['normal'] = 0;
                            setState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('Standard'),
                        selected: variant == 'normal',
                        labelStyle: TextStyle(
                          color: variant == 'normal' ? Colors.white : Colors.black87,
                        ),
                        selectedColor: Colors.blue,
                        onSelected: (selected) {
                          if (selected) {
                            final currentQty = singleItems[productName]![variant] ?? 0;
                            singleItems[productName]!['normal'] = currentQty;
                            singleItems[productName]!['small'] = 0;
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Quantity Controls
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: quantity > 0
                      ? () {
                          onQuantityChanged(quantity - 1);
                          setState(() {});
                        }
                      : null,
                ),
                Text(
                  '$quantity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () {
                    onQuantityChanged(quantity + 1);
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboSection() {
    final currentFlavors = selectedComboType == 'small' ? smallComboFlavors : standardComboFlavors;
    final currentCombo = comboItems[selectedComboType] ?? {};

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Combo Pack',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            // Combo Type Selection
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Small Combo (2 flavors)'),
                    selected: selectedComboType == 'small',
                    labelStyle: TextStyle(
                      color: selectedComboType == 'small' ? Colors.white : Colors.black87,
                    ),
                    selectedColor: Colors.green,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedComboType = 'small';
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Standard Combo (3 flavors)'),
                    selected: selectedComboType == 'standard',
                    labelStyle: TextStyle(
                      color: selectedComboType == 'standard' ? Colors.white : Colors.black87,
                    ),
                    selectedColor: Colors.blue,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedComboType = 'standard';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Combo Warning
            Builder(
              builder: (context) {
                final currentCount = _getComboTotalCount(selectedComboType);
                final limit = selectedComboType == 'small' ? 6 : 3;
                if (currentCount > limit) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[900], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${selectedComboType == 'small' ? 'Small' : 'Standard'} combo limit is $limit pcs. Currently: $currentCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            SizedBox(height: 16),
            // Flavor Selection
            Text(
              'Select Flavors (can choose same flavor, no limit):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            ...currentFlavors.map((flavor) {
              // Get price and image for this flavor (try to find normal variant)
              double flavorPrice = 0.0;
              String? flavorImageUrl;
              try {
                final flavorProduct = allProducts.firstWhere(
                  (p) => p.name.toLowerCase() == flavor.toLowerCase(),
                );
                flavorPrice = flavorProduct.price;
                flavorImageUrl = flavorProduct.imageUrl;
              } catch (e) {
                // Use default price if not found
                flavorPrice = 3.50;
              }

              return Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: flavorImageUrl != null && !flavorImageUrl!.startsWith('assets/')
                            ? Image.file(
                                File(flavorImageUrl!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image_not_supported, size: 30),
                                  );
                                },
                              )
                            : Image.asset(
                                flavorImageUrl ?? productImages[flavor.toLowerCase()] ?? 'assets/images/placeholder.jpg',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image_not_supported, size: 30),
                                  );
                                },
                              ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              flavor,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              PriceCalculator.formatPrice(flavorPrice),
                              style: TextStyle(fontSize: 14, color: Colors.orange[900], fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Quantity Controls
                      Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: (currentCombo[flavor] ?? 0) > 0
                            ? () {
                                setState(() {
                                  comboItems[selectedComboType]![flavor] =
                                      (comboItems[selectedComboType]![flavor] ?? 0) - 1;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '${currentCombo[flavor] ?? 0}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline),
                            onPressed: () {
                              final currentCount = _getComboTotalCount(selectedComboType);
                              final limit = selectedComboType == 'small' ? 6 : 3;
                              if (currentCount >= limit) {
                                Fluttertoast.showToast(
                                  msg: selectedComboType == 'small'
                                      ? "Small combo limit is 6 pcs. Reduce another flavor before adding more."
                                      : "Standard combo limit is 3 pcs. Reduce another flavor before adding more.",
                                  toastLength: Toast.LENGTH_LONG,
                                );
                                return;
                              }
                              setState(() {
                                comboItems[selectedComboType]![flavor] =
                                    (comboItems[selectedComboType]![flavor] ?? 0) + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderPrice = _calculateTotal();
    final codFeeForDisplay =
        paymentMethod == 'cod' ? (double.tryParse(_codAmountController.text.trim()) ?? 0.0) : 0.0;
    final totalPrice = orderPrice + codFeeForDisplay;
    final totalPcs = _calculateTotalPcs();

    return Scaffold(
      appBar: AppBar(title: Text("Add Customer Order")),
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
                    // Customer Selection
                    StreamBuilder<List<Customer>>(
                      stream: _fs.getAllCustomers(),
                      builder: (context, snapshot) {
                        List<Customer> customers = snapshot.data ?? [];
                        
                        // Only use selected customer ID if it exists in the current list
                        String? validCustomerId = _selectedCustomerId;
                        if (validCustomerId != null && !customers.any((c) => c.id == validCustomerId)) {
                          validCustomerId = null;
                        }
                        
                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: validCustomerId,
                                decoration: InputDecoration(
                                  labelText: "Select Customer (optional)",
                                  prefixIcon: Icon(Icons.people),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text("-- Select Customer --"),
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
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.add_circle),
                              color: Theme.of(context).primaryColor,
                              tooltip: 'Add New Customer',
                              onPressed: () => _showAddCustomerDialog(context, customers),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    // Customer Info
                    CustomTextField(
                      controller: _nameController,
                      label: "Customer Name",
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
                      controller: _phoneController,
                      label: "Phone Number (optional)",
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    // Pickup DateTime
                    InkWell(
                      onTap: () => _selectPickupDateTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Pickup Date & Time *",
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: pickupDateTime == null ? 'Required' : null,
                        ),
                        child: Text(
                          pickupDateTime != null
                              ? DateFormat('yyyy-MM-dd HH:mm').format(pickupDateTime!)
                              : 'Select pickup date and time',
                          style: TextStyle(
                            color: pickupDateTime != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Payment Method
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text('COD'),
                            selected: paymentMethod == 'cod',
                            labelStyle: TextStyle(
                              color: paymentMethod == 'cod' ? Colors.white : Colors.black87,
                            ),
                            selectedColor: Colors.blue,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  paymentMethod = 'cod';
                                });
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Text('Pickup'),
                            selected: paymentMethod == 'pickup',
                            labelStyle: TextStyle(
                              color: paymentMethod == 'pickup' ? Colors.white : Colors.black87,
                            ),
                            selectedColor: Colors.green,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  paymentMethod = 'pickup';
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Payment Status + Channel
                    Row(
                      children: [
                        Checkbox(
                          value: isPaid,
                          onChanged: (value) {
                            setState(() {
                              isPaid = value ?? false;
                            });
                          },
                        ),
                        Text('Payment Received'),
                        SizedBox(width: 12),
                        ChoiceChip(
                          label: Text('Cash'),
                          selected: paymentChannel == 'cash',
                          labelStyle: TextStyle(
                            color: paymentChannel == 'cash' ? Colors.white : Colors.black87,
                          ),
                          selectedColor: Colors.green,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                paymentChannel = 'cash';
                              });
                            }
                          },
                        ),
                        SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('QR'),
                          selected: paymentChannel == 'qr',
                          labelStyle: TextStyle(
                            color: paymentChannel == 'qr' ? Colors.white : Colors.black87,
                          ),
                          selectedColor: Colors.blue,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                paymentChannel = 'qr';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // COD Details
                    if (paymentMethod == 'cod') ...[
                      CustomTextField(
                        controller: _codAmountController,
                        label: "COD Amount (RM)",
                        prefixIcon: Icons.delivery_dining,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 12),
                      CustomTextField(
                        controller: _codAddressController,
                        label: "COD Address",
                        prefixIcon: Icons.location_on,
                        maxLines: 2,
                      ),
                      SizedBox(height: 24),
                    ] else
                      SizedBox(height: 24),
                    // Variant Filter
                    Row(
                      children: [
                        Text(
                          "Filter by variant:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedVariantFilter,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(value: 'small', child: Text('Small')),
                              DropdownMenuItem(value: 'normal', child: Text('Standard')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedVariantFilter = value ?? 'all';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Single Items Section
                    Text(
                      "Menu Items",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    // Show filtered products
                    ...allProducts
                        .where((p) {
                          if (p.variant == 'combo') return false;
                          if (selectedVariantFilter == 'small') {
                            return p.variant == 'small';
                          } else if (selectedVariantFilter == 'normal') {
                            return p.variant == 'normal';
                          } else {
                            return true; // 'all'
                          }
                        })
                        .map((product) {
                          final productName = product.name;
                          if (!singleItems.containsKey(productName)) {
                            singleItems[productName] = {'normal': 0, 'small': 0};
                          }
                          // Show the variant that has quantity > 0, or default to product's variant
                          final currentVariant = singleItems[productName]!['normal']! > 0
                              ? 'normal'
                              : (singleItems[productName]!['small']! > 0 ? 'small' : product.variant);
                          final currentQuantity = singleItems[productName]![currentVariant] ?? 0;
                          
                          return _buildProductCard(
                            productName,
                            currentVariant,
                            currentQuantity,
                            (newQuantity) {
                              singleItems[productName]![currentVariant] = newQuantity;
                            },
                          );
                        })
                        .toList(),
                    SizedBox(height: 24),
                    // Combo Section
                    _buildComboSection(),
                  ],
                ),
              ),
            ),
            // Summary and Save Button
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Pieces:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "$totalPcs pcs",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order Price:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        PriceCalculator.formatPrice(orderPrice),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  if (paymentMethod == 'cod') ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "COD Fee:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          PriceCalculator.formatPrice(codFeeForDisplay),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Price:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        PriceCalculator.formatPrice(totalPrice),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveOrder,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text("Save Order"),
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
}
