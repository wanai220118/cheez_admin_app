import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../widgets/receipt_widget.dart';

class ReceiptImageGenerator {
  static Future<Uint8List?> generateReceiptImage(
    Order order,
    double orderPrice,
    double codFee, {
    List<Product>? products,
  }) async {
    try {
      print('Creating screenshot controller...');
      final screenshotController = ScreenshotController();
      
      print('Capturing widget as image...');
      // Capture the receipt widget as image
      // captureFromWidget creates its own widget tree, so no context needed
      // Wrap in MediaQuery to avoid MediaQuery errors
      // Increase delay to ensure widget is fully rendered
      // Use ConstrainedBox to allow unlimited height for full content capture
      final imageBytes = await screenshotController.captureFromWidget(
        MediaQuery(
          data: MediaQueryData(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Material(
              color: Colors.transparent,
              child: Container(
                color: Color(0xFF783D2E), // Background color matching receipt
                padding: EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 420,
                      maxWidth: 420,
                      // No maxHeight constraint - allow unlimited height for full receipt capture
                    ),
                    child: ReceiptWidget(
                      order: order,
                      orderPrice: orderPrice,
                      codFee: codFee,
                      products: products,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        delay: Duration(milliseconds: 2000), // Increased delay for full rendering
        pixelRatio: 2.0,
      );

      if (imageBytes == null || imageBytes.isEmpty) {
        print('Error: Image bytes are null or empty');
        return null;
      }

      print('Image captured successfully: ${imageBytes.length} bytes');
      return imageBytes;
    } catch (e, stackTrace) {
      print('Error generating receipt image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<String?> saveReceiptImage(
    Order order,
    double orderPrice,
    double codFee, {
    List<Product>? products,
  }) async {
    try {
      print('Starting receipt image generation...');
      final imageBytes = await generateReceiptImage(order, orderPrice, codFee, products: products);
      if (imageBytes == null) {
        print('Error: Image bytes are null');
        return null;
      }

      print('Image bytes generated: ${imageBytes.length} bytes');
      final directory = await getTemporaryDirectory();
      final fileName = 'receipt_${order.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      print('Saving image to: $filePath');
      await file.writeAsBytes(imageBytes);
      
      // Verify file was written
      if (await file.exists()) {
        final fileSize = await file.length();
        print('Image saved successfully. File size: $fileSize bytes');
        return file.path;
      } else {
        print('Error: File was not created at $filePath');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error saving receipt image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

