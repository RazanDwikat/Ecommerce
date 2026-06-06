import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/product_filter.dart';
import '../manager/filter_cubit.dart';
import '../manager/products_cubit.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/search_field.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  void initState() {
    super.initState();
    final productsCubit = context.read<ProductsCubit>();
    productsCubit.loadCategories();
    productsCubit.fetchProducts(context.read<FilterCubit>().state);
  }

  void _openFilterSheet() async {
    final productsCubit = context.read<ProductsCubit>();
    final filterCubit = context.read<FilterCubit>();

    final result = await FilterBottomSheet.show(
      context,
      current: filterCubit.state,
      categories: productsCubit.state.categories,
    );

    if (result == null) return;

    filterCubit
      ..setCategory(result.categoryId)
      ..setPriceRange(result.minPrice, result.maxPrice)
      ..setSort(result.sort);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          BlocBuilder<FilterCubit, ProductFilter>(
            builder: (context, filter) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: _openFilterSheet,
                    tooltip: 'Filters',
                  ),
                  if (filter.hasActiveFilters)
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.amber,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      // When the filter changes, re-fetch products.
      body: BlocListener<FilterCubit, ProductFilter>(
        listener: (context, filter) {
          context.read<ProductsCubit>().fetchProducts(filter);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SearchField(
                initialValue: context.read<FilterCubit>().state.search,
                onChanged: (value) =>
                    context.read<FilterCubit>().setSearch(value),
              ),
            ),
            const _ActiveFiltersBar(),
            Expanded(
              child: BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) {
                  switch (state.status) {
                    case ProductsStatus.loading:
                    case ProductsStatus.initial:
                      return const LoadingWidget();
                    case ProductsStatus.failure:
                      return AppErrorWidget(
                        message: state.errorMessage ?? 'Something went wrong',
                        onRetry: () => context
                            .read<ProductsCubit>()
                            .fetchProducts(context.read<FilterCubit>().state),
                      );
                    case ProductsStatus.success:
                      final products = state.data?.products ?? const [];
                      if (products.isEmpty) return const EmptyWidget();
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: products.length,
                        itemBuilder: (_, i) =>
                            ProductCard(product: products[i]),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small bar that shows a "Clear all" action when filters are active.
class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, ProductFilter>(
      builder: (context, filter) {
        if (!filter.hasActiveFilters) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear all'),
              onPressed: () => context.read<FilterCubit>().reset(),
            ),
          ),
        );
      },
    );
  }
}
