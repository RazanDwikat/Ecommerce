import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 52),
              const SizedBox(height: 12),
              Text('Orders', style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('This section will list the user’s recent orders.', style: GoogleFonts.dmSans(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
