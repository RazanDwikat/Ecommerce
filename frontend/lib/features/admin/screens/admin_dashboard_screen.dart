import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_categories_screen.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_reviews_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      setState(() => _loading = true);
      
      // Load categories count
      final categoriesResponse = await _apiService.getAllCategoriesAdmin(token);
      final categories = categoriesResponse['categories'] as List<dynamic>? ?? [];
      
      // Load products count
      final productsResponse = await _apiService.getAllProductsAdmin(token);
      final products = productsResponse['products'] as List<dynamic>? ?? [];
      
      // Load orders count
      final ordersResponse = await _apiService.getAllOrdersAdmin(token);
      final orders = ordersResponse['orders'] as List<dynamic>? ?? [];

      if (!mounted) return;

      setState(() {
        _stats = {
          'categories': categories.length,
          'products': products.length,
          'orders': orders.length,
          'pendingOrders': orders.where((o) => (o as Map)['status'] == 'pending').length,
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have admin privileges',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Admin Dashboard', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildMenuGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Categories',
          value: _stats['categories']?.toString() ?? '0',
          icon: Icons.category_outlined,
          color: AppColors.skyBlue,
        ),
        _StatCard(
          title: 'Products',
          value: _stats['products']?.toString() ?? '0',
          icon: Icons.inventory_2_outlined,
          color: AppColors.steelBlue,
        ),
        _StatCard(
          title: 'Total Orders',
          value: _stats['orders']?.toString() ?? '0',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.sand,
        ),
        _StatCard(
          title: 'Pending Orders',
          value: _stats['pendingOrders']?.toString() ?? '0',
          icon: Icons.pending_actions_outlined,
          color: AppColors.statusPending,
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _MenuCard(
              title: 'Categories',
              icon: Icons.category_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
                );
              },
            ),
            _MenuCard(
              title: 'Products',
              icon: Icons.inventory_2_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                );
              },
            ),
            _MenuCard(
              title: 'Orders',
              icon: Icons.shopping_bag_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                );
              },
            ),
            _MenuCard(
              title: 'Reviews',
              icon: Icons.rate_review_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReviewsScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.steelBlue),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
