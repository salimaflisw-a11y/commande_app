import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/review_service.dart';
import '../widgets/qr_payment_dialogs.dart';
import 'review_form_page.dart';

class ClientOrdersPage extends StatelessWidget {
  const ClientOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);
    final orderService = OrderService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'Mes Commandes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF263238),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: const Color(0xFF263238),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined, color: primaryColor, size: 22),
            tooltip: 'Donner mon avis',
            onPressed: () {
              ReviewFormPage.open(context);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListenableBuilder(
        listenable: orderService,
        builder: (context, _) {
          final orders = orderService.orders;

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_outlined,
                          size: 48, color: primaryColor),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Aucune commande passée',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vos commandes passées et leurs reçus apparaîtront ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF78909C)),
                    ),
                  ],
                ),
              ),
            );
          }

          final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(
                order: order,
                primaryColor: primaryColor,
                dateFormat: dateFormat,
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final Color primaryColor;
  final DateFormat dateFormat;

  const _OrderCard({
    required this.order,
    required this.primaryColor,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: ID, Table & Date/Time ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF263238),
                          ),
                        ),
                        if (order.tableNumber != null &&
                            order.tableNumber!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEFF1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.tableNumber!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF455A64),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: Color(0xFF78909C)),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(order.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF78909C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reçu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Products List with Details & Prices ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.quantity}x ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: primaryColor,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.item.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.totalPrice.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ],
                        ),
                        if (item.quantity > 1) ...[
                          const SizedBox(height: 1),
                          Text(
                            '(${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} €)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF78909C),
                            ),
                          ),
                        ],
                        if (item.supplements.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          ...item.supplements.map((sup) => Padding(
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
                        if (item.removedIngredients.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Text(
                              'Sans : ${item.removedIngredients.join(', ')}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFFC62828),
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
          const Divider(height: 1),

          // ── Total Summary Footer ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total TTC (Sur place)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF78909C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.totalTtc.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (order.isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
                            SizedBox(width: 4),
                            Text(
                              'Payée',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
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
                              SizedBox(width: 4),
                              Text(
                                'Scanner QR Caisse',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'À régler au comptoir',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Review / Evaluation Button ──
          ListenableBuilder(
            listenable: ReviewService(),
            builder: (context, _) {
              final isReviewed = ReviewService().isOrderReviewed(order.id);
              final existingReview = ReviewService().getReviewForOrder(order.id);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isReviewed ? const Color(0xFFF1F8E9) : const Color(0xFFFFF8E1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isReviewed ? Icons.check_circle_outline_rounded : Icons.star_rate_rounded,
                      size: 18,
                      color: isReviewed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isReviewed
                            ? 'Avis enregistré : ${existingReview?.overallRating.toStringAsFixed(1) ?? '5.0'}/5 ⭐'
                            : 'Donner mon avis sur cette expérience',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isReviewed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ReviewFormPage.open(context, order: order);
                      },
                      icon: Icon(
                        isReviewed ? Icons.edit_outlined : Icons.rate_review_outlined,
                        size: 14,
                        color: isReviewed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      ),
                      label: Text(
                        isReviewed ? 'Modifier' : 'Évaluer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isReviewed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
