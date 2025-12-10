import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../models/category_model.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

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
          // Optimized aspect ratio for icon + name (removed description to prevent overflow)
          final aspectRatio = screenWidth < 360 ? 0.85 : 0.80;

          return GridView.builder(
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
              return _CategoryCard(category: category);
            },
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
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Section
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
              // Category Name - Always visible with fixed height
              SizedBox(
                height: 36, // Fixed height to ensure name is always visible
                child: Center(
                  child: Text(
                    category.name,
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
            ],
          ),
        ),
      ),
    );
  }
}

