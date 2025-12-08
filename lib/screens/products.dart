import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../utils/navigation_helper.dart';
import '../widgets/smooth_reveal.dart';
import 'add_product.dart';
import 'edit_product.dart';
import 'product_detail.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProductsScreen extends StatelessWidget {
  final FirestoreService _fs = FirestoreService();

  void _showDeleteDialog(BuildContext context, Product product) {
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
            onPressed: () {
              _fs.deleteProduct(product.id);
              Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Products"),
        actions: [
          IconButton(
            icon: SvgIcon(
              assetPath: 'assets/icons/add-icon.svg',
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => NavigationHelper.navigateWithBounce(context, AddProductScreen()),
          )
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final products = snapshot.data!;
          if (products.isEmpty) {
            return SmoothReveal(
              child: EmptyState(
                message: "No products added yet",
                iconPath: 'assets/icons/products-icon.svg',
                actionLabel: "Add Product",
                onAction: () => NavigationHelper.navigateWithBounce(context, AddProductScreen()),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return SmoothReveal(
                delay: Duration(milliseconds: index * 50),
                child: ProductCard(
                  product: p,
                  onTap: () => NavigationHelper.navigateWithBounce(
                    context,
                    ProductDetailScreen(product: p),
                  ),
                  onEdit: () => NavigationHelper.navigateWithBounce(
                    context,
                    EditProductScreen(product: p),
                  ),
                  onDelete: () => _showDeleteDialog(context, p),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
