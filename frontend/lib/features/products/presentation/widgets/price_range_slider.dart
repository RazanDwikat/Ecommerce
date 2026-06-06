import 'package:flutter/material.dart';

/// Lets the user pick a [minPrice]/[maxPrice] range.
class PriceRangeSlider extends StatelessWidget {
  final double maxLimit;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  const PriceRangeSlider({
    super.key,
    this.maxLimit = 1000,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price range'),
        RangeSlider(
          min: 0,
          max: maxLimit,
          divisions: 50,
          values: values,
          labels: RangeLabels(
            values.start.round().toString(),
            values.end.round().toString(),
          ),
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${values.start.round()}'),
              Text('\$${values.end.round()}'),
            ],
          ),
        ),
      ],
    );
  }
}
