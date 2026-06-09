import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 52),
              const SizedBox(height: 12),
              Text('Cart', style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Your cart view is ready for the next checkout step.', style: GoogleFonts.dmSans(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
