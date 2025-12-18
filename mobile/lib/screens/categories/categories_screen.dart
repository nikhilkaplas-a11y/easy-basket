import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../models/category_model.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Always refresh categories when screen opens to ensure fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  void _loadCategories() {
    if (_hasLoaded) return;
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    _hasLoaded = true;
    // Always fetch fresh categories to avoid stale data
    provider.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'All Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'RoundedSans',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            );
          }

          if (provider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: AppTheme.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories available',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.grey,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                ],
              ),
            );
          }

          final responsive = Responsive(context);
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = responsive.getCategoryGridColumns();
          // Optimized aspect ratio for icon + name
          // Icon (45px) + spacing (4px) + name (30px for 2 lines) + padding (16px) = ~95px needed
          // For width ~53px (on small screens), aspect ratio needs to be higher
          final aspectRatio = screenWidth < 360 ? 0.85 : 0.95;

          return RefreshIndicator(
            onRefresh: () async {
              final provider = Provider.of<ProductProvider>(context, listen: false);
              await provider.fetchCategories();
            },
            color: AppTheme.primaryGreen,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                // Validate category has valid data before displaying
                if (category.name.isEmpty || category.id <= 0) {
                  return const SizedBox.shrink();
                }
                return _CategoryCard(category: category);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return GestureDetector(
      onTap: () async {
        // Debug: Check category subcategories
        debugPrint('🔵 Tapped category: ${category.name} (ID: ${category.id})');
        debugPrint('🔵 Has subcategories: ${category.hasSubcategories}');
        debugPrint('🔵 Subcategories: ${category.subcategories}');
        debugPrint('🔵 Subcategories count: ${category.subcategories?.length ?? 0}');
        
        // Always navigate to category screen first - it will check for subcategories
        // This ensures we always show the Blinkit-style layout if subcategories exist
        debugPrint('🔵 Navigating to category screen: /categories/${category.id}/products');
        context.push('/categories/${category.id}/products', extra: {
          'parentCategoryName': category.name,
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight;
            final gap = maxH < 64 ? 2.0 : 4.0;
            final reservedTextHeight = maxH < 64 ? 12.0 : 22.0;
            final computedIconSize = (maxH - reservedTextHeight - gap - 8).clamp(16.0, 46.0);
            final remaining = maxH - computedIconSize - gap;
            final nameMaxLines = remaining < 16 ? 1 : 2;
            final nameFontSize = remaining < 16 ? responsive.fontSize(9) : responsive.fontSize(11);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: computedIconSize,
                    height: computedIconSize,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: category.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: category.imageUrl!,
                              width: computedIconSize,
                              height: computedIconSize,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.category_rounded,
                                size: responsive.iconSize(22),
                                color: AppTheme.primaryGreen,
                              ),
                              fadeInDuration: const Duration(milliseconds: 300),
                            ),
                          )
                        : Icon(
                            Icons.category_rounded,
                            size: responsive.iconSize(22),
                            color: AppTheme.primaryGreen,
                          ),
                  ),
                  SizedBox(height: gap),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        category.name.isNotEmpty ? category.name : 'Category',
                        style: TextStyle(
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.black,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: nameMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
