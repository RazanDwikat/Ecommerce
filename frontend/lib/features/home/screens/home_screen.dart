import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/category_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../cart/screens/cart_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../products/screens/product_detail_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<ProductItem> _products = [];
  List<CategoryItem> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await CategoryService.fetchCategories();
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final items = await ProductService.fetchProducts(query: _searchController.text);
    if (!mounted) return;
    setState(() {
      _products = items;
      _loading = false;
    });
  }

  List<ProductItem> get _filteredProducts {
    final query = _searchController.text.toLowerCase().trim();
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final auth = context.watch<AuthProvider>();

    final categoryOptions = ['All', ..._categories.map((category) => category.name).toList()];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('ShopHub', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        actions: [
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => _open(const AdminDashboardScreen()),
              tooltip: 'Admin Dashboard',
            ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => _open(const CartScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => _open(const OrdersScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => _open(const CategoriesScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Discover amazing products at great prices',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _searchBox(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categoryOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final category = categoryOptions[index];
                          final selected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category, style: const TextStyle(fontSize: 13)),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedCategory = category),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.skyBlue.withValues(alpha: 0.3),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Featured Products',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: _loading
                  ? const SliverFillRemaining(
                      child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                    )
                  : filtered.isEmpty
                      ? SliverFillRemaining(
                          child: _emptyState(),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, index) => _ProductCardCompact(product: filtered[index]),
                            childCount: filtered.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadProducts,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'No products found',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search or filters.',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ===============================
// COMPACT PRODUCT CARD (NEW)
// ===============================
class _ProductCardCompact extends StatefulWidget {
  const _ProductCardCompact({required this.product});

  final ProductItem product;

  @override
  State<_ProductCardCompact> createState() => _ProductCardCompactState();
}

class _ProductCardCompactState extends State<_ProductCardCompact> {
  int _quantity = 1;

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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: widget.product)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // ----- FIXED SIZE IMAGE (clear and crisp) -----
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.skyBlue.withValues(alpha: 0.2),
                  child: widget.product.imageUrl == null
                      ? Icon(
                          Icons.shopping_bag_outlined,
                          size: 32,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        )
                      : Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            size: 32,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // ----- DETAILS -----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      widget.product.name,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.category,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\$${widget.product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        // Compact quantity & add button
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Text(
                              '$_quantity',
                              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () => setState(() => _quantity++),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart_outlined, size: 20, color: AppColors.steelBlue),
                              onPressed: _addToCart,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Add to cart',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}