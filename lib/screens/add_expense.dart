import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../widgets/custom_textfield.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const AddExpenseScreen({Key? key, this.existingExpense}) : super(key: key);

  bool get isEdit => existingExpense != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _fs = FirestoreService();
  
  // Category and subcategory
  String _category = 'expense';
  String? _subcategory;
  
  // Date
  DateTime _expenseDate = DateTime.now();
  
  // Overall supplier
  final _supplierController = TextEditingController();
  String? _selectedSupplier;
  
  // Expense items
  List<ExpenseItemData> _items = [ExpenseItemData()];
  
  // Subcategories mapping
  final Map<String, List<String>> _subcategories = {
    'packaging': ['bekas 2oz', 'bekas 4oz', 'sudu', 'plastic s size', 'plastic l size', 'sticker'],
    'ingredients': [
      'cream cheese',
      'whipping cream',
      'nestum',
      'serbuk coklat',
      'biskut cream O',
      'bahulu',
      'gula',
      'fresh milk',
      'biskut marie large',
      'biskut marie small'
    ],
    'utilities': [],
    'commission': [],
    'expense': [],
    'gas': [],
    'storage': [],
    'etc': [],
  };

  @override
  void initState() {
    super.initState();

    // If editing an existing expense, prefill fields
    final existing = widget.existingExpense;
    if (existing != null) {
      _category = existing.category;
      _subcategory = existing.subcategory;
      _expenseDate = existing.date;
      _supplierController.text = existing.supplier ?? '';
      _selectedSupplier = existing.supplier;

      // Build items list from existing items
      _items = existing.items.map((expenseItem) {
        final data = ExpenseItemData();
        data.itemNameController.text = expenseItem.itemName;
        data.quantityController.text = expenseItem.quantity.toString();
        data.priceController.text = expenseItem.pricePerItem.toStringAsFixed(2);
        data.totalController.text = expenseItem.totalCost.toStringAsFixed(2);
        return data;
      }).toList();

      if (_items.isEmpty) {
        _items = [ExpenseItemData()];
      }
    }
  }

  @override
  void dispose() {
    _supplierController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _expenseDate) {
      setState(() {
        _expenseDate = picked;
        _subcategory = null; // Reset subcategory when date changes
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add(ExpenseItemData());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  void _calculateItemTotal(int index) {
    final item = _items[index];
    final qty = double.tryParse(item.quantityController.text) ?? 0.0;
    final price = double.tryParse(item.priceController.text) ?? 0.0;
    final total = qty * price;
    item.totalController.text = total.toStringAsFixed(2);
    setState(() {});
  }

  double _calculateOverallTotal() {
    return _items.fold(0.0, (sum, item) {
      final total = double.tryParse(item.totalController.text) ?? 0.0;
      return sum + total;
    });
  }

  void saveExpense() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate items
    bool hasValidItems = false;
    List<ExpenseItem> expenseItems = [];
    
    for (var itemData in _items) {
      final itemName = itemData.itemNameController.text.trim();
      final qty = double.tryParse(itemData.quantityController.text) ?? 0.0;
      final price = double.tryParse(itemData.priceController.text) ?? 0.0;
      final total = double.tryParse(itemData.totalController.text) ?? 0.0;
      
      if (itemName.isNotEmpty && qty > 0 && price > 0) {
        hasValidItems = true;
        expenseItems.add(ExpenseItem(
          itemName: itemName,
          quantity: qty,
          pricePerItem: price,
          totalCost: total > 0 ? total : (qty * price),
          supplier: null,
        ));
      }
    }

    if (!hasValidItems) {
      Fluttertoast.showToast(msg: "Please add at least one valid item");
      return;
    }

    final totalCost = _calculateOverallTotal();
    if (totalCost <= 0) {
      Fluttertoast.showToast(msg: "Total cost must be greater than 0");
      return;
    }

    final expense = Expense(
      id: widget.existingExpense?.id ?? "",
      category: _category,
      subcategory: _subcategory,
      items: expenseItems,
      totalCost: totalCost,
      date: _expenseDate,
      supplier: _supplierController.text.trim().isNotEmpty 
          ? _supplierController.text.trim() 
          : null,
    );

    if (widget.isEdit) {
      _fs.updateExpense(expense);
      Fluttertoast.showToast(msg: "Expense updated successfully");
    } else {
      _fs.addExpense(expense);
      Fluttertoast.showToast(msg: "Expense saved successfully");
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final overallTotal = _calculateOverallTotal();
    
    return Scaffold(
      appBar: AppBar(title: Text("Add Expense")),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Date",
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_expenseDate),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Category
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        labelText: "Category",
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['packaging', 'ingredients', 'utilities', 'commission', 'expense', 'gas', 'storage', 'etc']
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                          _subcategory = null; // Reset subcategory when category changes
                          // Reset all item names when category changes
                          for (var item in _items) {
                            item.itemNameController.clear();
                          }
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Subcategory (if available)
                    if (_subcategories[_category] != null && _subcategories[_category]!.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _subcategory,
                        decoration: InputDecoration(
                          labelText: "Subcategory (optional)",
                          prefixIcon: Icon(Icons.subdirectory_arrow_right),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _subcategories[_category]!
                            .map((sub) => DropdownMenuItem(
                                  value: sub,
                                  child: Text(sub),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _subcategory = value;
                          });
                        },
                      ),
                    if (_subcategories[_category] != null && _subcategories[_category]!.isNotEmpty)
                      SizedBox(height: 16),
                    
                    // Overall Supplier (dropdown)
                    DropdownButtonFormField<String>(
                      value: _selectedSupplier,
                      decoration: InputDecoration(
                        labelText: "Supplier (optional)",
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        'Sabasun',
                        'ECO',
                        'Mydin',
                        'Shopee',
                        'Kedai Plastik Buluh Gading',
                      ].map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSupplier = value;
                          _supplierController.text = value ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Items Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Items",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle),
                          onPressed: _addItem,
                          tooltip: 'Add Item',
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Items List
                    ...List.generate(_items.length, (index) {
                      final item = _items[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Item ${index + 1}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_items.length > 1)
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeItem(index),
                                    ),
                                ],
                              ),
                              SizedBox(height: 12),
                              // Item Name - Show subcategories if available, otherwise text field
                              if (_subcategories[_category] != null && _subcategories[_category]!.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    final currentValue = item.itemNameController.text.trim();
                                    final isValidSubcategory = _subcategories[_category]!.contains(currentValue);
                                    return DropdownButtonFormField<String>(
                                      value: currentValue.isEmpty || !isValidSubcategory 
                                          ? null 
                                          : currentValue,
                                      decoration: InputDecoration(
                                        labelText: "Item Name",
                                        prefixIcon: Icon(Icons.shopping_bag),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      items: _subcategories[_category]!
                                          .map((sub) => DropdownMenuItem(
                                                value: sub,
                                                child: Text(sub),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          item.itemNameController.text = value ?? '';
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                )
                              else
                                CustomTextField(
                                  controller: item.itemNameController,
                                  label: "Item Name",
                                  prefixIcon: Icons.shopping_bag,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: item.quantityController,
                                      label: "Quantity",
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      prefixIcon: Icons.numbers,
                                      onChanged: (_) => _calculateItemTotal(index),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: item.priceController,
                                      label: "Price per Item",
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      prefixIcon: Icons.attach_money,
                                      onChanged: (_) => _calculateItemTotal(index),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              CustomTextField(
                                controller: item.totalController,
                                label: "Total Cost",
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                prefixIcon: Icons.calculate,
                                enabled: false,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    SizedBox(height: 16),
                    // Overall Total
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Overall Total:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "RM ${overallTotal.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Save Button
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveExpense,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text("Save Expense"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseItemData {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController totalController = TextEditingController();

  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    totalController.dispose();
  }
}
