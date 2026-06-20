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
          IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => _open(CartScreen())),
          IconButton(icon: const Icon(Icons.receipt_long_outlined), onPressed: () => _open(OrdersScreen())),
          IconButton(icon: const Icon(Icons.category_outlined), onPressed: () => _open(CategoriesScreen())),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Browse products, search by name or category, and manage your cart and orders.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _searchBox(),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categoryOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final category = categoryOptions[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Featured products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (filtered.isEmpty)
              _emptyState()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) => _ProductCard(product: filtered[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search by name or category',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProducts,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 36),
            const SizedBox(height: 8),
            Text('No products found', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Try another keyword or category.', style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({required this.product});

  final ProductItem product;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: widget.product)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 108,
              width: double.infinity,
              color: AppColors.skyBlue.withValues(alpha: 0.35),
              child: widget.product.imageUrl == null
                  ? const Center(child: Icon(Icons.shopping_bag_outlined, size: 30, color: AppColors.textPrimary))
                  : ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      child: Image.network(
                        widget.product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 108,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 28)),
                      ),
                    ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(widget.product.category, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(widget.product.description, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
                            Text('\$${widget.product.price.toStringAsFixed(2)}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                              child: const Icon(Icons.remove, size: 15, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 6),
                            Text('$_quantity', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => setState(() => _quantity++),
                              child: const Icon(Icons.add, size: 15, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addToCart,
                      icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                      label: const Text('Add to cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.steelBlue,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ),
    );
  }
}
