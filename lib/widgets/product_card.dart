import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';
import '../utils/price_calculator.dart';
import 'svg_icon.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

  const ProductCard({
    Key? key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.onToggleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null && !product.imageUrl!.startsWith('assets/')
                    ? Image.file(
                        File(product.imageUrl!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                          );
                        },
                      )
                    : Image.asset(
                        product.imageUrl ?? 'assets/images/placeholder.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                          );
                        },
                      ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (product.description != null && product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getVariantColor(product.variant),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.variant, // Display series name (Tiramisu or Cheesekut)
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getSeriesTextColor(product.variant),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (!product.isActive) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'INACTIVE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      PriceCalculator.formatPrice(product.price),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.cost > 0)
                      Text(
                        'Cost: ${PriceCalculator.formatPrice(product.cost)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null || onToggleStatus != null) ...[
                SizedBox(width: 8),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            SvgIcon(
                              assetPath: 'assets/icons/edit-icon.svg',
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onToggleStatus != null)
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              product.isActive ? Icons.block : Icons.check_circle,
                              size: 20,
                              color: product.isActive ? Colors.orange : Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              product.isActive ? 'Deactivate' : 'Activate',
                              style: TextStyle(color: product.isActive ? Colors.orange : Colors.green),
                            ),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            SvgIcon(
                              assetPath: 'assets/icons/delete-icon.svg',
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (value == 'toggle' && onToggleStatus != null) {
                      onToggleStatus!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getVariantColor(String variant) {
    // Check if variant stores series (Tiramisu or Cheesekut)
    if (variant == 'Tiramisu') {
      return Color(0xFF783D2E); // Brown color
    } else if (variant == 'Cheesekut') {
      return Color(0xFFF5E6D3); // Cream color
    }
    // Fallback for old variant values
    switch (variant) {
      case 'normal':
        return Colors.blue;
      case 'small':
        return Colors.green;
      case 'combo':
      case 'combo_small':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getSeriesTextColor(String variant) {
    // Text color should contrast with background
    if (variant == 'Tiramisu') {
      return Colors.white; // White text on brown background
    } else if (variant == 'Cheesekut') {
      return Color(0xFF783D2E); // Brown text on cream background
    }
    // Fallback
    return Colors.white;
  }
}

