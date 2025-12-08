import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.fetchProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      body: Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final product = provider.products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () {
            if (provider.products.isNotEmpty) {
              return provider.products.first;
            }
            return throw Exception('Product not found');
          },
        );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.lightGrey,
                            child: const Icon(Icons.image, size: 100),
                          ),
                        )
                      : Container(
                          color: AppTheme.lightGrey,
                          child: const Icon(Icons.image, size: 100),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RoundedSans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(product.price),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          fontFamily: 'RoundedSans',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (product.description != null) ...[
                        Text(
                          product.description!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.grey,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (product.category != null) ...[
                        Row(
                          children: [
                            const Spacer(),
                            Chip(
                              label: Text(product.category!.name),
                              backgroundColor: AppTheme.lightGrey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 8),
                      if (product.isAvailable && product.stock > 0) ...[
                        Row(
                          children: [
                            const Text(
                              'Quantity:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'RoundedSans',
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'RoundedSans',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: _quantity < product.stock
                                      ? () => setState(() => _quantity++)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              for (int i = 0; i < _quantity; i++) {
                                await cartProvider.addItem(product);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '$_quantity x ${product.name} added to cart'),
                                  ),
                                );
                                context.pop();
                              }
                            },
                            icon: const Icon(Icons.shopping_cart),
                            label: Text(
                              'Add ${_quantity > 1 ? "$_quantity " : ""}to Cart',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ] else
                        const Center(
                          child: Text(
                            'Product is currently out of stock',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontFamily: 'RoundedSans',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

