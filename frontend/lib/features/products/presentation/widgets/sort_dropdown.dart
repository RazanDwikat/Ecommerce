import 'package:flutter/material.dart';

import '../../domain/entities/product_filter.dart';

class SortDropdown extends StatelessWidget {
  final ProductSort selected;
  final ValueChanged<ProductSort> onChanged;

  const SortDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ProductSort>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Sort by'),
      items: ProductSort.values
          .map(
            (s) => DropdownMenuItem<ProductSort>(
              value: s,
              child: Text(s.label),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
