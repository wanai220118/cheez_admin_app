import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/summary_service.dart';
import '../models/daily_summary.dart';
import '../widgets/empty_state.dart';
import '../widgets/flavor_count_tile.dart';
import '../widgets/svg_icon.dart';
import '../utils/date_formatter.dart';
import '../utils/price_calculator.dart';

class DailySummaryScreen extends StatefulWidget {
  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  final FirestoreService _fs = FirestoreService();
  final SummaryService _summaryService = SummaryService();
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'today'; // 'today', 'all'
  bool _isLoading = false;

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
        title: Text("Daily Summary"),
        actions: [
          if (_viewMode == 'today')
            IconButton(
              icon: SvgIcon(
                assetPath: 'assets/icons/calendar-icon.svg',
                size: 24,
                color: Colors.white,
              ),
              onPressed: () => _selectDate(context),
              tooltip: 'Select Date',
            ),
        ],
      ),
      body: Column(
        children: [
          // Date Display (only show when in 'today' mode)
          if (_viewMode == 'today')
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
          // View Mode Toggle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Today'),
                    selected: _viewMode == 'today',
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: _viewMode == 'today' ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _viewMode = 'today');
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('All Time'),
                    selected: _viewMode == 'all',
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: _viewMode == 'all' ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _viewMode = 'all');
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<DailySummary>(
              future: _viewMode == 'today'
                  ? _summaryService.generateDailySummary(_selectedDate)
                  : _summaryService.generateAllTimeSummary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return EmptyState(
                    message: _viewMode == 'today'
                        ? "No data for ${DateFormatter.formatDate(_selectedDate)}"
                        : "No data available",
                    iconPath: 'assets/icons/summary-icon.svg',
                  );
                }
                final summary = snapshot.data!;
                if (summary.totalOrders == 0 && summary.flavorCount.isEmpty) {
                  return EmptyState(
                    message: _viewMode == 'today'
                        ? "No orders for ${DateFormatter.formatDate(_selectedDate)}"
                        : "No orders recorded",
                    iconPath: 'assets/icons/summary-icon.svg',
                  );
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              "Orders",
                              "${summary.totalOrders}",
                              Icons.receipt_long,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              "Pieces",
                              "${summary.totalPcs}",
                              Icons.shopping_bag,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              "Revenue",
                              PriceCalculator.formatPrice(summary.totalRevenue),
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              "Expenses",
                              PriceCalculator.formatPrice(summary.totalExpenses),
                              Icons.money_off,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildSummaryCard(
                        "Net Profit",
                        PriceCalculator.formatPrice(summary.netProfit),
                        Icons.account_balance_wallet,
                        summary.netProfit >= 0 ? Colors.green : Colors.red,
                        isLarge: true,
                      ),
                      SizedBox(height: 24),
                      // Flavor Count Section
                      if (summary.flavorCount.isNotEmpty) ...[
                        Text(
                          "Flavor Breakdown",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Card(
                          child: Column(
                            children: (() {
                              final sortedEntries = summary.flavorCount.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value));
                              return sortedEntries.map((entry) => FlavorCountTile(
                                    flavor: entry.key,
                                    count: entry.value,
                                  )).toList();
                            })(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, {bool isLarge = false}) {
    Color textColor;
    if (color is MaterialColor) {
      textColor = color[900]!;
    } else {
      textColor = color;
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isLarge ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
