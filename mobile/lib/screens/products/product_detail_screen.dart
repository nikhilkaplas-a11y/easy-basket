import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_variant_model.dart';
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
  ProductVariantModel? _selectedVariant;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.fetchProductById(widget.productId);
      
      // Set default variant if product has variants
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final product = provider.products.firstWhere(
              (p) => p.id == widget.productId,
              orElse: () => provider.products.isNotEmpty ? provider.products.first : throw Exception('Product not found'),
            );
            if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
              final defaultVariant = product.variants!.firstWhere(
                (v) => v.isDefault,
                orElse: () => product.variants!.first,
              );
              setState(() {
                _selectedVariant = defaultVariant;
              });
            }
          }
        });
      }
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
        
        // Initialize default variant if not set and product has variants
        if (_selectedVariant == null && 
            product.hasVariants && 
            product.variants != null && 
            product.variants!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final defaultVariant = product.variants!.firstWhere(
                (v) => v.isDefault,
                orElse: () => product.variants!.first,
              );
              setState(() {
                _selectedVariant = defaultVariant;
              });
            }
          });
        }

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
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.lightGrey,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.lightGrey,
                            child: const Icon(Icons.image, size: 100, color: AppTheme.grey),
                          ),
                          fadeInDuration: const Duration(milliseconds: 400),
                        )
                      : Container(
                          color: AppTheme.lightGrey,
                          child: const Icon(Icons.image, size: 100, color: AppTheme.grey),
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
                      // Show price based on selected variant or base price
                      Text(
                        currencyFormat.format(
                          _selectedVariant?.price ?? product.price,
                        ),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          fontFamily: 'RoundedSans',
                        ),
                      ),
                      if (_selectedVariant != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedVariant!.label}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                      ],
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
                      // Variant Selection
                      if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) ...[
                        const Text(
                          'Select Quantity:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.variants!.where((v) => v.isAvailable).map((variant) {
                            final isSelected = _selectedVariant?.id == variant.id;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedVariant = variant;
                                  _quantity = 1; // Reset quantity when variant changes
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : AppTheme.lightGrey,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      variant.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.black,
                                        fontFamily: 'RoundedSans',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(variant.price),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? Colors.white70
                                            : AppTheme.primaryGreen,
                                        fontFamily: 'RoundedSans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (product.isAvailable && 
                          ((_selectedVariant != null && _selectedVariant!.stock > 0) || 
                           (_selectedVariant == null && product.stock > 0))) ...[
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
                                  onPressed: () {
                                    final maxStock = _selectedVariant?.stock ?? product.stock;
                                    if (_quantity < maxStock) {
                                      setState(() => _quantity++);
                                    }
                                  },
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
                              // Add item with variant if selected
                              for (int i = 0; i < _quantity; i++) {
                                await cartProvider.addItem(
                                  product,
                                  variant: _selectedVariant,
                                );
                              }
                              if (context.mounted) {
                                final variantLabel = _selectedVariant != null
                                    ? ' (${_selectedVariant!.label})'
                                    : '';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$_quantity x ${product.name}$variantLabel added to cart',
                                    ),
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
                              backgroundColor: AppTheme.primaryGreen,
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

