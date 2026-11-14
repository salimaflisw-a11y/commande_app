import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../widgets/cart_sheet.dart';
import '../widgets/auth_popup.dart';
import '../widgets/payment_timer_banner.dart';
import 'category_products_page.dart';
import 'client_orders_page.dart';
import 'admin_dashboard_page.dart';
import 'review_form_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // Currently selected category (null = All categories)
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Admin cannot access client menu - automatically redirect to AdminDashboardPage
    if (AuthService().isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prevent rendering client menu for admin
    if (AuthService().isAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    const primaryColor = Color(0xFFE65100);

    return PopScope(
      canPop: false,
      child: ListenableBuilder(
        listenable: MenuService(),
        builder: (context, _) {
          final allCategories = MenuService().categories;
          final displayedCategories = _selectedCategory == null
              ? allCategories
              : allCategories.where((c) => c.id == _selectedCategory!.id).toList();

          return Scaffold(
            backgroundColor: const Color(0xFFF9F9FB),
            appBar: _buildAppBar(primaryColor),
            body: Column(
              children: [
                // Top Menu with category name buttons
                _buildTopCategoryButtonsMenu(primaryColor, allCategories),

                // Category Banners List (no products, disabled "Consulter" button)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: displayedCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final category = displayedCategories[index];
                      return _buildCategoryBannerCard(category, primaryColor);
                    },
                  ),
                ),
              ],
            ),
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
),
);
}

  AppBar _buildAppBar(Color primaryColor) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant, color: Color(0xFFE65100), size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Menu Numérique',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF263238),
                ),
              ),
              Text(
                'Catégories du restaurant',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const PaymentTimerBanner(),
        ],
      ),
      actions: [
        ListenableBuilder(
          listenable: CartService(),
          builder: (context, _) {
            final count = CartService().itemCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF263238), size: 26),
                  tooltip: 'Voir le panier',
                  onPressed: () => CartSheet.show(context, primaryColor: primaryColor),
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
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
          icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF263238), size: 24),
          tooltip: 'Mes Commandes',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClientOrdersPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.rate_review_outlined, color: Color(0xFF263238), size: 24),
          tooltip: 'Donner votre avis',
          onPressed: () {
            ReviewFormPage.open(context);
          },
        ),
        ListenableBuilder(
          listenable: AuthService(),
          builder: (context, _) {
            final auth = AuthService();
            if (!auth.isLoggedIn) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TextButton.icon(
                  onPressed: () async {
                    final ok = await AuthPopup.show(context, primaryColor: primaryColor);
                    if (ok == true && context.mounted && AuthService().isAdmin) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Connexion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: PopupMenuButton<String>(
                tooltip: 'Mon Compte Client',
                onSelected: (val) {
                  if (val == 'logout') {
                    AuthService().logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Déconnexion réussie. Mode Visiteur activé.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                        ),
                        Text(
                          auth.currentUser?.email ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Se déconnecter', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: primaryColor,
                        child: Text(
                          (auth.displayName.isNotEmpty)
                              ? auth.displayName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        auth.displayName.split(' ').first,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  /// Top Menu with buttons of the names for the categories
  Widget _buildTopCategoryButtonsMenu(Color primaryColor, List<CategoryModel> allCategories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 42,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            // "Toutes les catégories" button
            _buildCategoryMenuButton(
              title: '✨ Tous',
              isSelected: _selectedCategory == null,
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(width: 8),

            // Specific Category Buttons from Firestore / defaults
            ...allCategories.map((cat) {
              final isSelected = _selectedCategory?.id == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryMenuButton(
                  title: '${cat.emoji} ${cat.label}',
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryProductsPage(category: cat),
                      ),
                    );
                  },
                  primaryColor: primaryColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }



  Widget _buildCategoryMenuButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF37474F),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// Big Category Banner with background photo, title, subtitle and disabled [Consulter] button
  Widget _buildCategoryBannerCard(CategoryModel cat, Color primaryColor) {
    return Container(
      height: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryProductsPage(category: cat),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              _buildSafeImage(cat.bannerImageUrl, cat),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),

          // Content inside the banner
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cat.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // [Consulter] button - active look, takes you nowhere
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CategoryProductsPage(category: cat),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Consulter',
                                style: TextStyle(
                                  color: Color(0xFF263238),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, color: Color(0xFFE65100), size: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom Title & Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cat.emoji} ${cat.label}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
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

  Widget _buildSafeImage(String url, CategoryModel cat) {
    if (url.trim().isEmpty) {
      return Container(
        color: const Color(0xFFEEEEEE),
        child: Center(
          child: Text(
            cat.emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFF0F1F3),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE65100)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFEEEEEE),
          child: Center(
            child: Text(
              cat.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        );
      },
    );
  }
}
