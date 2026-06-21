import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _categories = [];
      });
      return;
    }

    try {
      setState(() => _loading = true);
      final response = await _apiService.getAllCategoriesAdmin(token);
      setState(() {
        _categories = response['categories'] as List<dynamic>? ?? [];
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

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryDialog(
        nameController: nameController,
        descriptionController: descriptionController,
      ),
    );

    if (result == true && mounted) {
      await _createCategory(nameController.text.trim(), descriptionController.text.trim());
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _createCategory(String name, String description) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.createCategory(token, name, description);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category created successfully')),
      );
      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> category) async {
    final nameController = TextEditingController(text: category['name'] as String? ?? '');
    final descriptionController = TextEditingController(text: category['description'] as String? ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryDialog(
        nameController: nameController,
        descriptionController: descriptionController,
        isEdit: true,
      ),
    );

    if (result == true && mounted) {
      await _updateCategory(category['_id'].toString(), nameController.text.trim(), descriptionController.text.trim());
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _updateCategory(String categoryId, String name, String description) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.updateCategory(token, categoryId, name, description);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully')),
      );
      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
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
      await _apiService.deleteCategory(token, categoryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _restoreCategory(String categoryId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.restoreCategory(token, categoryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category restored successfully')),
      );
      _loadCategories();
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
        title: Text('Categories Management', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadCategories,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _categories.isEmpty
                  ? _buildEmptyState()
                  : _buildCategoriesList(),
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
          Icon(Icons.category_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Categories',
            style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first category to get started',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index] as Map<String, dynamic>;
        return _CategoryCard(
          category: category,
          onEdit: () => _showEditDialog(category),
          onDelete: () => _deleteCategory(category['_id'].toString()),
          onRestore: () => _restoreCategory(category['_id'].toString()),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = category['deletedAt'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDeleted ? AppColors.background.withValues(alpha: 0.5) : AppColors.white,
      elevation: isDeleted ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDeleted ? BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.skyBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.category_outlined,
                color: AppColors.steelBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'] as String? ?? 'Unnamed',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDeleted ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['description'] as String? ?? 'No description',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isDeleted)
              IconButton(
                onPressed: onRestore,
                icon: const Icon(Icons.restore_from_trash_outlined),
                tooltip: 'Restore',
                color: AppColors.success,
              )
            else
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

class _CategoryDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool isEdit;

  const _CategoryDialog({
    required this.nameController,
    required this.descriptionController,
    this.isEdit = false,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Category' : 'Create Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a name';
                return null;
              },
            ),
            const SizedBox(height: 16),
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
          ],
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
