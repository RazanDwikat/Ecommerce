import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  String? _errorCategories;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  Future<void> _loadProducts() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _products = [];
      });
      return;
    }

    try {
      setState(() => _loading = true);
      final response = await _apiService.getAllProductsAdmin(token);
      setState(() {
        _products = response['products'] as List<dynamic>? ?? [];
        _error = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _categories = [];
      });
      return;
    }

    try {
      final response = await _apiService.getAllCategoriesAdmin(token);
      setState(() {
        _categories = response['categories'] as List<dynamic>? ?? [];
        _errorCategories = null;
      });
    } catch (e) {
      setState(() {
        _errorCategories = e.toString();
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    String? selectedCategoryId;
    final stockController = TextEditingController(text: '0');
    List<String> selectedImagePaths = [];
    List<Uint8List> selectedImageBytes = [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ProductDialog(
        nameController: nameController,
        descriptionController: descriptionController,
        priceController: priceController,
        categories: _categories,
        selectedCategoryId: selectedCategoryId,
        onCategorySelected: (id) => selectedCategoryId = id,
        stockController: stockController,
        initialImagePaths: selectedImagePaths,
        onImagesSelected: (paths) => selectedImagePaths = paths,
        onImageBytesSelected: (bytes) => selectedImageBytes = bytes,
      ),
    );

    if (result == true && mounted && selectedCategoryId != null) {
      await _createProduct(
        nameController.text.trim(),
        descriptionController.text.trim(),
        double.tryParse(priceController.text) ?? 0,
        selectedCategoryId!,
        int.tryParse(stockController.text) ?? 0,
        selectedImagePaths,
        selectedImageBytes,
      );
    }

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  Future<void> _createProduct(String name, String description, double price, String category, int stock, List<String> imagePaths, List<Uint8List> imageBytes) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.createProduct(token, {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'stock': stock,
      }, imagePaths, imageBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully')),
      );
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> product) async {
    final nameController = TextEditingController(text: product['name'] as String? ?? '');
    final descriptionController = TextEditingController(text: product['description'] as String? ?? '');
    final priceController = TextEditingController(text: (product['price'] as num?)?.toString() ?? '0');
    
    // Handle category - it might be a Map (with _id and name) or a String
    String? selectedCategoryId;
    if (product['category'] is String) {
      selectedCategoryId = product['category'] as String;
    } else if (product['category'] is Map) {
      final categoryMap = product['category'] as Map<String, dynamic>?;
      selectedCategoryId = categoryMap?['_id']?.toString();
    }
    
    final stockController = TextEditingController(text: (product['stock'] as num?)?.toString() ?? '0');
    List<String> selectedImagePaths = [];
    List<Uint8List> selectedImageBytes = [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ProductDialog(
        nameController: nameController,
        descriptionController: descriptionController,
        priceController: priceController,
        categories: _categories,
        selectedCategoryId: selectedCategoryId,
        onCategorySelected: (id) => selectedCategoryId = id,
        stockController: stockController,
        isEdit: true,
        initialImagePaths: selectedImagePaths,
        onImagesSelected: (paths) => selectedImagePaths = paths,
        onImageBytesSelected: (bytes) => selectedImageBytes = bytes,
      ),
    );

    if (result == true && mounted && selectedCategoryId != null) {
      await _updateProduct(
        product['_id'].toString(),
        nameController.text.trim(),
        descriptionController.text.trim(),
        double.tryParse(priceController.text) ?? 0,
        selectedCategoryId!,
        int.tryParse(stockController.text) ?? 0,
        selectedImagePaths,
        selectedImageBytes,
      );
    }

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  Future<void> _updateProduct(String productId, String name, String description, double price, String category, int stock, List<String> imagePaths, List<Uint8List> imageBytes) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.updateProduct(token, productId, {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'stock': stock,
      }, imagePaths, imageBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.deleteProduct(token, productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Products Management', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _products.isEmpty
                  ? _buildEmptyState()
                  : _buildProductsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.steelBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Products',
            style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first product to get started',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index] as Map<String, dynamic>;
        return _ProductCard(
          product: product,
          onEdit: () => _showEditDialog(product),
          onDelete: () => _deleteProduct(product['_id'].toString()),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final images = product['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] as String? : null;
    
    // Handle category - it might be a Map (with _id and name) or a String
    String categoryName = 'No category';
    if (product['category'] is String) {
      categoryName = product['category'] as String;
    } else if (product['category'] is Map) {
      final categoryMap = product['category'] as Map<String, dynamic>?;
      categoryName = categoryMap?['name'] as String? ?? 'No category';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.skyBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 32),
                      ),
                    )
                  : const Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.steelBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] as String? ?? 'Unnamed',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoryName,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stock > 0 ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Stock: $stock',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stock > 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  color: AppColors.steelBlue,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final List<dynamic> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;
  final TextEditingController stockController;
  final bool isEdit;
  final List<String> initialImagePaths;
  final Function(List<String>) onImagesSelected;
  final Function(List<Uint8List>) onImageBytesSelected;

  const _ProductDialog({
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.stockController,
    this.isEdit = false,
    this.initialImagePaths = const [],
    required this.onImagesSelected,
    required this.onImageBytesSelected,
  });

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _localSelectedCategoryId;
  List<String> _imagePaths = [];
  List<Uint8List> _imageBytes = [];

  @override
  void initState() {
    super.initState();
    _localSelectedCategoryId = widget.selectedCategoryId;
    _imagePaths = widget.initialImagePaths;
  }

  Future<void> _pickImages() async {
    if (_imagePaths.length + _imageBytes.length >= 5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      for (var file in result.files) {
        if (_imagePaths.length + _imageBytes.length < 5) {
          if (file.bytes != null) {
            _imageBytes.add(file.bytes!);
          }
        }
      }
      widget.onImagesSelected(_imagePaths);
      widget.onImageBytesSelected(_imageBytes);
    });
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _imagePaths.length) {
        _imagePaths.removeAt(index);
      } else {
        _imageBytes.removeAt(index - _imagePaths.length);
      }
      widget.onImagesSelected(_imagePaths);
      widget.onImageBytesSelected(_imageBytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Product' : 'Create Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                controller: widget.nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a name';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a description';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a price';
                  if (double.tryParse(value) == null) return 'Please enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _localSelectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['_id'].toString(),
                    child: Text(category['name'] as String? ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _localSelectedCategoryId = value;
                    widget.onCategorySelected(value);
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select a category';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter stock';
                  if (int.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Product Images (Max 5)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_imagePaths.isEmpty && _imageBytes.isEmpty)
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add Images'),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length + _imageBytes.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: index < _imagePaths.length
                                      ? Image.file(
                                          File(_imagePaths[index]),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                        )
                                      : Image.memory(
                                          _imageBytes[index - _imagePaths.length],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (_imagePaths.length + _imageBytes.length < 5)
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add More Images'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, true);
            }
          },
          child: Text(widget.isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
