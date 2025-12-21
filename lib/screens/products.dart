import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../utils/navigation_helper.dart';
import '../widgets/smooth_reveal.dart';
import '../utils/setup_tiramisu_products.dart';
import 'add_product.dart';
import 'edit_product.dart';
import 'product_detail.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;
  String _selectedFilter = 'all'; // 'all', 'Tiramisu', 'Cheesekut', 'small', 'big'
  bool _showFilters = false;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Product'),
          ],
        ),
        content: Text('Are you sure you want to delete ${product.name} (${product.variant})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              _fs.deleteProduct(product.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Product deleted");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleProductStatus(Product product) async {
    final updatedProduct = Product(
      id: product.id,
      name: product.name,
      variant: product.variant,
      price: product.price,
      cost: product.cost,
      imageUrl: product.imageUrl,
      description: product.description,
      isActive: !product.isActive,
    );
    await _fs.updateProduct(updatedProduct);
    Fluttertoast.showToast(
      msg: product.isActive ? "Product deactivated" : "Product activated",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text("Products"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded),
            onPressed: _toggleFilters,
            tooltip: 'Filters',
          ),
          SizedBox(width: 8),
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: SvgIcon(
                assetPath: 'assets/icons/add-icon.svg',
                size: 22,
                color: Colors.white,
              ),
              onPressed: () => NavigationHelper.navigateWithBounce(context, AddProductScreen()),
              tooltip: 'Add Product',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Compact Filter Section with Animation
          SizeTransition(
            sizeFactor: _filterAnimation,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Tiramisu', 'Tiramisu'),
                      _buildFilterChip('Cheesekut', 'Cheesekut'),
                      _buildFilterChip('Small', 'small'),
                      _buildFilterChip('Big', 'big'),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Show Inactive Toggle
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showInactive = !_showInactive;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _showInactive,
                            onChanged: (value) {
                              setState(() {
                                _showInactive = value ?? false;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Text(
                            'Show inactive products',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Setup Tiramisu Products Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Reset Tiramisu Products'),
                          content: Text(
                            'This will delete ALL existing Tiramisu products and add new ones:\n\n'
                            'Big (RM7): Classic Tiramisu, Bahumisu, BatikMisu\n'
                            'Small (RM2): Classic Tiramisu, Bahumisu, BatikMisu\n\n'
                            'Are you sure?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Yes, Reset'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await setupTiramisuProducts();
                      }
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Reset Tiramisu Products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Divider(height: 1),
          
          // Products List
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _showInactive ? _fs.getProducts() : _fs.getProducts(activeOnly: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
                
                var products = snapshot.data!;
                
                // Apply filters (if showing inactive, we already have all products, otherwise only active)
                // No need to filter again since we're using activeOnly parameter
                
                // Apply selected filter
                if (_selectedFilter != 'all') {
                  if (_selectedFilter == 'small' || _selectedFilter == 'big') {
                    // Filter by size
                    products = products.where((p) {
                      final productSize = p.price <= 2.0 ? 'small' : 'big';
                      return productSize == _selectedFilter;
                    }).toList();
                  } else {
                    // Filter by series
                    products = products.where((p) => p.variant == _selectedFilter).toList();
                  }
                }
                
                // Apply search filter
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  products = products.where((p) {
                    return p.name.toLowerCase().contains(query) ||
                           p.variant.toLowerCase().contains(query) ||
                           (p.description?.toLowerCase().contains(query) ?? false);
                  }).toList();
                }
                
                // Sort alphabetically by default
                products.sort((a, b) => a.name.compareTo(b.name));
                
                if (products.isEmpty) {
                  return SmoothReveal(
                    child: EmptyState(
                      message: _searchController.text.isNotEmpty 
                          ? "No products match your search"
                          : _showInactive 
                              ? "No products found" 
                              : "No active products",
                      iconPath: 'assets/icons/products-icon.svg',
                      actionLabel: "Add Product",
                      onAction: () => NavigationHelper.navigateWithBounce(context, AddProductScreen()),
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return SmoothReveal(
                      delay: Duration(milliseconds: index * 30),
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
                        onToggleStatus: () => _toggleProductStatus(p),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Colors.transparent,
        ),
      ),
    );
  }
}