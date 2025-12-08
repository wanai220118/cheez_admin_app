import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/customer.dart';
import '../widgets/custom_textfield.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? existingCustomer;

  const AddCustomerScreen({Key? key, this.existingCustomer}) : super(key: key);

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _fs = FirestoreService();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  bool get isEdit => widget.existingCustomer != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final customer = widget.existingCustomer!;
      _nameController.text = customer.name;
      _contactController.text = customer.contactNo;
      _addressController.text = customer.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final customer = Customer(
      id: isEdit ? widget.existingCustomer!.id : '',
      name: _nameController.text.trim(),
      contactNo: _contactController.text.trim(),
      address: _addressController.text.trim(),
      createdAt: isEdit ? widget.existingCustomer!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      _fs.updateCustomer(customer);
      Fluttertoast.showToast(msg: "Customer updated successfully");
    } else {
      _fs.addCustomer(customer);
      Fluttertoast.showToast(msg: "Customer added successfully");
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Customer" : "Add Customer"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nameController,
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
                controller: _contactController,
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
                controller: _addressController,
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
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEdit ? "Update Customer" : "Save Customer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

