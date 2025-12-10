import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
          // Optimized aspect ratio for icon + name - increased to prevent overlap
          // Icon (55px) + spacing (10px) + name (40px) + padding (24px) = ~129px needed
          // For width ~110px, aspect ratio should be ~0.85
          final aspectRatio = screenWidth < 360 ? 0.90 : 0.85;

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
    final screenWidth = MediaQuery.of(context).size.width;
    // Reduced icon size to fit in available space
    final iconSize = screenWidth < 360 ? 50.0 : 55.0;

    return GestureDetector(
      onTap: () => context.push('/products?categoryId=${category.id}'),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Section - Fixed size
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: category.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          category.imageUrl!,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.category_rounded,
                            size: responsive.iconSize(28),
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.category_rounded,
                        size: responsive.iconSize(28),
                        color: AppTheme.primaryGreen,
                      ),
              ),
              const SizedBox(height: 10),
              // Category Name - Fixed height to prevent overlap
              SizedBox(
                height: 38, // Fixed height to ensure name doesn't overlap
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      category.name.isNotEmpty ? category.name : 'Category',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.black,
                        fontFamily: 'RoundedSans',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

