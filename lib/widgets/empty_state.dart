import 'package:flutter/material.dart';
import 'svg_icon.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? iconPath;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    Key? key,
    required this.message,
    this.icon,
    this.iconPath,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              SvgIcon(
                assetPath: iconPath!,
                size: 64,
                color: Colors.grey[400],
              )
            else
              Icon(
                icon ?? Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

