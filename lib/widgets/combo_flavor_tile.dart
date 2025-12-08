import 'package:flutter/material.dart';

class ComboFlavorTile extends StatelessWidget {
  final String flavor;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const ComboFlavorTile({
    Key? key,
    required this.flavor,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(flavor),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline),
              onPressed: quantity > 0 ? onDecrement : null,
              color: Colors.red,
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: onIncrement,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

