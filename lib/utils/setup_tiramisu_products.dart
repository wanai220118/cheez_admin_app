import '../services/firestore_service.dart';
import '../models/product.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Utility function to delete all Tiramisu products and add new ones
Future<void> setupTiramisuProducts() async {
  final fs = FirestoreService();
  
  try {
    // Delete all existing Tiramisu products
    await fs.deleteProductsByVariant('Tiramisu');
    
    // Create new Tiramisu products
    final newProducts = [
      // Big size products (RM 7)
      Product(
        id: '',
        name: 'Classic Tiramisu',
        variant: 'Tiramisu',
        price: 7.0,
        cost: 0.0,
        isActive: true,
        size: 'big',
      ),
      Product(
        id: '',
        name: 'Bahumisu',
        variant: 'Tiramisu',
        price: 7.0,
        cost: 0.0,
        isActive: true,
        size: 'big',
      ),
      Product(
        id: '',
        name: 'BatikMisu',
        variant: 'Tiramisu',
        price: 7.0,
        cost: 0.0,
        isActive: true,
        size: 'big',
      ),
      // Small size products (RM 2)
      Product(
        id: '',
        name: 'Classic Tiramisu',
        variant: 'Tiramisu',
        price: 2.0,
        cost: 0.0,
        isActive: true,
        size: 'small',
      ),
      Product(
        id: '',
        name: 'Bahumisu',
        variant: 'Tiramisu',
        price: 2.0,
        cost: 0.0,
        isActive: true,
        size: 'small',
      ),
      Product(
        id: '',
        name: 'BatikMisu',
        variant: 'Tiramisu',
        price: 2.0,
        cost: 0.0,
        isActive: true,
        size: 'small',
      ),
    ];
    
    // Add all new products
    await fs.addProductsBatch(newProducts);
    
    Fluttertoast.showToast(msg: "Tiramisu products updated successfully");
  } catch (e) {
    Fluttertoast.showToast(msg: "Error updating Tiramisu products: $e");
  }
}

