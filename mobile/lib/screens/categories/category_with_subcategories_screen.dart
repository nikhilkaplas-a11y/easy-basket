import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';

class CategoryWithSubcategoriesScreen extends StatefulWidget {
  final int parentCategoryId;
  final String parentCategoryName;

  const CategoryWithSubcategoriesScreen({
    super.key,
    required this.parentCategoryId,
    required this.parentCategoryName,
  });

  @override
  State<CategoryWithSubcategoriesScreen> createState() => _CategoryWithSubcategoriesScreenState();
}

class _CategoryWithSubcategoriesScreenState extends State<CategoryWithSubcategoriesScreen> {
  List<CategoryModel> _subcategories = [];
  int? _selectedSubcategoryId;
  bool _isLoadingSubcategories = true;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    setState(() => _isLoadingSubcategories = true);
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    
    try {
      debugPrint('🔄 Loading subcategories for parent category ID: ${widget.parentCategoryId}');
      final endpoint = '/categories/${widget.parentCategoryId}/subcategories';
      debugPrint('📡 API endpoint: $endpoint');
      
      final response = await provider.apiService.get(endpoint);
      
      debugPrint('📦 Raw API response type: ${response.runtimeType}');
      debugPrint('📦 Raw API response: $response');
      
      if (response is Map<String, dynamic>) {
        debugPrint('✅ Response is Map');
        debugPrint('📋 Response keys: ${response.keys.toList()}');
        
        if (response.containsKey('subcategories')) {
          final List<dynamic>? data = response['subcategories'] as List<dynamic>?;
          debugPrint('✅ Found subcategories key, data type: ${data.runtimeType}');
          debugPrint('📊 Subcategories count: ${data?.length ?? 0}');
          
          if (data != null && data.isNotEmpty) {
            debugPrint('📝 Parsing ${data.length} subcategories...');
            final parsed = <CategoryModel>[];
            
            for (var item in data) {
              try {
                if (item is Map<String, dynamic>) {
                  final subcategory = CategoryModel.fromJson(item);
                  parsed.add(subcategory);
                  debugPrint('  ✅ Parsed: ${subcategory.name} (ID: ${subcategory.id})');
                } else {
                  debugPrint('  ❌ Item is not Map: ${item.runtimeType}');
                }
              } catch (e) {
                debugPrint('  ❌ Error parsing subcategory: $e');
                debugPrint('  📄 Item data: $item');
              }
            }
            
            debugPrint('✅ Successfully parsed ${parsed.length} subcategories');
            
            setState(() {
              _subcategories = parsed;
              _isLoadingSubcategories = false;
              
              // Auto-select first subcategory if available
              if (_subcategories.isNotEmpty) {
                _selectedSubcategoryId = _subcategories.first.id;
                debugPrint('🎯 Auto-selected first subcategory: ${_subcategories.first.name} (ID: ${_subcategories.first.id})');
                _loadProducts(_subcategories.first.id);
              } else {
                debugPrint('⚠️ No subcategories after parsing, loading parent products');
                _selectedSubcategoryId = null;
                _loadProducts(widget.parentCategoryId);
              }
            });
          } else {
            debugPrint('⚠️ Subcategories array is empty or null');
            setState(() {
              _subcategories = [];
              _isLoadingSubcategories = false;
              _selectedSubcategoryId = null;
              _loadProducts(widget.parentCategoryId);
            });
          }
        } else {
          debugPrint('❌ Response does not contain "subcategories" key');
          debugPrint('📋 Available keys: ${response.keys.toList()}');
          setState(() {
            _subcategories = [];
            _isLoadingSubcategories = false;
            _selectedSubcategoryId = null;
            _loadProducts(widget.parentCategoryId);
          });
        }
      } else {
        debugPrint('❌ Response is not a Map, it is: ${response.runtimeType}');
        setState(() {
          _subcategories = [];
          _isLoadingSubcategories = false;
          _selectedSubcategoryId = null;
          _loadProducts(widget.parentCategoryId);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading subcategories: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      setState(() {
        _subcategories = [];
        _isLoadingSubcategories = false;
        _selectedSubcategoryId = null;
        _loadProducts(widget.parentCategoryId);
      });
    }
  }

  Future<void> _loadProducts(int categoryId) async {
    setState(() => _isLoadingProducts = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.fetchProducts(categoryId: categoryId);
    setState(() => _isLoadingProducts = false);
  }

  void _onSubcategorySelected(int subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });
    _loadProducts(subcategoryId);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.parentCategoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'RoundedSans',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingSubcategories
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            )
          : _subcategories.isEmpty
              ? _buildProductsOnlyView()
              : _buildSideBySideView(isMobile),
    );
  }

  Widget _buildProductsOnlyView() {
    final provider = Provider.of<ProductProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.lightGrey.withOpacity(0.3),
            ),
            onChanged: (query) {
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              productProvider.fetchProducts(
                categoryId: widget.parentCategoryId,
                search: query.isEmpty ? null : query,
              );
            },
          ),
        ),
        // Products grid
        Expanded(
          child: _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : provider.products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadProducts(widget.parentCategoryId),
                      child: GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 360 ? 8 : 12,
                          vertical: screenWidth < 360 ? 8 : 12,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: screenWidth < 400 ? 0.62 : 0.65, // Adjusted for side-positioned button
                          crossAxisSpacing: screenWidth < 360 ? 8 : 12,
                          mainAxisSpacing: screenWidth < 360 ? 8 : 12,
                        ),
                        itemCount: provider.products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(product: provider.products[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSideBySideView(bool isMobile) {
    // Blinkit-style: Side-by-side layout for both mobile and desktop
    // Mobile: Narrower sidebar, Desktop: Wider sidebar
    final sidebarWidth = isMobile ? 100.0 : 250.0;
    
    return Row(
      children: [
        // Left sidebar - Subcategories with images (Blinkit style)
        Container(
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: AppTheme.lightGrey.withOpacity(0.3),
            border: Border(
              right: BorderSide(color: AppTheme.lightGrey, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Subcategories list with images
              Expanded(
                child: ListView.builder(
                  itemCount: _subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = _subcategories[index];
                    final isSelected = _selectedSubcategoryId == subcategory.id;
                    
                    return InkWell(
                      onTap: () => _onSubcategorySelected(subcategory.id),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 12,
                          vertical: isMobile ? 10 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(color: AppTheme.lightGrey, width: 1),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Subcategory Image
                            Container(
                              width: isMobile ? 50 : 60,
                              height: isMobile ? 50 : 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                              ),
                              child: subcategory.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                                      child: CachedNetworkImage(
                                        imageUrl: subcategory.imageUrl!,
                                        width: isMobile ? 50 : 60,
                                        height: isMobile ? 50 : 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: AppTheme.primaryGreen.withOpacity(0.1),
                                          child: Center(
                                            child: SizedBox(
                                              width: isMobile ? 16 : 20,
                                              height: isMobile ? 16 : 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  isSelected ? Colors.white : AppTheme.primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Icon(
                                          Icons.category,
                                          size: isMobile ? 24 : 28,
                                          color: isSelected ? Colors.white : AppTheme.primaryGreen,
                                        ),
                                        fadeInDuration: const Duration(milliseconds: 300),
                                      ),
                                    )
                                  : Icon(
                                      Icons.category,
                                      size: isMobile ? 24 : 28,
                                      color: isSelected ? Colors.white : AppTheme.primaryGreen,
                                    ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(height: 6),
                              Flexible(
                                child: Text(
                                  subcategory.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.black,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            // Mobile: Show name below image in smaller text
                            if (isMobile) ...[
                              const SizedBox(height: 3),
                              Flexible(
                                child: Text(
                                  subcategory.name,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.black,
                                    height: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Right side - Products with search
        Expanded(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.lightGrey.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    isDense: isMobile,
                  ),
                  onChanged: (query) {
                    final productProvider = Provider.of<ProductProvider>(context, listen: false);
                    final categoryId = _selectedSubcategoryId ?? widget.parentCategoryId;
                    productProvider.fetchProducts(
                      categoryId: categoryId,
                      search: query.isEmpty ? null : query,
                    );
                  },
                ),
              ),
              // Products grid
              Expanded(
                child: _buildProductsGrid(showSearchBar: false),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildProductsGrid({bool showSearchBar = true}) {
    final provider = Provider.of<ProductProvider>(context);
    final responsive = Responsive(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    // Adjust grid columns based on available width (accounting for sidebar)
    final sidebarWidth = isMobile ? 100.0 : 250.0;
    final availableWidth = screenWidth - sidebarWidth;
    final crossAxisCount = isMobile 
        ? 2 
        : (availableWidth < 600 ? 2 : (availableWidth < 900 ? 3 : 4));
    
    return _isLoadingProducts
        ? const Center(child: CircularProgressIndicator())
        : provider.products.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () {
                  final categoryId = _selectedSubcategoryId ?? (_subcategories.isNotEmpty ? _subcategories.first.id : widget.parentCategoryId);
                  return _loadProducts(categoryId);
                },
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 360 ? 8 : 12,
                    vertical: screenWidth < 360 ? 8 : 12,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: screenWidth < 400 ? 0.62 : 0.65, // Adjusted for side-positioned button
                    crossAxisSpacing: screenWidth < 360 ? 8 : 12,
                    mainAxisSpacing: screenWidth < 360 ? 8 : 12,
                  ),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: provider.products[index]);
                  },
                ),
              );
  }
}

