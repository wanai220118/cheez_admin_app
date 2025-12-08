import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../utils/date_formatter.dart';
import '../utils/price_calculator.dart';
import '../utils/navigation_helper.dart';
import '../widgets/smooth_reveal.dart';
import 'add_expense.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final FirestoreService _fs = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  int _selectedTab = 0; // 0 = Today, 1 = All

  void _confirmDelete(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _fs.deleteExpense(expense.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Expense deleted");
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expenses"),
        actions: [
          IconButton(
            icon: SvgIcon(
              assetPath: 'assets/icons/calendar-icon.svg',
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: SvgIcon(
              assetPath: 'assets/icons/add-icon.svg',
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => NavigationHelper.navigateWithBounce(context, AddExpenseScreen()),
          )
        ],
      ),
      body: Column(
        children: [
          // Tab Selection
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Today'),
                    selected: _selectedTab == 0,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: _selectedTab == 0 ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTab = 0);
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('All Expenses'),
                    selected: _selectedTab == 1,
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: _selectedTab == 1 ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTab = 1);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_selectedTab == 0) ...[
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.orange[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.getRelativeDate(_selectedDate),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: SvgIcon(
                      assetPath: 'assets/icons/calendar-icon.svg',
                      size: 20,
                    ),
                    label: Text('Change Date'),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _selectedTab == 0
                  ? _fs.getExpensesByDate(_selectedDate)
                  : _fs.getAllExpenses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final expenses = snapshot.data!;
                if (expenses.isEmpty) {
                  return SmoothReveal(
                    child: EmptyState(
                      message: _selectedTab == 0
                          ? "No expenses for ${DateFormatter.formatDate(_selectedDate)}"
                          : "No expenses recorded",
                      iconPath: 'assets/icons/expenses-icon.svg',
                      actionLabel: "Add Expense",
                      onAction: () => NavigationHelper.navigateWithBounce(context, AddExpenseScreen()),
                    ),
                  );
                }
                double totalCost = expenses.fold(0.0, (sum, e) => sum + e.totalCost);
                
                // Calculate expenses by category
                Map<String, double> categoryExpenses = {};
                for (var expense in expenses) {
                  categoryExpenses[expense.category] = 
                      (categoryExpenses[expense.category] ?? 0.0) + expense.totalCost;
                }
                
                // Sort categories by amount (descending) to get top 3
                final sortedCategoryEntries = categoryExpenses.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topCategories = sortedCategoryEntries.take(3).toList();
                
                return Column(
                  children: [
                    // Summary Widget
                    SmoothReveal(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Expenses Summary",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Expenses",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      PriceCalculator.formatPrice(totalCost),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[900],
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Categories",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "${categoryExpenses.length}",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (topCategories.isNotEmpty) ...[
                              SizedBox(height: 12),
                              Divider(),
                              SizedBox(height: 8),
                              Text(
                                "Top 3 Categories",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Column(
                                children: topCategories.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final cat = entry.value;
                                  final rank = index + 1;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "$rank.",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[900],
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              cat.key.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          PriceCalculator.formatPrice(cat.value),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final e = expenses[index];
                          return SmoothReveal(
                            delay: Duration(milliseconds: index * 50),
                            child: Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: SvgIcon(
                                  assetPath: 'assets/icons/expenses-icon.svg',
                                  size: 24,
                                  color: Colors.red[700],
                                ),
                                title: Text(
                                  e.category.toUpperCase() + (e.subcategory != null ? ' - ${e.subcategory}' : ''),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "${e.items.length} item(s)${e.supplier != null ? ' • ${e.supplier}' : ''}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      PriceCalculator.formatPrice(e.totalCost),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[900],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Delete expense',
                                      onPressed: () {
                                        NavigationHelper.selectionClick();
                                        _confirmDelete(context, e);
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  NavigationHelper.selectionClick();
                                  NavigationHelper.navigateWithBounce(
                                    context,
                                    AddExpenseScreen(existingExpense: e),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
