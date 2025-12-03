import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../utils/theme.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;
  final int? productId;

  const AddEditProductScreen({super.key, this.product, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  int? _selectedCategoryId;
  String _selectedUnit = 'piece';
  bool _isAvailable = true;
  bool _isLoading = false;
  List<CategoryModel> _categories = [];

  final List<String> _units = ['piece', 'kg', 'g', 'liter', 'ml', 'pack', 'dozen'];

  ProductModel? _product;
  bool _isLoadingProduct = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadCategories();
    if (_product != null) {
      _loadProductData();
    } else if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoadingProduct = true);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await adminProvider.fetchProducts(token: authProvider.token);
    _product = adminProvider.products.firstWhere(
      (prod) => prod.id == widget.productId,
      orElse: () => adminProvider.products.first,
    );
    _loadProductData();
    setState(() => _isLoadingProduct = false);
  }

  void _loadProductData() {
    if (_product != null) {
      _nameController.text = _product!.name;
      _descriptionController.text = _product!.description ?? '';
      _priceController.text = _product!.price.toString();
      _stockController.text = _product!.stock.toString();
      _imageUrlController.text = _product!.imageUrl ?? '';
      _selectedCategoryId = _product!.category?.id;
      _selectedUnit = _product!.unit ?? 'piece';
      _isAvailable = _product!.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchCategories();
    setState(() {
      _categories = productProvider.categories;
      if (_selectedCategoryId == null && _categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
      }
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    if (price == null || price <= 0) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    final success = _product == null
        ? await adminProvider.createProduct(
            token: authProvider.token!,
            name: _nameController.text.trim(),
            price: price,
            categoryId: _selectedCategoryId!,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
            stock: stock,
            unit: _selectedUnit,
          )
        : await adminProvider.updateProduct(
            token: authProvider.token!,
            productId: _product!.id,
            name: _nameController.text.trim(),
            price: price,
            categoryId: _selectedCategoryId,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
            stock: stock,
            unit: _selectedUnit,
            isAvailable: _isAvailable,
          );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_product == null ? 'Product created successfully!' : 'Product updated successfully!'),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminProvider.error ?? 'Failed to save product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProduct) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_product == null ? 'Add Product' : 'Edit Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                prefixIcon: Icon(Icons.shopping_bag),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value),
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      prefixIcon: Icon(Icons.inventory),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Please enter a valid stock';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Unit',
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
              ),
              items: _units.map((unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Text(unit.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedUnit = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(),
                helperText: 'Enter a URL for the product image',
              ),
              keyboardType: TextInputType.url,
            ),
            if (_product != null) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Unavailable products won\'t be shown to customers'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                    )
                  : Text(
                      _product == null ? 'Create Product' : 'Update Product',
                      style: const TextStyle(fontSize: 16, color: AppTheme.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

