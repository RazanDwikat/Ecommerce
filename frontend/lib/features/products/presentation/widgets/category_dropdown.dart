import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

class CategoryDropdown extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Category'),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All categories'),
        ),
        ...categories.map(
          (c) => DropdownMenuItem<String?>(
            value: c.id,
            child: Text(c.name.isEmpty ? c.id : c.name),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
