import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

// =============================================================
// CART SCREEN
// ===============================                                                                                  ==============================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // ── Load Cart ─────────────────────────────────────────────
  Future<void> _loadCart() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _items = [];
        _total = 0;
      });
      return;
    }
    try {
      setState(() => _loading = true);
      final response = await _apiService.getCart(token);
      final cart = response['cart'] ?? {};
      final items = (cart['items'] as List<dynamic>?) ?? [];
      setState(() {
        _items = items;
        _total = (cart['totalPrice'] ?? 0).toDouble();
        _error = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Update / Remove ───────────────────────────────────────
  Future<void> _updateQuantity(String productId, int quantity) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.updateQuantity(token, productId, quantity);
      await _loadCart();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _removeItem(String productId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.removeFromCart(token, productId);
      await _loadCart();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  // ── Place Order ───────────────────────────────────────────
  Future<void> _placeOrder() async {
    print('[CART] Place order clicked');
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      print('[CART] No token found');
      _showSnack('Please log in first to place an order.');
      return;
    }
    print('[CART] Token found');

    final method = await _showPaymentMethodDialog();
    print('[CART] Payment method selected: $method');
    if (method == null || !mounted) return;

    try {
      print('[CART] Creating order...');
      final orderRes = await _apiService.createOrder(token);
      final orderId = orderRes['order']['_id'] as String;
      print('[CART] Order created: $orderId');

      if (method == 'cash') {
        print('[CART] Processing cash payment...');
        await _apiService.createPayment(token, orderId, 'cash');
        await _loadCart();
        if (!mounted) return;
        _showSnack('Order placed! Payment on delivery.');
      } else {
        print('[CART] Processing stripe payment...');
        final payRes =
            await _apiService.createPayment(token, orderId, 'stripe');
        final paymentIntentId = payRes['paymentIntentId'] as String;
        final amount = orderRes['order']['totalPrice'] as num;
        print('[CART] Payment intent created: $paymentIntentId, amount: $amount');
        if (!mounted) return;
        await _showStripeFormDialog(
          token: token,
          paymentIntentId: paymentIntentId,
          amount: amount.toDouble(),
        );
      }
    } catch (e) {
      print('[CART] Error: $e');
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Payment Method Bottom Sheet ───────────────────────────
  Future<String?> _showPaymentMethodDialog() {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose payment method',
              style: GoogleFonts.dmSans(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'How would you like to pay for your order?',
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            PaymentOptionTile(
              icon: Icons.payments_outlined,
              title: 'Cash on Delivery',
              subtitle: 'Pay when you receive your order',
              iconColor: AppColors.success,
              onTap: () => Navigator.pop(ctx, 'cash'),
            ),
            
            const SizedBox(height: 12),
            PaymentOptionTile(
              icon: Icons.credit_card_outlined,
              title: 'Credit Card',
              subtitle: 'Secure online payment',
              iconColor: AppColors.stripe,
               onTap: () => Navigator.pop(ctx, 'stripe'),
            ),
          ],
        ),
      ),
    );
  } // <-- closing brace for _showPaymentMethodDialog

  // ── Stripe Dialog ─────────────────────────────────────────
  Future<void> _showStripeFormDialog({
    required String token,
    required String paymentIntentId,
    required double amount,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StripeFormDialog(
        apiService: _apiService,
        token: token,
        paymentIntentId: paymentIntentId,
        amount: amount,
        onSuccess: () async {
          await _loadCart();
          if (!mounted) return;
          _showSnack('Payment successful! Your order is being processed.');
        },
        onFailure: (String reason) {
          _showSnack('Payment failed: $reason');
        },
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Helpers ───────────────────────────────────────────────
  String _productImage(dynamic product) {
    if (product is Map<String, dynamic>) {
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        final image = images.first.toString();
        return image.startsWith('http') ? image : 'http://localhost:3000$image';
      }
    }
    return 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=600&q=80';
  }

  double _productPrice(dynamic product) {
    if (product is Map<String, dynamic>) {
      final price = product['price'];
      return price is num ? price.toDouble() : 0.0;
    }
    return 0.0;
  }

  String _productName(dynamic product) {
    if (product is Map<String, dynamic>) {
      return product['name']?.toString() ?? 'Product';
    }
    return 'Product';
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Cart'),
 
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              onPressed: () async {
                final token = auth.token;
                if (token == null) return;
                await _apiService.clearCart(token);
                await _loadCart();
              },
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : auth.token == null
              ? _emptyState('Please log in to see your cart.')
              : _error != null
                  ? _emptyState(_error!, isError: true)
                  : _items.isEmpty
                      ? _emptyState(
                          'Your cart is empty. Add some products from the home screen.')
                      : _buildCartView(),
    );
  }

  Widget _emptyState(String message, {bool isError = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 54,
                color: isError ? AppColors.error : AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Cart',
                style: GoogleFonts.dmSans(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Your selected items',
            style: GoogleFonts.dmSans(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ..._items.map((item) {
          final product = item['product'];
          final quantity = item['quantity'] as int? ?? 1;
          final price = _productPrice(product) * quantity;

          return Card(
            color: AppColors.white,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _productImage(product),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.surfaceAlt.withOpacity(0.3),
                        child:
                            const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_productName(product),
                            style: GoogleFonts.dmSans(
                                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                            'Price: \$${_productPrice(product).toStringAsFixed(2)}',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: quantity > 1
                                  ? () => _updateQuantity(
                                      product['_id'], quantity - 1)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$quantity',
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            IconButton(
                              onPressed: () => _updateQuantity(
                                  product['_id'], quantity + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            Text('\$${price.toStringAsFixed(2)}',
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeItem(product['_id']),
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Card(
          color: AppColors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order summary',
                    style: GoogleFonts.dmSans(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary)),
                      Text('\$${_total.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700)),
                    ]),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary)),
                      Text('Free',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                    ]),
                const Divider(height: 24, color: AppColors.divider),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('\$${_total.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _placeOrder,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Place order'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} // <-- closing brace for _CartScreenState

// =============================================================
// PAYMENT OPTION TILE
// NOTE: public name (no underscore) so it can be used
//       inside the builder callback of showModalBottomSheet
//       which runs in a different widget tree scope.
// =============================================================
class PaymentOptionTile extends StatelessWidget {
  const PaymentOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// STRIPE SIMULATION FORM DIALOG
// =============================================================
class StripeFormDialog extends StatefulWidget {
  const StripeFormDialog({
    super.key,
    required this.apiService,
    required this.token,
    required this.paymentIntentId,
    required this.amount,
    required this.onSuccess,
    required this.onFailure,
  });

  final ApiService apiService;
  final String token;
  final String paymentIntentId;
  final double amount;
  final VoidCallback onSuccess;
  final void Function(String reason) onFailure;

  @override
  State<StripeFormDialog> createState() => _StripeFormDialogState();
}

class _StripeFormDialogState extends State<StripeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedScenario = 'pm_card_visa';
  bool _processing = false;
  String? _resultMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    print('[STRIPE] Submit payment clicked');
    if (!_formKey.currentState!.validate()) {
      print('[STRIPE] Form validation failed');
      return;
    }

    setState(() {
      _processing = true;
      _resultMessage = null;
    });

    try {
      print('[STRIPE] Calling simulatePayment with intent: ${widget.paymentIntentId}');
      final result = await widget.apiService.simulatePayment(
        widget.token,
        widget.paymentIntentId,
        paymentMethod: _selectedScenario,
      );
      print('[STRIPE] simulatePayment result: $result');

      final status = result['paymentIntentStatus'] as String? ?? '';
      print('[STRIPE] Payment intent status: $status');
      if (!mounted) return;

      if (status == 'succeeded') {
        setState(() {
          _processing = false;
          _isSuccess = true;
          _resultMessage = 'Payment successful!';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        setState(() {
          _processing = false;
          _isSuccess = false;
          _resultMessage = 'Payment was declined. Please try again.';
        });
        widget.onFailure('Card declined');
      }
    } catch (e) {
      print('[STRIPE] Error: $e');
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _processing = false;
        _isSuccess = false;
        _resultMessage = msg;
      });
      widget.onFailure(msg);
    }
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.stripe, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      filled: true,
      fillColor: AppColors.inputFill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stripeColor = AppColors.stripe;

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: stripeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.credit_card,
                          color:Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stripe Payment',
                              style: GoogleFonts.dmSans(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text('Simulator mode',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.stripe,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _processing ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Amount chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Amount: \$${widget.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),

                // Cardholder name
                Text('Cardholder Name',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Name on card'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Card number
                Text('Card Number',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: _inputDecoration('1234 5678 9012 3456',
                      suffix: const Icon(Icons.credit_card_outlined,
                          size: 20, color: AppColors.textHint)),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    CardNumberFormatter(),
                  ],
                  validator: (v) {
                    final digits = v?.replaceAll(' ', '') ?? '';
                    if (digits.length < 16) {
                      return 'Enter a valid card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Expiry + CVV
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expiry',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _expiryController,
                            decoration: _inputDecoration('MM/YY'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              ExpiryFormatter(),
                            ],
                            validator: (v) =>
                                (v == null || v.length < 5) ? 'Invalid' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CVV',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _cvvController,
                            decoration: _inputDecoration('123'),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (v) =>
                                (v == null || v.length < 3) ? 'Invalid' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Simulator scenario picker
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.5),
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.science_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Simulator — Test Scenario',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      ScenarioChip(
                        label: 'Success (Visa)',
                        selected: _selectedScenario == 'pm_card_visa',
                        onTap: () =>
                            setState(() => _selectedScenario = 'pm_card_visa'),
                      ),
                      const SizedBox(height: 6),
                      ScenarioChip(
                        label: 'Declined',
                        selected: _selectedScenario == 'pm_card_visa_decline',
                        onTap: () => setState(
                            () => _selectedScenario = 'pm_card_visa_decline'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Result message
                if (_resultMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSuccess
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      border: Border.all(
                          color: _isSuccess
                              ? AppColors.success
                              : AppColors.error),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(
                        _isSuccess
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _isSuccess ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resultMessage!,
                          style: GoogleFonts.dmSans(
                            color: _isSuccess
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pay button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _processing ? null : _submitPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.stripe,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _processing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Pay \$${widget.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.dmSans(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Branding note
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text('Powered by Stripe (Simulator)',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// SCENARIO CHIP
// =============================================================
class ScenarioChip extends StatelessWidget {
  const ScenarioChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight.withOpacity(0.3) : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 16,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// TEXT INPUT FORMATTERS
// =============================================================
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final formatted =
        '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
