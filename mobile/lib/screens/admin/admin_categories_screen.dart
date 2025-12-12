import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/category_model.dart';
import '../../utils/theme.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (adminProvider.hasMore && !adminProvider.isLoadingMore) {
        adminProvider.fetchCategories(token: authProvider.token, loadMore: true);
      }
    }
  }

  void _loadCategories() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    adminProvider.fetchCategories(token: authProvider.token);
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This will affect all products in this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.token == null) return;

      final success = await adminProvider.deleteCategory(
        token: authProvider.token!,
        categoryId: category.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully!')),
        );
        _loadCategories();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminProvider.error ?? 'Failed to delete category')),
        );
      }
    }
  }

  Future<void> _toggleCategoryStatus(CategoryModel category) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null) return;

    final success = await adminProvider.updateCategory(
      token: authProvider.token!,
      categoryId: category.id,
      isActive: !category.isActive,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category ${!category.isActive ? 'activated' : 'deactivated'} successfully!'),
        ),
      );
      _loadCategories();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminProvider.error ?? 'Failed to update category')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadCategories(),
        child: adminProvider.isLoading && adminProvider.categories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : adminProvider.categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: AppTheme.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No categories found',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/admin/categories/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Category'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: adminProvider.categories.length + (adminProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == adminProvider.categories.length) {
                        // Load more indicator
                        if (adminProvider.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final category = adminProvider.categories[index];
                      return _CategoryCard(
                        category: category,
                        onDelete: () => _deleteCategory(category),
                        onToggleStatus: () => _toggleCategoryStatus(category),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/admin/categories/add');
          if (result == true) {
            _loadCategories();
          }
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _CategoryCard({
    required this.category,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category Image/Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: category.isActive ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: category.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        category.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.category,
                          size: 32,
                          color: category.isActive ? AppTheme.primaryGreen : AppTheme.grey,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      size: 32,
                      color: category.isActive ? AppTheme.primaryGreen : AppTheme.grey,
                    ),
            ),
            const SizedBox(width: 16),
            // Category Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Use min to prevent overflow
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: category.isActive ? AppTheme.black : AppTheme.grey,
                            decoration: category.isActive ? null : TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: category.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: category.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        category.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Actions - Use Column with mainAxisSize.min
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    category.isActive ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blue,
                    size: 20,
                  ),
                  onPressed: onToggleStatus,
                  tooltip: category.isActive ? 'Deactivate' : 'Activate',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

