import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/payment_timer_service.dart';
import '../services/review_service.dart';
import '../widgets/qr_payment_dialogs.dart';
import 'client_orders_page.dart';
import 'catalog_page.dart';
import 'review_form_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final OrderModel order;

  const OrderSuccessPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Reçu de Commande',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF263238),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF263238), size: 26),
            tooltip: 'Retour au menu',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CatalogPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // ── Confirmation Badge ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Commande confirmée avec succès',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 2-Hour Payment Timer Banner ───────────────────────────────────
            ListenableBuilder(
              listenable: PaymentTimerService(),
              builder: (context, _) {
                final timer = PaymentTimerService();
                final remaining = timer.remaining;
                final h = remaining.inHours;
                final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
                final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
                final timeStr = h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.timer_outlined, color: Color(0xFFE65100), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Délai de règlement : $timeStr',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBF360C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Veuillez régler au comptoir dans les 2 heures. Passé ce délai, toute nouvelle commande sera bloquée.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5D4037),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                ClientQrScannerDialog.show(context, targetOrderId: order.id);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE65100),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.qr_code_scanner_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Scanner le QR Code caisse',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
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
            ),
            const SizedBox(height: 18),

            // ── DIGITAL RECEIPT CARD (REÇU) ─────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receipt Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'REÇU DE COMMANDE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            order.id,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF78909C)),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(order.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF78909C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Metadata Info (Client & Table)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Client',
                              style: TextStyle(fontSize: 11, color: Color(0xFF78909C)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.customerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ],
                        ),
                        if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEFF1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.table_restaurant_outlined,
                                    size: 16, color: Color(0xFF455A64)),
                                const SizedBox(width: 6),
                                Text(
                                  order.tableNumber!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF37474F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // Products List (Detail & Prices)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DÉTAIL DES ARTICLES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFF90A4AE),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...order.items.map((cartItem) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${cartItem.quantity}x ',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        cartItem.item.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF263238),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${cartItem.totalPrice.toStringAsFixed(2)} €',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF263238),
                                      ),
                                    ),
                                  ],
                                ),
                                if (cartItem.quantity > 1) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '(${cartItem.quantity} x ${cartItem.unitPrice.toStringAsFixed(2)} €)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF78909C),
                                    ),
                                  ),
                                ],
                                // Supplements detail
                                if (cartItem.supplements.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  ...cartItem.supplements.map((sup) => Padding(
                                        padding: const EdgeInsets.only(left: 14, top: 1),
                                        child: Text(
                                          '+ ${sup.name} ${sup.quantity > 1 ? 'x${sup.quantity} ' : ''}(+${sup.totalPrice.toStringAsFixed(2)} €)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF546E7A),
                                          ),
                                        ),
                                      )),
                                ],
                                // Removed ingredients
                                if (cartItem.removedIngredients.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Text(
                                      'Sans : ${cartItem.removedIngredients.join(', ')}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFFC62828),
                                      ),
                                    ),
                                  ),
                                ],
                                // Special instructions
                                if (cartItem.specialInstructions.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Text(
                                      'Note : ${cartItem.specialInstructions}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF78909C),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // Pricing Totals
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Column(
                      children: [
                        _buildPriceLine('Sous-total HT', '${order.subtotalHt.toStringAsFixed(2)} €'),
                        const SizedBox(height: 6),
                        _buildPriceLine('TVA (10%)', '${order.vatAmount.toStringAsFixed(2)} €'),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL TTC',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                            Text(
                              '${order.totalTtc.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Payment method footer note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      border: Border(top: BorderSide(color: Colors.amber.shade200)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.payment_outlined, size: 16, color: Color(0xFFE65100)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Paiement au comptoir après votre repas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Client Experience Evaluation Card ──
            ListenableBuilder(
              listenable: ReviewService(),
              builder: (context, _) {
                final isReviewed = ReviewService().isOrderReviewed(order.id);
                final existingReview = ReviewService().getReviewForOrder(order.id);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isReviewed ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isReviewed
                                  ? const Color(0xFFE8F5E9)
                                  : primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isReviewed ? Icons.check_circle_rounded : Icons.rate_review_rounded,
                              color: isReviewed ? const Color(0xFF2E7D32) : primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isReviewed
                                      ? 'Merci pour votre retour !'
                                      : 'Votre avis compte beaucoup !',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isReviewed
                                      ? 'Note enregistrée : ${existingReview?.overallRating.toStringAsFixed(1) ?? '5.0'}/5 ⭐'
                                      : 'Évaluez nourriture, service et rapidité en quelques clics',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ReviewFormPage.open(context, order: order);
                          },
                          icon: Icon(
                            isReviewed ? Icons.edit_outlined : Icons.star_rate_rounded,
                            size: 18,
                            color: isReviewed ? const Color(0xFF2E7D32) : primaryColor,
                          ),
                          label: Text(
                            isReviewed
                                ? 'Modifier mon évaluation'
                                : 'Évaluer mon expérience',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isReviewed ? const Color(0xFF2E7D32) : primaryColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isReviewed
                                  ? const Color(0xFFA5D6A7)
                                  : primaryColor.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: isReviewed
                                ? const Color(0xFFE8F5E9).withValues(alpha: 0.5)
                                : primaryColor.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── NAVIGATION ACTIONS ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ClientOrdersPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 20),
                label: const Text(
                  'Consulter Mes Commandes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const CatalogPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                label: const Text(
                  'Retour au Menu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF37474F),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildPriceLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF37474F),
          ),
        ),
      ],
    );
  }
}
