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
        title: Text("Daily Summary"),
        elevation: 0,
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
          // Enhanced Date Display with gradient background
          if (_viewMode == 'today')
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    Colors.orange[50]!,
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
          
          // Enhanced View Mode Toggle with segmented control style
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
                    isSelected: _viewMode == 'today',
                    onTap: () => setState(() => _viewMode = 'today'),
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildSegmentedButton(
                    label: 'All Time',
                    isSelected: _viewMode == 'all',
                    onTap: () => setState(() => _viewMode = 'all'),
                    color: Colors.teal,
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading summary...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        SizedBox(height: 16),
                        Text(
                          'Error loading data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
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
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Summary Cards with better spacing
                      _buildSummaryCard(
                        "Orders",
                        "${summary.totalOrders}",
                        Icons.receipt_long_rounded,
                        Colors.blue,
                      ),
                      SizedBox(height: 12),
                      _buildSummaryCard(
                        "Pieces Sold",
                        "${summary.totalPcs}",
                        Icons.shopping_bag_rounded,
                        Colors.green,
                      ),
                      SizedBox(height: 12),
                      _buildSummaryCard(
                        "Revenue",
                        PriceCalculator.formatPrice(summary.totalRevenue),
                        Icons.trending_up_rounded,
                        Colors.green,
                      ),
                      SizedBox(height: 12),
                      _buildSummaryCard(
                        "Expenses",
                        PriceCalculator.formatPrice(summary.totalExpenses),
                        Icons.money_off_rounded,
                        Colors.orange,
                      ),
                      SizedBox(height: 12),
                      // Prominent Net Profit Card
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: summary.netProfit >= 0
                                ? [Colors.green[400]!, Colors.green[600]!]
                                : [Colors.red[400]!, Colors.red[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (summary.netProfit >= 0 ? Colors.green : Colors.red)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Net Profit",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.95),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  PriceCalculator.formatPrice(summary.netProfit),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              summary.netProfit >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Flavor Count Section with enhanced design
                      if (summary.flavorCount.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pie_chart_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Flavor Breakdown",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: (() {
                                final sortedEntries = summary.flavorCount.entries.toList()
                                  ..sort((a, b) => b.value.compareTo(a.value));
                                return sortedEntries.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final flavorEntry = entry.value;
                                  return Column(
                                    children: [
                                      FlavorCountTile(
                                        flavor: flavorEntry.key,
                                        count: flavorEntry.value,
                                      ),
                                      if (index < sortedEntries.length - 1)
                                        Divider(height: 1, thickness: 1),
                                    ],
                                  );
                                }).toList();
                              })(),
                            ),
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

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}