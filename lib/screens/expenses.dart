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
  int _selectedTab = 0;

  void _confirmDelete(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Expense'),
          ],
        ),
        content: Text('Are you sure you want to delete this expense entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _fs.deleteExpense(expense.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Expense deleted");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Expenses"),
        elevation: 0,
        actions: [
          if (_selectedTab == 0)
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
            icon: Icon(Icons.add_circle_rounded),
            onPressed: () => NavigationHelper.navigateWithBounce(context, AddExpenseScreen()),
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Date Display (only for Today tab)
          if (_selectedTab == 0)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    Colors.red[50]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.getRelativeDate(_selectedDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        DateFormatter.formatDate(_selectedDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 1,
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            SvgIcon(
                              assetPath: 'assets/icons/calendar-icon.svg',
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
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
          
          // Enhanced Tab Selection
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentedButton(
                    label: 'Today',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildSegmentedButton(
                    label: 'All Time',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _selectedTab == 0
                  ? _fs.getExpensesByDate(_selectedDate)
                  : _fs.getAllExpenses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading expenses...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                
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
                
                final sortedCategoryEntries = categoryExpenses.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topCategories = sortedCategoryEntries.take(3).toList();
                
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Enhanced Summary Card
                      SmoothReveal(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red[50]!, Colors.red[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red[200]!, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red[700],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Expenses Summary",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryItem(
                                        "Total Expenses",
                                        PriceCalculator.formatPrice(totalCost),
                                        Icons.trending_down_rounded,
                                        Colors.red,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        "Categories",
                                        "${categoryExpenses.length}",
                                        Icons.category_rounded,
                                        Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                if (topCategories.isNotEmpty) ...[
                                  SizedBox(height: 20),
                                  Divider(color: Colors.red[300]),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bar_chart_rounded,
                                        color: Colors.red[700],
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Top 3 Categories",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  ...topCategories.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final cat = entry.value;
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: index == 0
                                                    ? [Colors.amber[400]!, Colors.amber[600]!]
                                                    : index == 1
                                                    ? [Colors.grey[400]!, Colors.grey[600]!]
                                                    : [Colors.brown[400]!, Colors.brown[600]!],
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '#${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              cat.key.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              PriceCalculator.formatPrice(cat.value),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[900],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Expenses List Header
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "All Expenses",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${expenses.length} items",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Expense Cards
                      ...expenses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final e = entry.value;
                        return SmoothReveal(
                          delay: Duration(milliseconds: index * 50),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
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
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  NavigationHelper.selectionClick();
                                  NavigationHelper.navigateWithBounce(
                                    context,
                                    AddExpenseScreen(existingExpense: e),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: SvgIcon(
                                          assetPath: 'assets/icons/expenses-icon.svg',
                                          size: 24,
                                          color: Colors.red[700]!,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.category.toUpperCase() + 
                                              (e.subcategory != null ? ' - ${e.subcategory}' : ''),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.shopping_basket_rounded, 
                                                     size: 14, 
                                                     color: Colors.grey[600]),
                                                SizedBox(width: 4),
                                                Text(
                                                  "${e.items.length} item(s)",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                if (e.supplier != null) ...[
                                                  SizedBox(width: 8),
                                                  Icon(Icons.store_rounded, 
                                                       size: 14, 
                                                       color: Colors.grey[600]),
                                                  SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      e.supplier!,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            PriceCalculator.formatPrice(e.totalCost),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.delete_rounded,
                                              size: 18,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => NavigationHelper.navigateWithBounce(context, AddExpenseScreen()),
        icon: Icon(Icons.add_rounded),
        label: Text('Add Expense'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSegmentedButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}