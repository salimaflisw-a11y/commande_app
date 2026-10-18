import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/pdf_invoice_service.dart';
import 'pdf_preview_page.dart';

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
                      'Vos commandes confirmées et leurs statuts apparaîtront ici.',
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
        border: order.clientLeftWithoutPaying
            ? Border.all(color: Colors.red.shade400, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: ID, Date & Status Chip ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEFF1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.tableNumber!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF455A64),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateFormat.format(order.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(order),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Delivered Order Payment Context Banner ─────────────────────────
          if (order.isDelivered) _buildPaymentContextBanner(order),

          // ── Ordered items preview ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: primaryColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.item.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF263238),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.totalPrice.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (order.items.length > 3)
                  Text(
                    '+ ${order.items.length - 3} autre(s) article(s)...',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF78909C),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Total & PDF Receipt Footer ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total TTC (${order.orderType})',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF78909C)),
                    ),
                    Text(
                      '${order.totalTtc.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: order.clientLeftWithoutPaying
                            ? Colors.red.shade700
                            : primaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20),
                      tooltip: 'Partager le ticket',
                      onPressed: () => PdfInvoiceService.printOrShare(order),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PdfPreviewPage(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('Reçu PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── RESPONSIBLE / ADMIN SIMULATION CONTROL PANEL ───────────────────
          _buildAdminSimulationPanel(context),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderModel order) {
    if (order.clientLeftWithoutPaying) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFC62828), size: 14),
            SizedBox(width: 4),
            Text(
              'Impayé (App bloquée)',
              style: TextStyle(
                color: Color(0xFFC62828),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (order.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded,
                color: Color(0xFFE65100), size: 14),
            SizedBox(width: 4),
            Text(
              'En attente',
              style: TextStyle(
                color: Color(0xFFE65100),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (order.isDelivered) {
      final isPaid = order.isPaid;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPaid
                  ? Icons.check_circle_rounded
                  : Icons.room_service_outlined,
              color: isPaid
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF1565C0),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isPaid ? 'Livrée & Payée' : 'Livrée à table',
              style: TextStyle(
                color: isPaid
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1565C0),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // Rejetée
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFC62828), size: 14),
            SizedBox(width: 4),
            Text(
              'Rejetée',
              style: TextStyle(
                color: Color(0xFFC62828),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPaymentContextBanner(OrderModel order) {
    if (order.clientLeftWithoutPaying) {
      return Container(
        color: const Color(0xFFFFEBEE),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFC62828), size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Client parti sans payer au comptoir. Application bloquée !',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC62828),
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  OrderService().settlePaymentAndUnblock(order.id),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 26),
              ),
              child: const Text('Régler', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (order.isPaid) {
      return Container(
        color: const Color(0xFFE8F5E9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Note réglée au comptoir après le repas. Merci !',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Delivered & Unpaid (Currently eating)
    return Container(
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.restaurant_rounded, color: Color(0xFFF57F17), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plat servi à table (En dégustation) • Paiement au comptoir après le repas',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSimulationPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        dense: true,
        leading: const Icon(Icons.admin_panel_settings_rounded,
            color: Color(0xFF455A64), size: 20),
        title: const Text(
          'Contrôles Responsable / Admin',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
        subtitle: Text(
          'Statut: ${order.status} | Paiement: ${order.paymentStatus}',
          style: const TextStyle(fontSize: 10, color: Color(0xFF78909C)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '1. Statut Commande (Admin) :',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildAdminChoiceChip(
                      context,
                      label: 'En attente',
                      isSelected: order.status == 'En attente',
                      color: const Color(0xFFE65100),
                      onTap: () => OrderService()
                          .updateOrderStatus(order.id, 'En attente'),
                    ),
                    const SizedBox(width: 6),
                    _buildAdminChoiceChip(
                      context,
                      label: 'Livrée',
                      isSelected: order.status == 'Livrée',
                      color: const Color(0xFF1565C0),
                      onTap: () => OrderService()
                          .updateOrderStatus(order.id, 'Livrée'),
                    ),
                    const SizedBox(width: 6),
                    _buildAdminChoiceChip(
                      context,
                      label: 'Rejetée',
                      isSelected: order.status == 'Rejetée',
                      color: const Color(0xFFC62828),
                      onTap: () => OrderService()
                          .updateOrderStatus(order.id, 'Rejetée'),
                    ),
                  ],
                ),

                if (order.status == 'Livrée') ...[
                  const SizedBox(height: 12),
                  const Text(
                    '2. Statut Paiement (Table livrée) :',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildAdminChoiceChip(
                        context,
                        label: '⏳ Non payée (unpaid)',
                        isSelected: order.paymentStatus == 'unpaid' &&
                            !order.clientLeftWithoutPaying,
                        color: const Color(0xFFE65100),
                        onTap: () => OrderService()
                            .updatePaymentStatus(order.id, 'unpaid'),
                      ),
                      const SizedBox(width: 6),
                      _buildAdminChoiceChip(
                        context,
                        label: '💳 Payée (paid)',
                        isSelected: order.paymentStatus == 'paid',
                        color: const Color(0xFF2E7D32),
                        onTap: () => OrderService()
                            .updatePaymentStatus(order.id, 'paid'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '3. Sécurité / Impayé :',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (!order.clientLeftWithoutPaying)
                    ElevatedButton.icon(
                      onPressed: () {
                        OrderService().markClientLeftWithoutPaying(order.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Alerte: Client parti sans payer ! Application verrouillée.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      icon: const Icon(Icons.report_problem_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Simuler : Client parti sans payer (Bloquer l\'app)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        OrderService().settlePaymentAndUnblock(order.id);
                      },
                      icon: const Icon(Icons.check_circle_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Régler au comptoir (Débloquer l\'application)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminChoiceChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF37474F),
            ),
          ),
        ),
      ),
    );
  }
}
