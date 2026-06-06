import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/product_filter.dart';
import 'category_dropdown.dart';
import 'price_range_slider.dart';
import 'sort_dropdown.dart';

/// Result returned when the user applies filters from the bottom sheet.
class FilterResult {
  final String? categoryId;
  final num? minPrice;
  final num? maxPrice;
  final ProductSort sort;

  const FilterResult({
    required this.categoryId,
    required this.minPrice,
    required this.maxPrice,
    required this.sort,
  });
}

/// Bottom sheet that groups all filter controls (category, price, sort).
class FilterBottomSheet extends StatefulWidget {
  final ProductFilter current;
  final List<Category> categories;
  final double maxPrice;

  const FilterBottomSheet({
    super.key,
    required this.current,
    required this.categories,
    this.maxPrice = 1000,
  });

  /// Shows the sheet and returns the chosen [FilterResult], or null if dismissed.
  static Future<FilterResult?> show(
    BuildContext context, {
    required ProductFilter current,
    required List<Category> categories,
    double maxPrice = 1000,
  }) {
    return showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterBottomSheet(
        current: current,
        categories: categories,
        maxPrice: maxPrice,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _categoryId;
  late RangeValues _priceRange;
  late ProductSort _sort;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.current.categoryId;
    _sort = widget.current.sort;
    _priceRange = RangeValues(
      (widget.current.minPrice ?? 0).toDouble(),
      (widget.current.maxPrice ?? widget.maxPrice).toDouble(),
    );
  }

  void _reset() {
    setState(() {
      _categoryId = null;
      _sort = ProductSort.none;
      _priceRange = RangeValues(0, widget.maxPrice);
    });
  }

  void _apply() {
    final usesMin = _priceRange.start > 0;
    final usesMax = _priceRange.end < widget.maxPrice;
    Navigator.of(context).pop(
      FilterResult(
        categoryId: _categoryId,
        minPrice: usesMin ? _priceRange.start : null,
        maxPrice: usesMax ? _priceRange.end : null,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 8),
          CategoryDropdown(
            categories: widget.categories,
            selectedId: _categoryId,
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 16),
          PriceRangeSlider(
            maxLimit: widget.maxPrice,
            values: _priceRange,
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          const SizedBox(height: 16),
          SortDropdown(
            selected: _sort,
            onChanged: (v) => setState(() => _sort = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _apply,
              child: const Text('Apply filters'),
            ),
          ),
        ],
      ),
    );
  }
}
