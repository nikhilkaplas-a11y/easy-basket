import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
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
        adminProvider.fetchProducts(token: authProvider.token, loadMore: true);
      }
    }
  }

  void _loadProducts() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    adminProvider.fetchProducts(token: authProvider.token);
  }

  void _loadCategories() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.fetchCategories();
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
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

      final success = await adminProvider.deleteProduct(
        token: authProvider.token!,
        productId: product.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
        _loadProducts();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminProvider.error ?? 'Failed to delete product')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadProducts();
          _loadCategories();
        },
        child: adminProvider.isLoading && adminProvider.products.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : adminProvider.products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/admin/products/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: adminProvider.products.length + (adminProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == adminProvider.products.length) {
                        // Load more indicator
                        if (adminProvider.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final product = adminProvider.products[index];
                      return _ProductCard(
                        product: product,
                        currencyFormat: currencyFormat,
                        onDelete: () => _deleteProduct(product),
                        onEdit: () async {
                          final result = await context.push('/admin/products/${product.id}/edit');
                          if (result == true) {
                            _loadProducts();
                          }
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/admin/products/add');
          if (result == true) {
            _loadProducts();
          }
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final NumberFormat currencyFormat;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ProductCard({
    required this.product,
    required this.currencyFormat,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppTheme.lightGrey,
                        child: const Icon(Icons.image, size: 40),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.lightGrey,
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Use min to prevent overflow
                children: [
                  // Product Name - Flexible to prevent overflow
                  Flexible(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.description != null) ...[
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Price Row - Use Flexible to prevent horizontal overflow
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          currencyFormat.format(product.price),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4), // Reduced spacing
                      Flexible(
                        child: Text(
                          '/ ${product.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Availability Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        product.isAvailable ? Icons.check_circle : Icons.cancel,
                        size: 14, // Reduced size
                        color: product.isAvailable ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          product.isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 11, // Reduced size
                            color: product.isAvailable ? Colors.green : Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (product.category != null) ...[
                    const SizedBox(height: 4),
                    Flexible(
                      child: Chip(
                        label: Text(
                          product.category!.name,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
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
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
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

