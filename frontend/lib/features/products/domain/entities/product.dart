import 'package:equatable/equatable.dart';

import 'category.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final num price;
  final int stock;
  final List<String> images;
  final Category? category;
  final num averageRating;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
    required this.category,
    required this.averageRating,
  });

  @override
  List<Object?> get props =>
      [id, name, description, price, stock, images, category, averageRating];
}
