import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/category_card.dart';
import '../../widgets/product_card.dart';
import '../../models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      productProvider.fetchCategories();
      productProvider.fetchProducts();
      
      // Fetch addresses if user is authenticated
      if (authProvider.token != null) {
        orderProvider.fetchAddresses(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: AppTheme.white),
        title: const Text(
          'Easy Basket',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart, color: AppTheme.white),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.white),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final productProvider = Provider.of<ProductProvider>(context, listen: false);
          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
          await productProvider.fetchCategories();
          await productProvider.fetchProducts();
          if (authProvider.token != null) {
            await orderProvider.fetchAddresses(authProvider.token!);
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Bar (Blinkit Style)
              Consumer<OrderProvider>(
                builder: (context, orderProvider, _) {
                  final defaultAddress = orderProvider.addresses.isNotEmpty
                      ? orderProvider.addresses.firstWhere(
                          (addr) => addr.isDefault,
                          orElse: () => orderProvider.addresses.first,
                        )
                      : null;

                  return Container(
                    width: double.infinity,
                    color: AppTheme.primaryGreen,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: GestureDetector(
                      onTap: () => context.push('/addresses'),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  defaultAddress != null
                                      ? 'Deliver to'
                                      : 'Add delivery address',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  defaultAddress != null
                                      ? defaultAddress.addressLine1.length > 40
                                          ? '${defaultAddress.addressLine1.substring(0, 40)}...'
                                          : defaultAddress.addressLine1
                                      : 'Tap to add address',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Search Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.white,
                child: GestureDetector(
                  onTap: () => context.push('/products'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppTheme.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search for products...',
                            style: TextStyle(
                              color: AppTheme.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(Icons.mic, color: AppTheme.grey, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              // Categories Section (Blinkit Style - Grid Layout)
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.categories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    color: AppTheme.white,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final responsive = Responsive(context);
                            final crossAxisCount = responsive.getCategoryGridColumns();
                            // Calculate aspect ratio based on screen size
                            final aspectRatio = constraints.maxWidth < 360 ? 0.95 : 0.9;
                            
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: aspectRatio,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: provider.categories.length > 8 ? 8 : provider.categories.length,
                              itemBuilder: (context, index) {
                                final category = provider.categories[index];
                                return _CategoryGridCard(category: category);
                              },
                            );
                          },
                        ),
                        if (provider.categories.length > 8)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(
                              child: TextButton(
                                onPressed: () => context.push('/products'),
                                child: const Text(
                                  'View All Categories',
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              // Products Section
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.products.isEmpty) {
                    return Container(
                      color: AppTheme.white,
                      padding: const EdgeInsets.all(48.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: AppTheme.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products available',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back soon!',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container(
                    color: AppTheme.white,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Featured Products',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/products'),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68, // Adjusted to prevent overflow
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: provider.products.length > 4 ? 4 : provider.products.length,
                          itemBuilder: (context, index) {
                            final product = provider.products[index];
                            return ProductCard(product: product);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Category Grid Card (Blinkit Style)
class _CategoryGridCard extends StatelessWidget {
  final CategoryModel category;

  const _CategoryGridCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 45.0 : 50.0;
    final fontSize = responsive.fontSize(11);
    
    return GestureDetector(
      onTap: () => context.push('/products?categoryId=${category.id}'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: category.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      category.imageUrl!,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.category,
                        size: responsive.iconSize(24),
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  )
                : Icon(
                    Icons.category,
                    size: responsive.iconSize(24),
                    color: AppTheme.primaryGreen,
                  ),
          ),
          SizedBox(height: screenWidth < 360 ? 4 : 6),
          Flexible(
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

