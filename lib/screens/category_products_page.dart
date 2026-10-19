import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../services/cart_service.dart';
import '../services/menu_service.dart';
import '../widgets/product_customization_sheet.dart';
import '../widgets/cart_sheet.dart';
import 'client_orders_page.dart';

class CategoryProductsPage extends StatelessWidget {
  final CategoryInfo category;

  const CategoryProductsPage({super.key, required this.category});

  List<MenuItemModel> _items(MenuService menu) =>
      menu.getItemsByCategory(category);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    return ListenableBuilder(
      listenable: MenuService(),
      builder: (context, _) {
        final items = _items(MenuService());

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9FB),
          body: CustomScrollView(
            slivers: [
          // ── Sliver App Bar with category banner image ──────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            actions: [
              // Cart icon button with real-time badge
              ListenableBuilder(
                listenable: CartService(),
                builder: (context, _) {
                  final count = CartService().itemCount;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: 'Voir le panier',
                        onPressed: () => CartSheet.show(
                          context,
                          primaryColor: primaryColor,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Mes Commandes',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClientOrdersPage()),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 14),
              title: Text(
                '${category.emoji} ${category.label}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    category.bannerImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: primaryColor.withValues(alpha: 0.7),
                      child: Center(
                        child: Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Subtitle pill ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.subtitle,
                        style: const TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Section heading ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Nos produits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Product cards ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductCard(
                  item: items[index],
                  primaryColor: primaryColor,
                ),
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
      // Bottom banner floating button when cart has items
      bottomNavigationBar: ListenableBuilder(
        listenable: CartService(),
        builder: (context, _) {
          final count = CartService().itemCount;
          if (count == 0) return const SizedBox.shrink();
          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              10 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => CartSheet.show(
                context,
                primaryColor: primaryColor,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Voir le panier',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${CartService().totalAmount.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
        },
      );
  }
}

// ── Individual product card ──────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final MenuItemModel item;
  final Color primaryColor;

  const _ProductCard({required this.item, required this.primaryColor});

  void _openCustomizationPopup(BuildContext context) {
    ProductCustomizationSheet.show(
      context,
      item: item,
      primaryColor: primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCustomizationPopup(context),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left image ─────────────────────────────────────────
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: 120,
                      height: 125,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF0F1F3),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          color: const Color(0xFFEEEEEE),
                          child: Center(
                            child: Icon(Icons.fastfood_outlined,
                                color: Colors.grey.shade400, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Right content ───────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges row
                          if (item.isPopular || item.isVegetarian)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  if (item.isPopular)
                                    _Badge(
                                      label: '🔥 Populaire',
                                      bg: const Color(0xFFFFF3E0),
                                      fg: primaryColor,
                                    ),
                                  if (item.isPopular && item.isVegetarian)
                                    const SizedBox(width: 6),
                                  if (item.isVegetarian)
                                    const _Badge(
                                      label: '🌿 Végé',
                                      bg: Color(0xFFE8F5E9),
                                      fg: Color(0xFF2E7D32),
                                    ),
                                ],
                              ),
                            ),

                          // Name
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Description
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78909C),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Rating + prep time
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: Color(0xFFFFC107)),
                              const SizedBox(width: 2),
                              Text(
                                item.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF37474F),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '(${item.reviewsCount})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF90A4AE),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.schedule_outlined,
                                  size: 13, color: Color(0xFF90A4AE)),
                              const SizedBox(width: 2),
                              Text(
                                item.prepTime,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF90A4AE),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Action Footer: Price & [Add to panier] button ─────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFB),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price tag
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prix unitaire',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF90A4AE),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${item.price.toStringAsFixed(2)} €',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),

                    // [Add to pannier] button
                    ElevatedButton.icon(
                      onPressed: () => _openCustomizationPopup(context),
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Ajouter au panier',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
