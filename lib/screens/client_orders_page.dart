import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                      child: Icon(Icons.receipt_long_outlined, size: 48, color: primaryColor),
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
                      'Vos commandes confirmées et leurs factures PDF apparaîtront ici.',
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
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = orders[index];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Card header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF263238),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(order.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF78909C),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle_outline, color: Color(0xFF00796B), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Transmise',
                                  style: TextStyle(
                                    color: Color(0xFF00796B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Ordered items preview
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...order.items.take(3).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
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

                    // Total & PDF Actions footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total TTC (${order.orderType})',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF78909C)),
                              ),
                              Text(
                                '${order.totalTtc.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share_outlined, size: 20),
                                tooltip: 'Partager le PDF',
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
                                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                                label: const Text('Reçu PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
