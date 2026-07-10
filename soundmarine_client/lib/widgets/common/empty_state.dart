import 'package:flutter/material.dart';

/// A centered empty-state placeholder with an icon and message.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[600], size: iconSize),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
