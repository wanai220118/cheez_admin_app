import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../utils/price_calculator.dart';
import '../widgets/svg_icon.dart';
import 'edit_product.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirestoreService _fs = FirestoreService();

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name} (${product.variant})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _fs.deleteProduct(product.id);
              Navigator.pop(context);
              Navigator.pop(context); // close detail screen
              Fluttertoast.showToast(msg: "Product deleted");
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: _fs.getProductById(widget.product.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.product.name)),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final product = snapshot.data;

        // If product was deleted from elsewhere, close this screen
        if (product == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Product no longer exists");
            }
          });
          return Scaffold(
            appBar: AppBar(title: Text(widget.product.name)),
            body: Center(child: Text('Product no longer exists')),
          );
        }

        final imagePath = product.imageUrl;
        final isLocalFile = imagePath != null && !imagePath.startsWith('assets/');

        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              IconButton(
                icon: SvgIcon(
                  assetPath: 'assets/icons/edit-icon.svg',
                  size: 22,
                ),
                tooltip: 'Edit',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
                  );
                  // After returning from edit, the StreamBuilder will rebuild with latest data
                },
              ),
              IconButton(
                icon: SvgIcon(
                  assetPath: 'assets/icons/delete-icon.svg',
                  size: 22,
                  color: Colors.red,
                ),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, product),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isLocalFile
                        ? Image.file(
                            File(imagePath!),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported, size: 48),
                              );
                            },
                          )
                        : Image.asset(
                            imagePath ?? 'assets/images/placeholder.jpg',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported, size: 48),
                              );
                            },
                          ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  product.name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        product.variant.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      PriceCalculator.formatPrice(product.price),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
                if (product.cost > 0) ...[
                  SizedBox(height: 4),
                  Text(
                    'Cost: ${PriceCalculator.formatPrice(product.cost)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
                SizedBox(height: 16),
                if (product.description != null && product.description!.isNotEmpty) ...[
                  Text(
                    "Description",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    product.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}


