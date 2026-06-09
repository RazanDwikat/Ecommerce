import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/category_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/theme/app_colors.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryItem> _categories = [];
  List<ProductItem> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final categories = await CategoryService.fetchCategories();
    final products = await ProductService.fetchProducts();

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _products = products;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Categories', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final category = _categories[index];
            final items = _products
                .where((product) => product.category.toLowerCase() == category.name.toLowerCase())
                .toList();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(category.description, style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Text('No products available in this category yet.', style: GoogleFonts.dmSans(color: AppColors.textSecondary))
                    else
                      ...items.map((product) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                                  Text(product.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('\$${product.price.toStringAsFixed(2)}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
