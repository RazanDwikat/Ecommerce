import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _reviews = [];
      });
      return;
    }

    try {
      setState(() => _loading = true);
      
      // Get all products first
      final productsResponse = await _apiService.getAllProductsAdmin(token);
      final products = productsResponse['products'] as List<dynamic>? ?? [];
      
      // Load reviews for each product
      List<dynamic> allReviews = [];
      for (var product in products) {
        final productId = product['_id'].toString();
        try {
          final reviewsResponse = await _apiService.getProductReviews(productId);
          final reviews = reviewsResponse['reviews'] as List<dynamic>? ?? [];
          for (var review in reviews) {
            allReviews.add({
              ...review,
              'productName': product['name'],
              'productId': productId,
            });
          }
        } catch (e) {
          // Skip if reviews can't be loaded for this product
        }
      }

      if (!mounted) return;

      setState(() {
        _reviews = allReviews;
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

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.deleteReviewAdmin(token, reviewId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully')),
      );
      _loadReviews();
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
        title: Text('Reviews Management', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadReviews,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _reviews.isEmpty
                  ? _buildEmptyState()
                  : _buildReviewsList(),
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
          Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Reviews',
            style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'No reviews have been submitted yet',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index] as Map<String, dynamic>;
        return _ReviewCard(
          review: review,
          onDelete: () => _deleteReview(review['_id'].toString()),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final user = review['user'] as Map<String, dynamic>? ?? {};
    final userName = user['name'] as String? ?? 'Anonymous';
    final productName = review['productName'] as String? ?? 'Unknown Product';
    final createdAt = review['createdAt'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.skyBlue,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        productName,
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comment,
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  color: AppColors.error,
                ),
              ],
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
