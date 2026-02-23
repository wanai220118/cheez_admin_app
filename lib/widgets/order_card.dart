import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/date_formatter.dart';
import '../utils/price_calculator.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final Function(bool)? onStatusChanged;
  final VoidCallback? onDelete;

  const OrderCard({
    Key? key,
    required this.order,
    this.onTap,
    this.onStatusChanged,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompleted = order.status == 'completed';

    int pcs = order.displayTotalPcs;
    order.comboPacks.forEach((_, allocation) {
      allocation.forEach((_, quantity) {
        pcs += quantity;
      });
    });

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isCompleted ? 1 : 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          order.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green[900] : Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        '$pcs pcs',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Text(
                    PriceCalculator.formatPrice(order.totalPrice),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                DateFormatter.formatDateTime(order.orderDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              if (onStatusChanged != null || onDelete != null) ...[
                SizedBox(height: 12),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (onStatusChanged != null)
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              'Mark as completed',
                              style: TextStyle(fontSize: 14),
                            ),
                            Switch(
                              value: isCompleted,
                              onChanged: (value) {
                                if (onStatusChanged != null) {
                                  onStatusChanged!(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                        tooltip: 'Delete order',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

