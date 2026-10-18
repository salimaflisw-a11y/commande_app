import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../screens/order_checkout_page.dart';

class CartSheet extends StatelessWidget {
  final Color primaryColor;

  const CartSheet({super.key, this.primaryColor = const Color(0xFFE65100)});

  static Future<void> show(
    BuildContext context, {
    Color primaryColor = const Color(0xFFE65100),
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => CartSheet(primaryColor: primaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService();
    final mediaQuery = MediaQuery.of(context);

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final items = cart.items;

        return Container(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.88,
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

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shopping_bag_outlined,
                          color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mon Panier',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        Text(
                          '${cart.itemCount} article(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78909C),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (items.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => cart.clear(),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Colors.red),
                        label: const Text(
                          'Vider',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Item list or empty state
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'Votre panier est vide',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF37474F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ajoutez des plats et personnalisez avec des suppléments',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF78909C),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final cartItem = items[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9FB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    cartItem.item.imageUrl,
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 65,
                                      height: 65,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.fastfood,
                                          size: 24, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cartItem.item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF263238),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${cartItem.unitPrice.toStringAsFixed(2)} € / unité',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // Customization summaries
                                      if (cartItem
                                          .removedIngredients.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sans: ${cartItem.removedIngredients.join(", ")}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      if (cartItem.supplements.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: cartItem.supplements
                                              .map((supp) => Text(
                                                    '+ ${supp.name} x${supp.quantity} (${supp.totalPrice.toStringAsFixed(2)} €)',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF2E7D32),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                      ] else if (cartItem
                                          .extraIngredients.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Extra: ${cartItem.extraIngredients.join(", ")}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      if (cartItem.specialInstructions
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Note: "${cartItem.specialInstructions}"',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFF78909C),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${cartItem.totalPrice.toStringAsFixed(2)} €',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF263238),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => cart.updateQuantity(
                                              cartItem.id,
                                              cartItem.quantity - 1),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                            child: Icon(
                                              cartItem.quantity == 1
                                                  ? Icons.delete_outline_rounded
                                                  : Icons.remove,
                                              size: 16,
                                              color: cartItem.quantity == 1
                                                  ? Colors.red
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text(
                                            '${cartItem.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => cart.updateQuantity(
                                              cartItem.id,
                                              cartItem.quantity + 1),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                            child: const Icon(Icons.add,
                                                size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Total, TVA and Checkout button
              if (items.isNotEmpty)
                Container(
                  padding: EdgeInsets.fromLTRB(
                      20, 14, 20, 14 + mediaQuery.padding.bottom),
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
                  child: Column(
                    children: [
                      // Financial breakdown with TVA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sous-total HT',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78909C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${cart.subtotalHt.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF546E7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TVA (10%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78909C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${cart.vatAmount.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF546E7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total TTC à payer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),
                          Text(
                            '${cart.totalTtc.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const OrderCheckoutPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Consulter l\'addition & Commander',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
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
      },
    );
  }
}
