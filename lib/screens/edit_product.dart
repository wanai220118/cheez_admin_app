import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/svg_icon.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _descriptionController;
  late String _series; // Series: Tiramisu, Cheesekut, Banana Pudding, Others
  late String _size; // Size: small, big or none (optional)
  late bool _isActive;
  final FirestoreService _fs = FirestoreService();
  File? _selectedImage;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _costController = TextEditingController(text: widget.product.cost.toString());
    _descriptionController = TextEditingController(text: widget.product.description ?? '');
    // Use variant field to store series, default to Tiramisu if not found
    _series = widget.product.variant;
    // If variant is old format (normal/small), default to Tiramisu
    if (_series != 'Tiramisu' &&
        _series != 'Cheesekut' &&
        _series != 'Banana Pudding' &&
        _series != 'Others') {
      _series = 'Tiramisu';
    }
    // Initialize size from product.size or infer from price
    _size = widget.product.size ?? (widget.product.price <= 2.0 ? 'small' : 'big');
    _imagePath = widget.product.imageUrl;
    _isActive = widget.product.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    try {
      final tempFile = File(pickedFile.path);
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'product_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final savedPath = path.join(imagesDir.path, fileName);
      final savedFile = await tempFile.copy(savedPath);

      setState(() {
        _selectedImage = savedFile;
        _imagePath = savedPath;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save image locally: ${e.toString()}');
    }
  }

  void saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all required fields");
      return;
    }

    final updatedProduct = Product(
      id: widget.product.id,
      name: _nameController.text,
      variant: _series, // Using variant field to store series
      price: double.tryParse(_priceController.text) ?? 0.0,
      cost: double.tryParse(_costController.text) ?? 0.0,
      imageUrl: _imagePath ?? widget.product.imageUrl ?? 'assets/images/placeholder.jpg',
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      isActive: _isActive,
      size: _size == 'none' ? null : _size,
    );

    _fs.updateProduct(updatedProduct);
    Fluttertoast.showToast(msg: "Product updated successfully");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Product"),
        actions: [
          IconButton(
            icon: SvgIcon(
              assetPath: 'assets/icons/save-icon.svg',
              size: 24,
              color: Colors.white,
            ),
            onPressed: saveProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(
              controller: _nameController,
              label: "Product Name",
              prefixIcon: Icons.shopping_bag,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              label: "Price",
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _costController,
              label: "Cost (optional)",
              keyboardType: TextInputType.number,
              prefixIcon: Icons.money_off,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: "Description (optional)",
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
            SizedBox(height: 16),
            // Series field (replacing Variant)
            DropdownButtonFormField<String>(
              value: _series,
              decoration: InputDecoration(
                labelText: "Series",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.category),
              ),
              items: ['Tiramisu', 'Cheesekut', 'Banana Pudding', 'Others']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (s) => setState(() => _series = s!),
            ),
            SizedBox(height: 16),
            // Size field
            DropdownButtonFormField<String>(
              value: _size,
              decoration: InputDecoration(
                labelText: "Size (optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.aspect_ratio),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('No size / Single size')),
                DropdownMenuItem(value: 'small', child: Text('Small')),
                DropdownMenuItem(value: 'big', child: Text('Big')),
              ],
              onChanged: (value) {
                setState(() {
                  _size = value ?? 'none';
                });
              },
            ),
            SizedBox(height: 16),
            // Image Section (device-local image or placeholder)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Product Image",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (_imagePath != null && !_imagePath!.startsWith('assets/')
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      widget.product.imageUrl ?? 'assets/images/placeholder.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Icon(Icons.image_not_supported),
                                        );
                                      },
                                    )),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(Icons.photo_library, size: 18),
                              label: Text(
                                _selectedImage != null || (_imagePath != null && !_imagePath!.startsWith('assets/'))
                                    ? "Change Image"
                                    : "Choose Image",
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Images are stored only on this device and not uploaded to the cloud.",
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Product Status Toggle
            Card(
              color: _isActive ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Product Status",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _isActive ? "Active" : "Inactive",
                          style: TextStyle(
                            fontSize: 14,
                            color: _isActive ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: saveProduct,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text("Update Product"),
            ),
          ],
        ),
      ),
    );
  }
}

