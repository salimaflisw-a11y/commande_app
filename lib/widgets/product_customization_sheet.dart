import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class AvailableSupplement {
  final String id;
  final String name;
  final String category;
  final String icon;
  final double price;

  const AvailableSupplement({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.price,
  });
}

class ProductCustomizationSheet extends StatefulWidget {
  final MenuItemModel item;
  final Color primaryColor;

  const ProductCustomizationSheet({
    super.key,
    required this.item,
    this.primaryColor = const Color(0xFFE65100),
  });

  static Future<void> show(
    BuildContext context, {
    required MenuItemModel item,
    Color primaryColor = const Color(0xFFE65100),
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => ProductCustomizationSheet(
        item: item,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<ProductCustomizationSheet> createState() =>
      _ProductCustomizationSheetState();
}

class _ProductCustomizationSheetState extends State<ProductCustomizationSheet> {
  late Set<String> _selectedBaseIngredients;
  final Map<String, int> _supplementQuantities = {};
  int _quantity = 1;
  String _selectedSupplementTab = 'Tous';
  final TextEditingController _noteController = TextEditingController();

  static const List<AvailableSupplement> _allAvailableSupplements = [
    // ── SAUCES ─────────────────────────────────────────────────────────────
    AvailableSupplement(
      id: 'sauce_alg',
      name: 'Sauce Algérienne',
      category: 'Sauces',
      icon: '🌶️',
      price: 0.50,
    ),
    AvailableSupplement(
      id: 'sauce_bbq',
      name: 'Sauce Barbecue Fumée',
      category: 'Sauces',
      icon: '🍯',
      price: 0.50,
    ),
    AvailableSupplement(
      id: 'sauce_mayo',
      name: 'Mayonnaise Gourmet',
      category: 'Sauces',
      icon: '🥚',
      price: 0.50,
    ),
    AvailableSupplement(
      id: 'sauce_fromage',
      name: 'Sauce Fromagère Maison',
      category: 'Sauces',
      icon: '🧀',
      price: 0.80,
    ),
    AvailableSupplement(
      id: 'sauce_ketchup',
      name: 'Ketchup Épicé',
      category: 'Sauces',
      icon: '🥫',
      price: 0.50,
    ),

    // ── FRITES & ACCOMPAGNEMENTS ───────────────────────────────────────────
    AvailableSupplement(
      id: 'frites_portion',
      name: 'Portion Frites Dorées',
      category: 'Frites & Accomp.',
      icon: '🍟',
      price: 2.00,
    ),
    AvailableSupplement(
      id: 'frites_cheddar',
      name: 'Frites Cheddar & Bacon',
      category: 'Frites & Accomp.',
      icon: '🥓',
      price: 3.50,
    ),
    AvailableSupplement(
      id: 'potatos',
      name: 'Potatos Épicées aux herbes',
      category: 'Frites & Accomp.',
      icon: '🥔',
      price: 2.50,
    ),
    AvailableSupplement(
      id: 'nuggets',
      name: 'Nuggets Croustillants (x4)',
      category: 'Frites & Accomp.',
      icon: '🍗',
      price: 2.80,
    ),
    AvailableSupplement(
      id: 'onion_rings',
      name: 'Onion Rings (x6)',
      category: 'Frites & Accomp.',
      icon: '🧅',
      price: 2.20,
    ),

    // ── BOISSONS ───────────────────────────────────────────────────────────
    AvailableSupplement(
      id: 'boisson_coca',
      name: 'Coca-Cola 33cl',
      category: 'Boissons',
      icon: '🥤',
      price: 1.80,
    ),
    AvailableSupplement(
      id: 'boisson_zero',
      name: 'Coca Zéro 33cl',
      category: 'Boissons',
      icon: '🥤',
      price: 1.80,
    ),
    AvailableSupplement(
      id: 'boisson_eau',
      name: 'Eau Minérale 50cl',
      category: 'Boissons',
      icon: '💧',
      price: 1.00,
    ),
    AvailableSupplement(
      id: 'boisson_orange',
      name: 'Jus d\'Orange Pressé Minute',
      category: 'Boissons',
      icon: '🍊',
      price: 2.50,
    ),
    AvailableSupplement(
      id: 'boisson_icetea',
      name: 'Ice Tea Pêche 33cl',
      category: 'Boissons',
      icon: '🍑',
      price: 1.80,
    ),

    // ── EXTRAS & FROMAGE ───────────────────────────────────────────────────
    AvailableSupplement(
      id: 'extra_cheddar',
      name: 'Double Cheddar Fondu',
      category: 'Extras',
      icon: '🧀',
      price: 1.00,
    ),
    AvailableSupplement(
      id: 'extra_bacon',
      name: 'Bacon Grillé Croustillant',
      category: 'Extras',
      icon: '🥓',
      price: 1.50,
    ),
    AvailableSupplement(
      id: 'extra_avocat',
      name: 'Tranches d\'Avocat Frais',
      category: 'Extras',
      icon: '🥑',
      price: 1.20,
    ),
    AvailableSupplement(
      id: 'extra_jalapeno',
      name: 'Piments Jalapeños Doux',
      category: 'Extras',
      icon: '🌶️',
      price: 0.60,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedBaseIngredients = Set.from(widget.item.ingredients);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _extrasTotal {
    double total = 0.0;
    for (final supp in _allAvailableSupplements) {
      final qty = _supplementQuantities[supp.id] ?? 0;
      total += supp.price * qty;
    }
    return total;
  }

  double get _unitPrice => widget.item.price + _extrasTotal;
  double get _totalPrice => _unitPrice * _quantity;

  int _getSupplementQty(String id) => _supplementQuantities[id] ?? 0;

  void _incrementSupplement(String id) {
    setState(() {
      _supplementQuantities[id] = (_supplementQuantities[id] ?? 0) + 1;
    });
  }

  void _decrementSupplement(String id) {
    setState(() {
      final current = _supplementQuantities[id] ?? 0;
      if (current > 1) {
        _supplementQuantities[id] = current - 1;
      } else {
        _supplementQuantities.remove(id);
      }
    });
  }

  void _onAddToCart() {
    final removed = widget.item.ingredients
        .where((ing) => !_selectedBaseIngredients.contains(ing))
        .toList();

    final selectedSupplements = <SupplementItem>[];
    for (final supp in _allAvailableSupplements) {
      final qty = _supplementQuantities[supp.id] ?? 0;
      if (qty > 0) {
        selectedSupplements.add(
          SupplementItem(
            id: supp.id,
            name: '${supp.icon} ${supp.name}',
            category: supp.category,
            unitPrice: supp.price,
            quantity: qty,
          ),
        );
      }
    }

    final cartItem = CartItemModel(
      id: '${widget.item.id}_${DateTime.now().millisecondsSinceEpoch}',
      item: widget.item,
      selectedIngredients: _selectedBaseIngredients.toList(),
      removedIngredients: removed,
      supplements: selectedSupplements,
      quantity: _quantity,
      specialInstructions: _noteController.text.trim(),
    );

    CartService().addItem(cartItem);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${widget.item.name} (${_quantity}x) ajouté au panier !',
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final primary = widget.primaryColor;
    final mediaQuery = MediaQuery.of(context);

    // Filter supplements by active category tab
    final displayedSupplements = _selectedSupplementTab == 'Tous'
        ? _allAvailableSupplements
        : _allAvailableSupplements
            .where((s) => s.category == _selectedSupplementTab)
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Scrollable details and customization content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image & Close button header ─────────────────────────────
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFFEEEEEE),
                              child: const Icon(Icons.fastfood,
                                  size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      if (item.isPopular)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Text(
                              '🔥 Populaire',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Title & Price Row ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.category.emoji} ${item.category.label}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_unitPrice.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          if (_extrasTotal > 0)
                            Text(
                              'Base: ${item.price.toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Rating & prep chips ─────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFA000),
                        text: '${item.rating} (${item.reviewsCount} avis)',
                      ),
                      _buildChip(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF1E88E5),
                        text: item.prepTime,
                      ),
                      _buildChip(
                        icon: Icons.local_fire_department_outlined,
                        iconColor: const Color(0xFFE53935),
                        text: '${item.calories} kcal',
                      ),
                      if (item.isVegetarian)
                        _buildChip(
                          icon: Icons.eco_rounded,
                          iconColor: const Color(0xFF43A047),
                          text: 'Végétarien',
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Description ─────────────────────────────────────────────
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF546E7A),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // ── SECTION 1: Base ingredients removal/keeping ──────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Personnaliser les ingrédients',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Retirez un ingrédient que vous ne souhaitez pas',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78909C),
                            ),
                          ),
                        ],
                      ),
                      if (item.ingredients.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedBaseIngredients.length ==
                                  item.ingredients.length) {
                                _selectedBaseIngredients.clear();
                              } else {
                                _selectedBaseIngredients =
                                    Set.from(item.ingredients);
                              }
                            });
                          },
                          child: Text(
                            _selectedBaseIngredients.length ==
                                    item.ingredients.length
                                ? 'Tout retirer'
                                : 'Tout remettre',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (item.ingredients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Recette prête sans ingrédients retirables.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF78909C)),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.ingredients.map((ingredient) {
                        final isIncluded =
                            _selectedBaseIngredients.contains(ingredient);
                        return FilterChip(
                          selected: isIncluded,
                          label: Text(ingredient),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isIncluded
                                ? const Color(0xFF263238)
                                : Colors.red.shade700,
                            decoration:
                                isIncluded ? null : TextDecoration.lineThrough,
                          ),
                          avatar: Icon(
                            isIncluded
                                ? Icons.check_circle_rounded
                                : Icons.remove_circle_outline,
                            size: 16,
                            color: isIncluded
                                ? const Color(0xFF2E7D32)
                                : Colors.red.shade400,
                          ),
                          selectedColor: const Color(0xFFE8F5E9),
                          backgroundColor: const Color(0xFFFFEBEE),
                          checkmarkColor: const Color(0xFF2E7D32),
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isIncluded
                                  ? const Color(0xFFC8E6C9)
                                  : Colors.red.shade200,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedBaseIngredients.add(ingredient);
                              } else {
                                _selectedBaseIngredients.remove(ingredient);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 22),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // ── SECTION 2: ADD SUPPLEMENTS WITH QUANTITY COUNTER ────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ajouter des suppléments',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sauces, frites, boissons & extras avec quantité modifiable',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78909C),
                            ),
                          ),
                        ],
                      ),
                      if (_extrasTotal > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${_extrasTotal.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Category filter pills for supplements
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Tous',
                        'Sauces',
                        'Frites & Accomp.',
                        'Boissons',
                        'Extras'
                      ].map((tab) {
                        final isSelected = _selectedSupplementTab == tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(tab),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF455A64),
                            ),
                            selected: isSelected,
                            selectedColor: primary,
                            backgroundColor: const Color(0xFFF1F3F5),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide.none,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedSupplementTab = tab);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Supplements List with individual +/- quantity counters
                  Column(
                    children: displayedSupplements.map((supp) {
                      final qty = _getSupplementQty(supp.id);
                      final isSelected = qty > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary.withValues(alpha: 0.06)
                              : const Color(0xFFF9F9FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? primary : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(supp.icon,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supp.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: const Color(0xFF263238),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+${supp.price.toStringAsFixed(2)} € / portion',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? primary
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Stepper for this specific supplement
                            if (qty == 0)
                              InkWell(
                                onTap: () => _incrementSupplement(supp.id),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded,
                                          size: 16, color: primary),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Ajouter',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF263238),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: primary, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          _decrementSupplement(supp.id),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(Icons.remove_rounded,
                                            size: 16, color: primary),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        '$qty',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _incrementSupplement(supp.id),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(Icons.add_rounded,
                                            size: 16, color: primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // ── SECTION 3: SPECIAL INSTRUCTIONS ──────────────────────────
                  const Text(
                    'Instructions spéciales (optionnel)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Ex: cuisson bien cuite, sans oignon, sauce à part...',
                      hintStyle:
                          TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF9F9FB),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // ── BOTTOM BAR WITH DISH QUANTITY & ADD TO CART ─────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + mediaQuery.padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Dish Quantity Stepper
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Button [Ajouter au panier]
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onAddToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Ajouter au panier',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${_totalPrice.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF455A64),
            ),
          ),
        ],
      ),
    );
  }
}
