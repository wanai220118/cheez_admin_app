import 'package:flutter/material.dart';

class FlavorCountTile extends StatelessWidget {
  final String flavor;
  final int count;

  const FlavorCountTile({
    Key? key,
    required this.flavor,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(flavor),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count pcs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange[900],
          ),
        ),
      ),
    );
  }
}

