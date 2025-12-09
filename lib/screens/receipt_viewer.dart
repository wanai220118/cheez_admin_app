import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/order.dart';
import '../utils/html_receipt_generator.dart';
import '../utils/price_calculator.dart';
import '../utils/receipt_image_generator.dart';

class ReceiptViewerScreen extends StatefulWidget {
  final Order order;
  final double orderPrice;
  final double codFee;

  const ReceiptViewerScreen({
    Key? key,
    required this.order,
    required this.orderPrice,
    required this.codFee,
  }) : super(key: key);

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final htmlContent = HtmlReceiptGenerator.generateHtmlReceipt(
      widget.order,
      widget.orderPrice,
      widget.codFee,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  Future<void> _shareReceipt() async {
    try {
      Fluttertoast.showToast(msg: "Generating receipt image...");
      
      // Generate and save receipt image
      final imagePath = await ReceiptImageGenerator.saveReceiptImage(
        widget.order,
        widget.orderPrice,
        widget.codFee,
      );

      if (imagePath == null) {
        Fluttertoast.showToast(
          msg: "Error generating receipt image",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Receipt for Order',
      );

      Fluttertoast.showToast(msg: "Receipt shared successfully");
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error sharing receipt: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _copyHtmlToClipboard() async {
    try {
      final htmlContent = HtmlReceiptGenerator.generateHtmlReceipt(
        widget.order,
        widget.orderPrice,
        widget.codFee,
      );

      await Clipboard.setData(ClipboardData(text: htmlContent));
      Fluttertoast.showToast(msg: "Receipt HTML copied to clipboard");
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error copying receipt: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Receipt"),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            tooltip: 'Share Receipt',
            onPressed: _shareReceipt,
          ),
          IconButton(
            icon: Icon(Icons.copy),
            tooltip: 'Copy HTML',
            onPressed: _copyHtmlToClipboard,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

