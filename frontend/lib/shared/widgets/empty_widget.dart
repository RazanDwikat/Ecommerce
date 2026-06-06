import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  final String message;

  const EmptyWidget({super.key, this.message = 'No products found'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
