import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../models/category_model.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';

class ProductListScreen extends StatefulWidget {
  final int? categoryId;

  const ProductListScreen({super.key, this.categoryId});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    // Clear any stale category name on init
    _categoryName = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesAndProducts();
    });
  }

  void _loadCategoriesAndProducts() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    
    // Always ensure categories are loaded first to get accurate category name
    if (provider.categories.isEmpty) {
      provider.fetchCategories().then((_) {
        _updateCategoryName();
        _loadProducts();
      });
    } else {
      // Categories already loaded, update name and load products
      _updateCategoryName();
      _loadProducts();
    }
  }

  void _updateCategoryName() {
    if (widget.categoryId != null) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      // Find the exact category matching the ID
      try {
        final category = provider.categories.firstWhere(
          (cat) => cat.id == widget.categoryId,
        );
        if (mounted) {
          setState(() {
            _categoryName = category.name;
          });
        }
      } catch (e) {
        // Category not found in list yet, will get from products
        if (mounted) {
          setState(() {
            _categoryName = null;
          });
        }
      }
    }
  }

  Future<void> _loadProducts() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.fetchProducts(categoryId: widget.categoryId);
    
    // Update category name after products load (only if not already set)
    if (widget.categoryId != null && _categoryName == null) {
      _updateCategoryName();
    }
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload products if categoryId changes
    if (oldWidget.categoryId != widget.categoryId) {
      // Immediately clear old category name to prevent showing wrong name
      _categoryName = null;
      // Force rebuild to clear UI
      if (mounted) {
        setState(() {
          _categoryName = null;
        });
      }
      // Reload with new category
      _updateCategoryName();
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchProducts(String query) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.fetchProducts(categoryId: widget.categoryId, search: query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Consumer<ProductProvider>(
          builder: (context, provider, _) {
            // Always look up category name from categories list first (most reliable)
            // Don't rely on cached _categoryName to avoid stale data
            String displayTitle = 'All Products';
            
            if (widget.categoryId != null) {
              // First priority: look up from categories list (always fresh and reliable)
              try {
                final category = provider.categories.firstWhere(
                  (cat) => cat.id == widget.categoryId,
                );
                // Double-check the category ID matches to prevent wrong category display
                if (category.id == widget.categoryId) {
                  displayTitle = category.name;
                  // Update cached name for consistency
                  if (_categoryName != category.name) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _categoryName = category.name;
                        });
                      }
                    });
                  }
                } else {
                  displayTitle = 'Products';
                }
              } catch (e) {
                // Category not found in categories list
                // Only try to get from products if categories list is empty (not loaded yet)
                // Otherwise, show generic title to avoid showing wrong category name
                if (provider.categories.isEmpty && provider.products.isNotEmpty) {
                  // Find ALL products that belong to this category
                  final matchingProducts = provider.products.where(
                    (product) => product.category != null && 
                                 product.category!.id == widget.categoryId,
                  ).toList();
                  
                  if (matchingProducts.isNotEmpty) {
                    // Use the category from the first matching product
                    final matchingProduct = matchingProducts.first;
                    if (matchingProduct.category != null && 
                        matchingProduct.category!.id == widget.categoryId) {
                      displayTitle = matchingProduct.category!.name;
                      // Update cached name
                      if (_categoryName != matchingProduct.category!.name) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _categoryName = matchingProduct.category!.name;
                            });
                          }
                        });
                      }
                    } else {
                      displayTitle = 'Products';
                    }
                  } else {
                    // No products match this category ID
                    displayTitle = 'Products';
                  }
                } else {
                  // Categories list exists but category not found, or no products
                  // Show generic title to avoid confusion
                  displayTitle = 'Products';
                }
              }
            }
            
            return Text(
              displayTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'RoundedSans',
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // Category Info Header (if category selected)
          if (widget.categoryId != null)
            Consumer<ProductProvider>(
              builder: (context, provider, _) {
                // Get category from categories list first (most reliable)
                CategoryModel? category;
                
                try {
                  category = provider.categories.firstWhere(
                    (cat) => cat.id == widget.categoryId,
                  );
                } catch (e) {
                  // If not in categories list, only try to get from products if categories list is empty
                  // This prevents showing wrong category when categories list exists but category not found
                  if (provider.categories.isEmpty && provider.products.isNotEmpty) {
                    // Find ALL products that belong to this category
                    final matchingProducts = provider.products.where(
                      (product) => product.category != null && 
                                   product.category!.id == widget.categoryId,
                    ).toList();
                    
                    if (matchingProducts.isNotEmpty) {
                      // Use the category from the first matching product
                      final matchingProduct = matchingProducts.first;
                      if (matchingProduct.category != null && 
                          matchingProduct.category!.id == widget.categoryId) {
                        category = matchingProduct.category;
                      } else {
                        // Category doesn't match, skip header
                        return const SizedBox.shrink();
                      }
                    } else {
                      // No matching product found, skip header
                      return const SizedBox.shrink();
                    }
                  } else {
                    // Categories list exists but category not found, or no products
                    // Skip header to avoid showing wrong category
                    return const SizedBox.shrink();
                  }
                }
                
                if (category == null) {
                  return const SizedBox.shrink();
                }
                
                final productCount = provider.products.length;
                
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (category.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            category.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.category,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'RoundedSans',
                              ),
                            ),
                            if (category.description != null && category.description!.isNotEmpty)
                              Text(
                                category.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.grey,
                                  fontFamily: 'RoundedSans',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Text(
                                '$productCount ${productCount == 1 ? 'product' : 'products'} available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.grey,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(
                  color: AppTheme.grey.withOpacity(0.6),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.grey.withOpacity(0.7),
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppTheme.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.lightGrey.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppTheme.lightGrey.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppTheme.lightGrey.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onChanged: _searchProducts,
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                // Update category name from products if available
                if (widget.categoryId != null && 
                    provider.products.isNotEmpty && 
                    provider.products.first.category != null &&
                    _categoryName == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _categoryName = provider.products.first.category!.name;
                    });
                  });
                }
                
                if (provider.isLoading && provider.products.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  );
                }
                if (provider.products.isEmpty && !provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.grey,
                          ),
                        ),
                        if (widget.categoryId != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try selecting a different category',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading products',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final responsive = Responsive(context);
                    final crossAxisCount = responsive.getGridColumns();
                    final screenWidth = MediaQuery.of(context).size.width;
                    // Calculate aspect ratio based on screen size (adjusted for taller cards)
                    final aspectRatio = screenWidth < 360 ? 0.60 : screenWidth < 400 ? 0.63 : 0.67;
                    
                    return GridView.builder(
                      padding: responsive.padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: responsive.spacing(16),
                        mainAxisSpacing: responsive.spacing(16),
                      ),
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        return ProductCard(product: product);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

