import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.payment_outlined, size: 14, color: Color(0xFFE65100)),
                      SizedBox(width: 4),
                      Text(
                        'Paiement au comptoir',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
