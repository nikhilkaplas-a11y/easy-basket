import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/floating_cart_bar.dart';
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
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _categoryName = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesAndProducts();
    });
  }

  void _loadCategoriesAndProducts() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    
    if (provider.categories.isEmpty) {
      provider.fetchCategories().then((_) {
        _updateCategoryName();
        _loadProducts();
      });
    } else {
      _updateCategoryName();
      _loadProducts();
    }
  }

  void _updateCategoryName() {
    if (widget.categoryId != null) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
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
    
    if (widget.categoryId != null && _categoryName == null) {
      _updateCategoryName();
    }
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _categoryName = null;
      if (mounted) {
        setState(() {
          _categoryName = null;
        });
      }
      _updateCategoryName();
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchProducts(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      
      if (query.length >= 2) {
        provider.fetchSuggestions(query);
      } else {
        provider.clearSuggestions();
      }

      provider.fetchProducts(categoryId: widget.categoryId, search: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Consumer<ProductProvider>(
          builder: (context, provider, _) {
            String displayTitle = 'All Products';
            if (widget.categoryId != null) {
               try {
                final category = provider.categories.firstWhere(
                  (cat) => cat.id == widget.categoryId,
                );
                if (category.id == widget.categoryId) {
                  displayTitle = category.name;
                }
              } catch (e) {
                if (provider.categories.isEmpty && provider.products.isNotEmpty) {
                  final matchingProducts = provider.products.where(
                    (product) => product.category != null && 
                                 product.category!.id == widget.categoryId,
                  ).toList();
                  if (matchingProducts.isNotEmpty) {
                    displayTitle = matchingProducts.first.category!.name;
                  }
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Search Bar (Pinned)
              SliverToBoxAdapter(
                child: Container(
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
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    onChanged: _searchProducts,
                  ),
                ),
              ),

              // 2. Suggestions List (Inline)
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.suggestions.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final suggestion = provider.suggestions[index];
                        final imageUrl = suggestion['imageUrl'];
                        
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.search, size: 20, color: AppTheme.grey),
                                        ),
                                      )
                                    : const Icon(Icons.search, size: 20, color: AppTheme.grey),
                              ),
                              title: Text(
                                suggestion['name'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                _searchController.text = suggestion['name'];
                                _searchProducts(suggestion['name']);
                                provider.clearSuggestions();
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            if (index < provider.suggestions.length - 1)
                              const Divider(height: 1, indent: 76, endIndent: 20),
                          ],
                        );
                      },
                      childCount: provider.suggestions.length,
                    ),
                  );
                },
              ),

              // 3. "Showing results for..." Header
              SliverToBoxAdapter(
                child: ValueListenableBuilder(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Text(
                        'Showing results for "${value.text}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. Product Grid
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                    );
                  }

                  if (provider.products.isEmpty && !provider.isLoading) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final responsive = Responsive(context);
                  final crossAxisCount = responsive.getGridColumns();
                  final screenWidth = MediaQuery.of(context).size.width;
                  final aspectRatio = screenWidth < 360 ? 0.54 : screenWidth < 400 ? 0.56 : 0.58;

                  return SliverPadding(
                    padding: EdgeInsets.only(
                      left: responsive.padding.left,
                      right: responsive.padding.right,
                      top: responsive.padding.top,
                      bottom: MediaQuery.of(context).padding.bottom + 120, // Space for cart bar
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ProductCard(product: provider.products[index]);
                        },
                        childCount: provider.products.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: responsive.spacing(16),
                        mainAxisSpacing: responsive.spacing(16),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Floating Cart Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const FloatingCartBar(),
          ),
        ],
      ),
    );
  }
}
