import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _orders = [];
      });
      return;
    }

    try {
      setState(() => _loading = true);
      final response = await _apiService.getAllOrdersAdmin(token);
      setState(() {
        _orders = response['orders'] as List<dynamic>? ?? [];
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

  Future<void> _showStatusDialog(Map<String, dynamic> order) async {
    final currentStatus = order['status'] as String? ?? 'pending';
    final statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => _StatusDialog(
        currentStatus: currentStatus,
        statuses: statuses,
      ),
    );

    if (newStatus != null && mounted) {
      await _updateOrderStatus(order['_id'].toString(), newStatus);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.updateOrderStatus(token, orderId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $status')),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Orders Management', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _orders.isEmpty
                  ? _buildEmptyState()
                  : _buildOrdersList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Orders',
            style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'No orders have been placed yet',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index] as Map<String, dynamic>;
        return _OrderCard(
          order: order,
          onUpdateStatus: () => _showStatusDialog(order),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.statusPending;
      case 'processing':
        return AppColors.statusProcessing;
      case 'shipped':
        return AppColors.statusShipped;
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
        return AppColors.statusCancelled;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.paymentPaid;
      case 'pending':
        return AppColors.paymentPending;
      case 'failed':
        return AppColors.paymentFailed;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final paymentStatus = order['paymentStatus'] as String? ?? 'pending';
    final totalPrice = (order['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final items = order['items'] as List<dynamic>? ?? [];
    final user = order['user'] as Map<String, dynamic>? ?? {};
    final createdAt = order['createdAt'] as String? ?? '';

    final statusColor = _getStatusColor(status);
    final paymentStatusColor = _getPaymentStatusColor(paymentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        'Order #${order['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer: ${user['name'] as String? ?? 'Unknown'}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Email: ${user['email'] as String? ?? 'Unknown'}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${items.length} item${items.length != 1 ? 's' : ''}',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final itemData = item as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${itemData['name'] ?? 'Product'}',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            'x${itemData['quantity'] ?? 1}',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Status',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: paymentStatusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          paymentStatus.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: paymentStatusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Price',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  createdAt.isNotEmpty ? _formatDate(createdAt) : '',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpdateStatus,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Update Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.steelBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _StatusDialog extends StatelessWidget {
  final String currentStatus;
  final List<String> statuses;

  const _StatusDialog({
    required this.currentStatus,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Order Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: statuses.map((status) {
          return RadioListTile<String>(
            title: Text(status.toUpperCase()),
            value: status,
            groupValue: currentStatus,
            onChanged: (value) {
              Navigator.pop(context, value);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
