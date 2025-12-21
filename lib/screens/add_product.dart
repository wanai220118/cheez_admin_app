import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_textfield.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddProductScreen extends StatefulWidget {
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _series = 'Tiramisu'; // Series: Tiramisu or Cheesekut
  String _size = 'small'; // Size: small or big
  final FirestoreService _fs = FirestoreService();
  File? _selectedImage;
  String? _imagePath;

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
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: "",
        name: _nameController.text.trim(),
        variant: _series, // Using variant field to store series
        price: double.parse(_priceController.text),
        cost: double.tryParse(_costController.text) ?? 0.0,
        // Store local file path if selected, otherwise use placeholder asset
        imageUrl: _imagePath ?? 'assets/images/placeholder.jpg',
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isActive: true,
        size: _size,
      );
      _fs.addProduct(product);
      Fluttertoast.showToast(msg: "Product added successfully");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Product")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: "Product Name",
                prefixIcon: Icons.shopping_bag,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                label: "Price",
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _costController,
                label: "Cost (optional)",
                keyboardType: TextInputType.number,
                prefixIcon: Icons.money_off,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Please enter a valid cost';
                    }
                  }
                  return null;
                },
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
                items: ['Tiramisu', 'Cheesekut']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (s) => setState(() => _series = s!),
              ),
              SizedBox(height: 16),
              // Size field
              DropdownButtonFormField<String>(
                value: _size,
                decoration: InputDecoration(
                  labelText: "Size",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.aspect_ratio),
                ),
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Small')),
                  DropdownMenuItem(value: 'big', child: Text('Big')),
                ],
                onChanged: (value) {
                  setState(() {
                    _size = value ?? 'small';
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
                child: Row(
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
                            : Image.asset(
                                'assets/images/placeholder.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                      ),
                    ),
                    SizedBox(height: 16, width: 16),
                    Expanded(
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
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.photo_library, size: 18),
                            label: Text(
                              _selectedImage != null ? "Change Image" : "Choose Image",
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
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text("Save Product"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
