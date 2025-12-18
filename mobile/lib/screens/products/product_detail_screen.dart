import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/floating_cart_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  ProductVariantModel? _selectedVariant;
  bool _showFullDescription = false;
  ProductModel? _fetchedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final fetched = await provider.fetchProductById(widget.productId);
      if (mounted && fetched != null) {
        // Set fetched product and choose default variant from fetched data only (no provider list assumptions)
        setState(() {
          _fetchedProduct = fetched;
          if (fetched.hasVariants && fetched.variants != null && fetched.variants!.isNotEmpty) {
            _selectedVariant = fetched.variants!.firstWhere(
                (v) => v.isDefault,
              orElse: () => fetched.variants!.first,
              );
          }
        });
        // ignore: avoid_print
        print('[ProductDetail] fetched product id=${fetched.id}, name=${fetched.name}');
      } else if (mounted) {
        // ignore: avoid_print
        print('[ProductDetail] fetch returned null for id=${widget.productId}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final double heroHeight = 280;
    // ignore: avoid_print
    print('[ProductDetail][build] start build for productId=${widget.productId}, fetched=${_fetchedProduct != null}');

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final product = _resolveProduct(provider);
        if (product == null) {
          // ignore: avoid_print
          print('[ProductDetail][build] product is null. products=${provider.products.length}, error=${provider.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: AppTheme.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Product unavailable right now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'products=${provider.products.length}, fetched=${_fetchedProduct != null}, error=${provider.error ?? 'none'}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await provider.fetchProductById(widget.productId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Ensure a default variant is selected when variants exist
        if (_selectedVariant == null && 
            product.hasVariants && 
            product.variants != null && 
            product.variants!.isNotEmpty) {
          // ignore: avoid_print
          print('[ProductDetail][build] selecting default variant for productId=${product.id}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedVariant = product.variants!.firstWhere(
                (v) => v.isDefault,
                orElse: () => product.variants!.first,
              );
              });
            }
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.lightGrey,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
                leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.black),
                  onPressed: () => context.pop(),
                ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: AppTheme.black),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: cartProvider.itemCount > 0 ? 200 : 110, // Extra padding when cart bar is visible
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: _buildHeroSection(product, currencyFormat),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildCompactEssentials(product, currencyFormat),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            if (_hasUsableVariants(product))
                              _buildVariantSection(product, cartProvider, currencyFormat)
                            else
                              _buildNoVariantInfo(product, currencyFormat),
                            const SizedBox(height: 16),
                            _buildHighlightsRow(product),
                            const SizedBox(height: 16),
                            _buildDescription(product),
                            if (_isDetailsMissing(product)) ...[
                              const SizedBox(height: 12),
                              _buildFallbackNotice(),
                            ],
                            const SizedBox(height: 16),
                            _buildInfoCards(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating Cart Bar (above sticky CTA when cart has items)
                if (cartProvider.itemCount > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 90, // Position above sticky CTA (which is ~90px tall)
                    child: const FloatingCartBar(),
                  ),
                // Sticky Add to Cart CTA
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildStickyCta(product, cartProvider, currencyFormat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ProductModel? _resolveProduct(ProductProvider provider) {
    if (_fetchedProduct != null) return _fetchedProduct;
    if (provider.products.isEmpty) return null;
    try {
      return provider.products.firstWhere((p) => p.id == widget.productId);
    } catch (_) {
      return provider.products.first;
    }
  }

  // Blinkit-style quantity selector for variants
  Widget _buildVariantQuantitySelector(
    BuildContext context,
    CartProvider cartProvider,
    product,
    ProductVariantModel variant,
    int quantity,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          GestureDetector(
            onTap: () async {
              if (quantity > 1) {
                await cartProvider.updateQuantity(product.id, quantity - 1, variantId: variant.id);
              } else {
                await cartProvider.removeItem(product.id, variantId: variant.id);
              }
              if (context.mounted) {
                setState(() {});
              }
            },
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          // Quantity display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              quantity.toString(),
                          style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
          ),
          // Increment button
          GestureDetector(
            onTap: () async {
              if (quantity < variant.stock) {
                await cartProvider.updateQuantity(product.id, quantity + 1, variantId: variant.id);
                if (context.mounted) {
                  setState(() {});
                }
              }
            },
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: quantity < variant.stock ? Colors.white : Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: quantity < variant.stock ? AppTheme.primaryGreen : AppTheme.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ProductModel product, NumberFormat currencyFormat) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Image unavailable', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEEF8EE), Color(0xFFE3F2FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 72, color: AppTheme.grey),
                  SizedBox(height: 8),
                        Text(
                    'Image not available',
                          style: TextStyle(
                            color: AppTheme.grey,
                      fontSize: 14,
                            fontFamily: 'RoundedSans',
                    ),
                  ),
                ],
                        ),
                ),
              ),
        // Light gradient only to keep UI clean for Tier 3 audience
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black26],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleCard(ProductModel product, NumberFormat currencyFormat) {
    final bool hasVariants = product.hasVariants && (product.variants?.isNotEmpty ?? false);
    final double displayPrice = hasVariants
        ? (_selectedVariant?.price ?? product.variants!.first.price)
        : product.price;
    final String safeName = (product.name.isNotEmpty) ? product.name : 'Product';
                          
                          return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
        borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                      safeName,
                        style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                          fontFamily: 'RoundedSans',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          '4.7',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1.2k ratings',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!hasVariants)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                    currencyFormat.format(displayPrice),
                                              style: const TextStyle(
                      fontSize: 18,
                                                fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            fontFamily: 'RoundedSans',
                                              ),
                                            ),
                                          ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill(text: 'Best Seller', icon: Icons.local_fire_department_outlined, color: Colors.orange),
              if (product.baseUnit != null)
                _buildPill(text: product.baseUnit!, icon: Icons.scale_outlined, color: Colors.blueGrey),
              _buildPill(
                text: product.stock > 15 ? 'Fresh Stock' : 'Limited Stock',
                icon: Icons.eco_outlined,
                color: AppTheme.primaryGreen,
                                        ),
                                    ],
                                  ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip(ProductModel product, NumberFormat currencyFormat) {
    final bool hasVariants = _hasUsableVariants(product);
    final List<ProductVariantModel> availableVariants = hasVariants
        ? product.variants!.where((v) => v.isAvailable).toList()
        : <ProductVariantModel>[];
    final double displayPrice = hasVariants && availableVariants.isNotEmpty
        ? (_selectedVariant?.price ?? availableVariants.first.price)
        : product.price;
    final String sizeLabel = hasVariants && availableVariants.isNotEmpty
        ? (_selectedVariant?.label ?? availableVariants.first.label)
        : (product.unit ?? 'unit');
    // ignore: avoid_print
    print('[ProductDetail][render] summary strip productId=${product.id}, price=$displayPrice, size=$sizeLabel, variants=$hasVariants');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                  product.name.isNotEmpty ? product.name : 'Product',
                                          style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                                            fontFamily: 'RoundedSans',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPill(
                      text: sizeLabel,
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.lightGrey,
                      foreground: AppTheme.darkGrey,
                    ),
                    _buildPill(
                      text: '5-15 min',
                      icon: Icons.timer_outlined,
                      color: AppTheme.primaryYellow,
                      foreground: Colors.black,
                    ),
                    _buildPill(
                      text: product.stock > 0 ? 'In stock' : 'Limited',
                      icon: Icons.check_circle_outline,
                      color: product.stock > 0 ? AppTheme.primaryGreen : Colors.orangeAccent,
                      foreground: product.stock > 0 ? AppTheme.black : Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                currencyFormat.format(displayPrice),
                                              style: const TextStyle(
                  fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryGreen,
                                                fontFamily: 'RoundedSans',
                                              ),
                                            ),
              const SizedBox(height: 4),
                                              Text(
                product.stock > 0 ? 'In stock' : 'Limited',
                                                style: TextStyle(
                                                  fontSize: 13,
                  color: product.stock > 0 ? AppTheme.grey : Colors.orange,
                                                  fontFamily: 'RoundedSans',
                                                ),
                                              ),
                                            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsRow(ProductModel product) {
    final List<String> highlights = [
      'Delivery in 5-15 mins',
      product.stock > 20 ? 'Always fresh' : 'Restocking soon',
      'Easy returns',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: highlights
          .map(
            (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    h,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDescription(ProductModel product) {
    final description = (product.description != null && product.description!.trim().isNotEmpty)
        ? product.description!
        : 'Fresh groceries delivered quickly.';
    final textStyle = TextStyle(
                            fontSize: 14,
      color: AppTheme.darkGrey,
                            fontFamily: 'RoundedSans',
                            height: 1.4,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'RoundedSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: textStyle,
            maxLines: _showFullDescription ? null : 4,
            overflow: _showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showFullDescription = !_showFullDescription),
            child: Text(
              _showFullDescription ? 'Show less' : 'Read more',
              style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
                fontFamily: 'RoundedSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSection(
    ProductModel product,
    CartProvider cartProvider,
    NumberFormat currencyFormat,
  ) {
    final variants = product.variants!.where((v) => v.isAvailable).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                        const Text(
          'Select Unit',
                          style: TextStyle(
                            fontSize: 16,
            fontWeight: FontWeight.w700,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: variants.map((variant) {
                          final isSelected = _selectedVariant?.id == variant.id;
            final originalPrice = variant.price * 1.1;
                          final discountPercent = ((originalPrice - variant.price) / originalPrice * 100).round();
                          final hasDiscount = discountPercent > 0;
                          
            return GestureDetector(
              onTap: () {
                                              setState(() {
                                                _selectedVariant = variant;
                                              });
              },
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.lightGrey.withOpacity(0.8),
                                width: isSelected ? 2 : 1,
                              ),
                  boxShadow: const [
                                BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [const Color(0xFFE8F5E9), const Color(0xFFDFF4FF)]
                        : [Colors.white, Colors.white],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                    Row(
                                    children: [
                        Expanded(
                          child: Text(
                            variant.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'RoundedSans',
                            ),
                          ),
                        ),
                                      if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                                          borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                              '$discountPercent% OFF',
                                              style: const TextStyle(
                                                color: Colors.white,
                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'RoundedSans',
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                    const SizedBox(height: 8),
                    Row(
                                          children: [
                                            Text(
                                              currencyFormat.format(variant.price),
                                              style: const TextStyle(
                            fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryGreen,
                                                fontFamily: 'RoundedSans',
                                              ),
                                            ),
                                              const SizedBox(width: 6),
                        if (hasDiscount)
                                              Text(
                                                currencyFormat.format(originalPrice),
                                                style: TextStyle(
                              fontSize: 12,
                                                  color: AppTheme.grey,
                                                  decoration: TextDecoration.lineThrough,
                                                  fontFamily: 'RoundedSans',
                                                ),
                                              ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      variant.stock > 0 ? 'In stock' : 'Limited',
                      style: TextStyle(
                        fontSize: 12,
                        color: variant.stock > 0 ? AppTheme.grey : Colors.orange,
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: isSelected
                          ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18)
                          : const SizedBox.shrink(),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
        ),
      ],
    );
  }

  Widget _buildSimpleQuantitySection(ProductModel product, CartProvider cartProvider) {
    if (!product.isAvailable || product.stock <= 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
                                            child: Text(
            'Product is currently out of stock',
                                              style: TextStyle(
              fontSize: 16,
              color: Colors.red,
                                                fontFamily: 'RoundedSans',
                                              ),
                                            ),
                                          ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                                                color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
            'Quantity',
                                style: TextStyle(
                                  fontSize: 16,
              fontWeight: FontWeight.w700,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                                children: [
                                  IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
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
                      icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (_quantity < product.stock) {
                                        setState(() => _quantity++);
                                      }
                                    },
                                  ),
                                ],
                              ),
              ),
              const Spacer(),
              _buildPrimaryCta(
                label: 'Add ${_quantity > 1 ? "$_quantity " : ""}to Cart',
                              onPressed: () async {
                                for (int i = 0; i < _quantity; i++) {
                                  await cartProvider.addItem(product);
                                }
                              },
                                    ),
                                ],
                              ),
        ],
      ),
    );
  }

  Widget _buildNoVariantInfo(ProductModel product, NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
          const SizedBox(height: 6),
                          Row(
                            children: [
              Text(
                currencyFormat.format(product.price),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
              const SizedBox(width: 10),
              _buildPill(
                text: product.unit ?? 'unit',
                icon: Icons.inventory_2_outlined,
                color: AppTheme.lightGrey,
                foreground: AppTheme.darkGrey,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            product.stock > 0 ? 'In stock' : 'Limited',
                                style: TextStyle(
              fontSize: 13,
              color: product.stock > 0 ? AppTheme.grey : Colors.orange,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
          const SizedBox(height: 8),
          Text(
            'Use the Add to cart bar below to choose quantity.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.grey,
              fontFamily: 'RoundedSans',
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildStickyCta(
    ProductModel product,
    CartProvider cartProvider,
    NumberFormat currencyFormat,
  ) {
    final bool hasVariants = _hasUsableVariants(product);
    final List<ProductVariantModel> availableVariants = hasVariants
        ? product.variants!.where((v) => v.isAvailable).toList()
        : <ProductVariantModel>[];
    final ProductVariantModel? activeVariant = hasVariants
        ? (_selectedVariant ??
            (availableVariants.isNotEmpty ? availableVariants.first : product.variants!.first))
        : null;

    final int variantQuantity = hasVariants && activeVariant != null
        ? (cartProvider.contains(product.id, variantId: activeVariant.id)
            ? cartProvider.getQuantity(product.id, variantId: activeVariant.id)
            : 0)
        : 0;

    final bool isOutOfStock = hasVariants
        ? (activeVariant == null || activeVariant.stock <= 0)
        : (!product.isAvailable || product.stock <= 0);

    final double displayPrice = hasVariants && activeVariant != null
        ? activeVariant.price
        : product.price;

    final String sizeLabel = hasVariants && activeVariant != null
        ? activeVariant.label
        : (product.unit ?? '');

    final bool nonVariantInCart = !hasVariants && cartProvider.contains(product.id);
    final int nonVariantQty = !hasVariants ? cartProvider.getQuantity(product.id) : 0;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
                            children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sizeLabel.isNotEmpty ? sizeLabel : product.name,
                  style: const TextStyle(
                    fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'RoundedSans',
                                ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(displayPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
        color: AppTheme.primaryGreen,
                    fontFamily: 'RoundedSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Inclusive of all taxes',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.grey,
                    fontFamily: 'RoundedSans',
                ),
              ),
            ],
                              ),
                              const Spacer(),
            if (isOutOfStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Out of stock',
                                style: TextStyle(
                                  color: Colors.red,
                    fontWeight: FontWeight.w700,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
              )
            else if (hasVariants && activeVariant != null)
              variantQuantity > 0
                  ? _buildVariantQuantitySelector(
                      context,
                      cartProvider,
                      product,
                      activeVariant,
                      variantQuantity,
                    )
                  : _buildPrimaryCta(
                      label: 'Add to cart',
                      onPressed: () async {
                        await cartProvider.addItem(product, variant: activeVariant);
                        if (context.mounted) {
                          setState(() {
                            _selectedVariant = activeVariant;
                          });
                        }
                      },
                    )
            else if (!hasVariants)
              nonVariantQty > 0
                  ? Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey,
                            borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () async {
                                  if (nonVariantQty > 1) {
                                    await cartProvider.updateQuantity(product.id, nonVariantQty - 1);
                                    setState(() {
                                      _quantity = nonVariantQty - 1;
                                    });
              } else {
                                    await cartProvider.removeItem(product.id);
                                    setState(() {
                                      _quantity = 1;
                                    });
                                  }
                                },
                              ),
                              Text(
                                '$nonVariantQty',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: nonVariantQty < product.stock
                                    ? () async {
                                        await cartProvider.updateQuantity(product.id, nonVariantQty + 1);
                                        setState(() {
                                          _quantity = nonVariantQty + 1;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _buildPrimaryCta(
                      label: 'Add to cart',
                      onPressed: () async {
                        await cartProvider.addItem(product);
                        setState(() {
                          _quantity = cartProvider.getQuantity(product.id);
                        });
                      },
                    )
            else
              const SizedBox.shrink(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCards() {
    final items = [
      (Icons.delivery_dining_outlined, 'Fast delivery', 'Get it in minutes'),
      (Icons.health_and_safety_outlined, 'Safe packaging', 'Tamper-proof, hygienic'),
      (Icons.verified_user_outlined, 'Trusted quality', 'Checked by store team'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Container(
              width: 180,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$1, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
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
            ),
          )
          .toList(),
    );
  }

  Widget _buildAddButton(Future<void> Function() onTap) {
    return Container(
      width: 110,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
                Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'ADD TO CART',
                  style: TextStyle(
                color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RoundedSans',
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required String text,
    required IconData icon,
    Color color = const Color(0xFFE8F5E9),
    Color foreground = AppTheme.black,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
              fontFamily: 'RoundedSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.shopping_cart_outlined, size: 20),
        label: Text(
          label,
              style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
                fontFamily: 'RoundedSans',
              ),
            ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
        ),
      ),
    );
  }

  bool _isDetailsMissing(ProductModel product) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    final hasDescription = product.description != null && product.description!.trim().isNotEmpty;
    return !hasImage || !hasDescription;
  }

  bool _hasUsableVariants(ProductModel product) {
    return product.hasVariants &&
        product.variants != null &&
        product.variants!.isNotEmpty &&
        product.variants!.any((v) => v.isAvailable);
  }

  Widget _buildDebugStrip(ProductProvider provider) {
    final String status =
        'products=${provider.products.length}, fetched=${_fetchedProduct != null}, error=${provider.error ?? 'none'}';
    return Container(
      width: double.infinity,
      color: Colors.black12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.bug_report, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Some details are missing for this product. You can still add it to cart.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkGrey,
                fontFamily: 'RoundedSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialsCard(ProductModel product, NumberFormat currencyFormat) {
    final bool hasVariants = _hasUsableVariants(product);
    final List<ProductVariantModel> availableVariants = hasVariants
        ? product.variants!.where((v) => v.isAvailable).toList()
        : <ProductVariantModel>[];
    final double displayPrice = hasVariants && availableVariants.isNotEmpty
        ? (_selectedVariant?.price ?? availableVariants.first.price)
        : product.price;
    final String sizeLabel = hasVariants && availableVariants.isNotEmpty
        ? (_selectedVariant?.label ?? availableVariants.first.label)
        : (product.unit ?? 'unit');
    // ignore: avoid_print
    print('[ProductDetail][render] essentials card productId=${product.id}, price=$displayPrice, size=$sizeLabel, variants=$hasVariants');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
                color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name.isNotEmpty ? product.name : 'Product',
              style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'RoundedSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(displayPrice),
            style: const TextStyle(
              fontSize: 20,
                fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
                fontFamily: 'RoundedSans',
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildPill(
                text: sizeLabel,
                icon: Icons.inventory_2_outlined,
                color: AppTheme.lightGrey,
                foreground: AppTheme.darkGrey,
              ),
              const SizedBox(width: 8),
              _buildPill(
                text: product.stock > 0 ? 'In stock' : 'Limited',
                icon: Icons.check_circle_outline,
                color: product.stock > 0 ? AppTheme.primaryGreen : Colors.orangeAccent,
                foreground: product.stock > 0 ? AppTheme.black : Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (product.description != null && product.description!.trim().isNotEmpty)
                ? product.description!
                : 'Available for quick delivery.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.grey,
              fontFamily: 'RoundedSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEssentials(ProductModel product, NumberFormat currencyFormat) {
    final bool hasVariants = _hasUsableVariants(product);
    final List<ProductVariantModel> availableVariants = hasVariants
        ? product.variants!.where((v) => v.isAvailable).toList()
        : <ProductVariantModel>[];
    final double displayPrice = hasVariants && availableVariants.isNotEmpty
        ? (_selectedVariant?.price ?? availableVariants.first.price)
        : product.price;
    final String sizeLabel = hasVariants && availableVariants.isNotEmpty
        ? (_selectedVariant?.label ?? availableVariants.first.label)
        : (product.unit ?? 'unit');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
                color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name.isNotEmpty ? product.name : 'Product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'RoundedSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sizeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.grey,
                    fontFamily: 'RoundedSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock: ${product.stock > 0 ? product.stock : 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: product.stock > 0 ? AppTheme.darkGrey : Colors.orange,
                    fontFamily: 'RoundedSans',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(displayPrice),
                style: const TextStyle(
                  fontSize: 18,
                fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                fontFamily: 'RoundedSans',
              ),
            ),
              const SizedBox(height: 4),
              _buildPill(
                text: product.stock > 0 ? 'In stock' : 'Limited',
                icon: Icons.check_circle_outline,
                color: product.stock > 0 ? AppTheme.primaryGreen : Colors.orangeAccent,
                foreground: product.stock > 0 ? AppTheme.black : Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildDataCard(ProductModel product, NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug snapshot',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkGrey,
              fontFamily: 'RoundedSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'id: ${product.id} | name: ${product.name}',
            style: TextStyle(fontSize: 13, color: AppTheme.darkGrey, fontFamily: 'RoundedSans'),
          ),
          Text(
            'price: ${currencyFormat.format(product.price)} | unit: ${product.unit ?? 'n/a'} | stock: ${product.stock}',
            style: TextStyle(fontSize: 13, color: AppTheme.darkGrey, fontFamily: 'RoundedSans'),
          ),
          Text(
            'hasVariants: ${product.hasVariants} | variants count: ${product.variants?.length ?? 0}',
            style: TextStyle(fontSize: 13, color: AppTheme.darkGrey, fontFamily: 'RoundedSans'),
          ),
        ],
      ),
    );
  }
}
