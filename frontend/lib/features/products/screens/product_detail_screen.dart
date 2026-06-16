import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/theme/app_colors.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProductItem product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  List<Review> _reviews = [];
  bool _loadingReviews = true;
  bool _showAllReviews = false;
  bool _hasPurchased = false;
  bool _checkingPurchase = false;
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _checkPurchaseStatus();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    final reviews = await ReviewService.getProductReviews(widget.product.id);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _loadingReviews = false;
    });
  }

  Future<void> _checkPurchaseStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (auth.token == null) {
      setState(() => _hasPurchased = false);
      return;
    }

    setState(() => _checkingPurchase = true);
    final hasPurchased = await ApiService().hasUserPurchasedProduct(auth.token!, widget.product.id);
    if (!mounted) return;
    setState(() {
      _hasPurchased = hasPurchased;
      _checkingPurchase = false;
    });
  }

  Future<void> _addToCart() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first to add items to cart.')),
      );
      return;
    }

    try {
      await ApiService().addToCart(auth.token!, widget.product.id, _quantity);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.product.name} added to cart x$_quantity')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _submitReview() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first to write a review.')),
      );
      return;
    }

    try {
      await ApiService().createReview(
        auth.token!,
        widget.product.id,
        _rating,
        _reviewController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );

      _reviewController.clear();
      setState(() => _rating = 5);
      _loadReviews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showReviewDialog() {
    if (!_hasPurchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must purchase this product before writing a review.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your experience with this product...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitReview();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayReviews = _showAllReviews ? _reviews : (_reviews.isEmpty ? [] : [_reviews.first]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(widget.product.name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Product Image
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.skyBlue.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: widget.product.imageUrl == null
                ? const Center(child: Icon(Icons.shopping_bag_outlined, size: 60, color: AppColors.textPrimary))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 60)),
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // Product Info
          Text(widget.product.name, style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(widget.product.category, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Text(
            widget.product.description,
            style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            '\$${widget.product.price.toStringAsFixed(2)}',
            style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),

          // Quantity Selector
          Row(
            children: [
              Text('Quantity:', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                      child: const Icon(Icons.remove, size: 20, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 16),
                    Text('$_quantity', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => setState(() => _quantity++),
                      child: const Icon(Icons.add, size: 20, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Add to Cart Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
              label: const Text('Add to Cart', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.steelBlue,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Reviews Section
          Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reviews (${_reviews.length})',
                      style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    if (_checkingPurchase)
                      const SizedBox(width: 16, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    else if (_hasPurchased)
                      TextButton.icon(
                        onPressed: _showReviewDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Write Review'),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Purchase to review',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loadingReviews)
                  const Center(child: CircularProgressIndicator())
                else if (_reviews.isEmpty)
                  Text(
                    'No reviews yet. Be the first to review!',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...displayReviews.map((review) => _ReviewCard(review: review)),
                      if (_reviews.length > 1 && !_showAllReviews)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton(
                            onPressed: () => setState(() => _showAllReviews = true),
                            child: Text(
                              'View More (${_reviews.length - 1} more)',
                              style: GoogleFonts.dmSans(color: AppColors.steelBlue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      if (_showAllReviews && _reviews.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton(
                            onPressed: () => setState(() => _showAllReviews = false),
                            child: Text(
                              'Show Less',
                              style: GoogleFonts.dmSans(color: AppColors.steelBlue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.skyBlue,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'A',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (review.createdAt != null)
                      Text(
                        _formatDate(review.createdAt!),
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
