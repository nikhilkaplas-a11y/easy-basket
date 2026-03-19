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
        setState(() {
          _fetchedProduct = fetched;
          if (fetched.hasVariants && fetched.variants != null && fetched.variants!.isNotEmpty) {
            _selectedVariant = fetched.variants!.firstWhere(
              (v) => v.isDefault,
              orElse: () => fetched.variants!.first,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F6F6),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),
          );
        }

        final product = _resolveProduct(provider);
        if (product == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F6F6),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.info_outline, size: 40, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Product unavailable right now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
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

        // Ensure a default variant is selected
        if (_selectedVariant == null &&
            product.hasVariants &&
            product.variants != null &&
            product.variants!.isNotEmpty) {
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
          backgroundColor: const Color(0xFFF6F6F6),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Green gradient behind status bar
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 123, 226, 127).withValues(alpha: 0.18),
                      const Color(0xFFF6F6F6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
              // Main content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: cartProvider.itemCount > 0 ? 200 : 110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image
                    _buildHeroSection(product),
                    const SizedBox(height: 12),
                    // Product info card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildProductInfoCard(product, currencyFormat),
                    ),
                    const SizedBox(height: 12),
                    // Variant section or single product info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: () {
                        final usableVariants = product.hasVariants && product.variants != null
                            ? product.variants!.where((v) => v.isAvailable).toList()
                            : <ProductVariantModel>[];
                        if (usableVariants.length > 1) {
                          return _buildVariantSection(product, cartProvider, currencyFormat);
                        }
                        return const SizedBox.shrink();
                      }(),
                    ),
                    const SizedBox(height: 12),
                    // Highlights
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildHighlightsRow(product),
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildDescription(product),
                    ),
                    if (_isDetailsMissing(product)) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: _buildFallbackNotice(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Info cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildInfoCards(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Floating Cart Bar
              if (cartProvider.itemCount > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 100,
                  child: const FloatingCartBar(),
                ),
              // Sticky CTA
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildStickyCta(product, cartProvider, currencyFormat),
              ),
            ],
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

  // ── Hero Section ──
  Widget _buildHeroSection(ProductModel product) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SizedBox(
        height: 300 + topPadding,
        width: double.infinity,
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: product.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFFF0F0F0),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFF0F0F0),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 48, color: AppTheme.grey),
                      SizedBox(height: 8),
                      Text('Image unavailable', style: TextStyle(color: AppTheme.grey)),
                    ],
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 72, color: AppTheme.grey),
                      SizedBox(height: 8),
                      Text('Image not available', style: TextStyle(color: AppTheme.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Product Info Card ──
  Widget _buildProductInfoCard(ProductModel product, NumberFormat currencyFormat) {
    final bool hasVariants = _hasUsableVariants(product);
    final List<ProductVariantModel> availableVariants = hasVariants
        ? product.variants!.where((v) => v.isAvailable).toList()
        : <ProductVariantModel>[];
    final double displayPrice = hasVariants && availableVariants.isNotEmpty
        ? (_selectedVariant?.price ?? availableVariants.first.price)
        : product.price;
    final String sizeLabel = hasVariants && availableVariants.isNotEmpty
        ? (_selectedVariant?.label ?? availableVariants.first.label)
        : _nonVariantLabel(product);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            product.name.isNotEmpty ? product.name : 'Product',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Price row
          Row(
            children: [
              Text(
                currencyFormat.format(displayPrice),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sizeLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkGrey),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: product.stock > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.stock > 0 ? 'In stock' : 'Limited',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: product.stock > 0 ? AppTheme.primaryGreen : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick info row
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              const Text('4.7', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text('(1.2k)', style: TextStyle(fontSize: 12, color: AppTheme.grey)),
              const SizedBox(width: 16),
              Icon(Icons.timer_outlined, size: 16, color: AppTheme.grey),
              const SizedBox(width: 4),
              Text('5-15 min', style: TextStyle(fontSize: 12, color: AppTheme.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Variant Section ──
  Widget _buildVariantSection(
    ProductModel product,
    CartProvider cartProvider,
    NumberFormat currencyFormat,
  ) {
    final variants = product.variants!.where((v) => v.isAvailable).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: variants.map((variant) {
              final isSelected = _selectedVariant?.id == variant.id;
              final originalPrice = variant.price * 1.1;
              final discountPercent = ((originalPrice - variant.price) / originalPrice * 100).round();
              final hasDiscount = discountPercent > 0;

              return GestureDetector(
                onTap: () => setState(() => _selectedVariant = variant),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0C831F) : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (hasDiscount)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C831F),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$discountPercent% OFF',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            currencyFormat.format(variant.price),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            Text(
                              currencyFormat.format(originalPrice),
                              style: TextStyle(fontSize: 11, color: AppTheme.grey, decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            variant.stock > 0 ? 'In stock' : 'Limited',
                            style: TextStyle(fontSize: 11, color: variant.stock > 0 ? AppTheme.grey : Colors.orange),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Color(0xFF0C831F), size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Highlights Row ──
  Widget _buildHighlightsRow(ProductModel product) {
    final highlights = [
      ('Delivery in 5-15 mins', Icons.delivery_dining_outlined, const Color(0xFFE8F5E9), AppTheme.primaryGreen),
      (product.stock > 20 ? 'Always fresh' : 'Restocking soon', Icons.eco_outlined, const Color(0xFFFFF3E0), Colors.orange),
      ('Easy returns', Icons.replay_outlined, const Color(0xFFE3F2FD), Colors.blue),
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
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: h.$3,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(h.$2, color: h.$4, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(h.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Description ──
  Widget _buildDescription(ProductModel product) {
    final description = (product.description != null && product.description!.trim().isNotEmpty)
        ? product.description!
        : 'Fresh groceries delivered quickly.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: AppTheme.darkGrey, height: 1.4),
            maxLines: _showFullDescription ? null : 4,
            overflow: _showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showFullDescription = !_showFullDescription),
            child: Text(
              _showFullDescription ? 'Show less' : 'Read more',
              style: const TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Cards ──
  Widget _buildInfoCards() {
    final items = [
      (Icons.delivery_dining_outlined, 'Fast delivery', 'Get it in minutes', const Color(0xFFE8F5E9), AppTheme.primaryGreen),
      (Icons.health_and_safety_outlined, 'Safe packaging', 'Tamper-proof, hygienic', const Color(0xFFE3F2FD), Colors.blue),
      (Icons.verified_user_outlined, 'Trusted quality', 'Checked by store team', const Color(0xFFFFF3E0), Colors.orange),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
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
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: item.$4,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.$1, color: item.$5, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(item.$3, style: TextStyle(fontSize: 11, color: AppTheme.grey)),
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

  // ── Fallback Notice ──
  Widget _buildFallbackNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, color: AppTheme.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Some details are missing for this product. You can still add it to cart.',
              style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky CTA ──
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
        : _nonVariantLabel(product);

    final bool nonVariantInCart = !hasVariants && cartProvider.contains(product.id);
    final int nonVariantQty = !hasVariants ? cartProvider.getQuantity(product.id) : 0;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            // Left — price info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sizeLabel.isNotEmpty ? sizeLabel : product.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  currencyFormat.format(displayPrice),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
                Text(
                  'Inclusive of all taxes',
                  style: TextStyle(fontSize: 10, color: AppTheme.grey),
                ),
              ],
            ),
            const Spacer(),
            // Right — action button
            if (isOutOfStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Out of stock',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              )
            else if (hasVariants && activeVariant != null)
              variantQuantity > 0
                  ? _buildQuantitySelector(
                      quantity: variantQuantity,
                      onDecrement: () async {
                        if (variantQuantity > 1) {
                          await cartProvider.updateQuantity(product.id, variantQuantity - 1, variantId: activeVariant.id);
                        } else {
                          await cartProvider.removeItem(product.id, variantId: activeVariant.id);
                        }
                        if (context.mounted) setState(() {});
                      },
                      onIncrement: variantQuantity < activeVariant.stock
                          ? () async {
                              await cartProvider.updateQuantity(product.id, variantQuantity + 1, variantId: activeVariant.id);
                              if (context.mounted) setState(() {});
                            }
                          : null,
                    )
                  : _buildAddToCartButton(
                      onPressed: () async {
                        await cartProvider.addItem(product, variant: activeVariant);
                        if (context.mounted) setState(() => _selectedVariant = activeVariant);
                      },
                    )
            else if (!hasVariants)
              nonVariantQty > 0
                  ? _buildQuantitySelector(
                      quantity: nonVariantQty,
                      onDecrement: () async {
                        if (nonVariantQty > 1) {
                          await cartProvider.updateQuantity(product.id, nonVariantQty - 1);
                        } else {
                          await cartProvider.removeItem(product.id);
                        }
                        setState(() => _quantity = nonVariantQty > 1 ? nonVariantQty - 1 : 1);
                      },
                      onIncrement: nonVariantQty < product.stock
                          ? () async {
                              await cartProvider.updateQuantity(product.id, nonVariantQty + 1);
                              setState(() => _quantity = nonVariantQty + 1);
                            }
                          : null,
                    )
                  : _buildAddToCartButton(
                      onPressed: () async {
                        await cartProvider.addItem(product);
                        setState(() => _quantity = cartProvider.getQuantity(product.id));
                      },
                    )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // ── Quantity Selector (dark green gradient) ──
  Widget _buildQuantitySelector({
    required int quantity,
    required VoidCallback onDecrement,
    VoidCallback? onIncrement,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A5C18), Color(0xFF1B8A2E), Color(0xFF0A5C18)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 40,
              height: 44,
              alignment: Alignment.center,
              child: const Text('–', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 40,
              height: 44,
              alignment: Alignment.center,
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: onIncrement != null ? Colors.white : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add to Cart Button (light green gradient with green border) ──
  Widget _buildAddToCartButton({required VoidCallback onPressed}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Colors.white, Color(0xFFE8F5E9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0C831F), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF0C831F).withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shopping_cart_outlined, size: 18, color: Color(0xFF0C831F)),
                SizedBox(width: 8),
                Text(
                  'Add to cart',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0C831F)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──
  String _nonVariantLabel(ProductModel product) {
    final name = product.name;
    final bracketMatch = RegExp(r'\(([^)]+)\)$').firstMatch(name);
    if (bracketMatch != null) {
      final content = bracketMatch.group(1)!.trim();
      if (content.isNotEmpty) return content;
    }
    if (product.minQuantity != null && product.unit != null) {
      final q = product.minQuantity!;
      final qStr = q % 1 == 0 ? q.toInt().toString() : q.toString();
      return '$qStr ${product.unit}';
    }
    if (product.unit != null) return '1 ${product.unit}';
    return '';
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
}
