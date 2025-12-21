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
  
  String _category = 'expense';
  String? _subcategory;
  DateTime _expenseDate = DateTime.now();
  final _supplierController = TextEditingController();
  String? _selectedSupplier;
  final List<String> _commonSuppliers = [
    'Sabasun',
    'ECO',
    'Mydin',
    'Shopee',
    'Kedai Plastik Buluh Gading',
    'TikTok',
  ];
  
  List<ExpenseItemData> _items = [ExpenseItemData()];
  
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
    final existing = widget.existingExpense;
    if (existing != null) {
      _category = existing.category;
      _subcategory = existing.subcategory;
      _expenseDate = existing.date;
      _supplierController.text = existing.supplier ?? '';
      _selectedSupplier = existing.supplier;

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _expenseDate) {
      setState(() {
        _expenseDate = picked;
        _subcategory = null;
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
    } else {
      Fluttertoast.showToast(msg: "At least one item is required");
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isEdit ? "Edit Expense" : "Add Expense"),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildSectionHeader(
                      icon: Icons.info_rounded,
                      title: "Expense Details",
                      color: Colors.blue,
                    ),
                    SizedBox(height: 12),
                    
                    // Date, Category, Subcategory, Supplier in Card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Date Picker
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: Colors.blue[700]),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Expense Date",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          DateFormat('dd MMM yyyy').format(_expenseDate),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Category
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: InputDecoration(
                              labelText: "Category",
                              prefixIcon: Icon(Icons.category_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
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
                                _subcategory = null;
                                for (var item in _items) {
                                  item.itemNameController.clear();
                                }
                              });
                            },
                          ),
                          
                          // Subcategory (if available)
                          if (_subcategories[_category] != null && _subcategories[_category]!.isNotEmpty) ...[
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _subcategory,
                              decoration: InputDecoration(
                                labelText: "Subcategory (optional)",
                                prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
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
                          ],
                          SizedBox(height: 16),
                          
                          // Supplier
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _supplierController,
                                  label: "Supplier (optional)",
                                  prefixIcon: Icons.store_rounded,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSupplier = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                                  tooltip: 'Select common supplier',
                                  onSelected: (value) {
                                    setState(() {
                                      _selectedSupplier = value;
                                      _supplierController.text = value;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  itemBuilder: (context) => _commonSuppliers.map((supplier) {
                                    return PopupMenuItem(
                                      value: supplier,
                                      child: Row(
                                        children: [
                                          Icon(Icons.store_rounded, size: 18, color: Colors.grey[600]),
                                          SizedBox(width: 12),
                                          Text(supplier),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Items Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_basket_rounded, color: Colors.orange[700], size: 24),
                            SizedBox(width: 8),
                            Text(
                              "Items",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add_rounded, color: Colors.white),
                            onPressed: _addItem,
                            tooltip: 'Add Item',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Items List
                    ...List.generate(_items.length, (index) {
                      final item = _items[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inventory_2_rounded, size: 16, color: Colors.orange[700]),
                                        SizedBox(width: 6),
                                        Text(
                                          "Item ${index + 1}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_items.length > 1)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.delete_rounded, color: Colors.red[700], size: 20),
                                        onPressed: () => _removeItem(index),
                                        tooltip: 'Remove item',
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 16),
                              
                              // Item Name - Dropdown or TextField
                              if (_subcategories[_category] != null && _subcategories[_category]!.isNotEmpty)
                                Column(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final currentValue = item.itemNameController.text.trim();
                                        final subcategoriesWithEtc = [..._subcategories[_category]!, 'etc.'];
                                        final isValidSubcategory = _subcategories[_category]!.contains(currentValue);
                                        final isEtcOrCustom = !isValidSubcategory && currentValue.isNotEmpty;
                                        
                                        return DropdownButtonFormField<String>(
                                          value: currentValue.isEmpty || isEtcOrCustom ? null : currentValue,
                                          decoration: InputDecoration(
                                            labelText: "Quick Select",
                                            prefixIcon: Icon(Icons.list_rounded),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                          items: subcategoriesWithEtc
                                              .map((sub) => DropdownMenuItem(
                                                    value: sub,
                                                    child: Text(sub),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == 'etc.') {
                                                item.itemNameController.text = '';
                                              } else if (value != null) {
                                                item.itemNameController.text = value;
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                    SizedBox(height: 12),
                                  ],
                                ),
                              CustomTextField(
                                controller: item.itemNameController,
                                label: "Item Name",
                                prefixIcon: Icons.edit_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter item name';
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
                                      label: "Qty",
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      prefixIcon: Icons.numbers_rounded,
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
                                      label: "Price",
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      prefixIcon: Icons.attach_money_rounded,
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
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calculate_rounded, size: 18, color: Colors.blue[700]),
                                        SizedBox(width: 8),
                                        Text(
                                          "Item Total:",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "RM ${item.totalController.text.isEmpty ? '0.00' : item.totalController.text}",
                                      style: TextStyle(
                                        fontSize: 16,
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
                      );
                    }),
                    
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            
            // Fixed Bottom Total Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[50]!, Colors.red[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Expense",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "RM ${overallTotal.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: saveExpense,
                          icon: Icon(widget.isEdit ? Icons.check_circle_rounded : Icons.save_rounded),
                          label: Text(
                            widget.isEdit ? "Update Expense" : "Save Expense",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
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