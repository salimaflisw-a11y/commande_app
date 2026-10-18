import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/pdf_invoice_service.dart';
import 'pdf_preview_page.dart';
import 'client_orders_page.dart';
import 'catalog_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final OrderModel order;

  const OrderSuccessPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF263238), size: 28),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            // Success animation/icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF81C784), width: 3),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 60,
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Commande Confirmée !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Votre commande a été transmise en direct au responsable du restaurant.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF78909C),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Live transmission badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF80CBC4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.wifi_tethering, color: Color(0xFF00796B), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Transmise en cuisine en temps réel',
                    style: TextStyle(
                      color: Color(0xFF00796B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'N° de commande',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78909C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
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
                    ],
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow('Client', order.customerName),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Mode',
                    order.tableNumber != null && order.tableNumber!.isNotEmpty
                        ? '${order.orderType} (${order.tableNumber})'
                        : order.orderType,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Règlement', order.paymentMethod),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Articles', '${order.totalItemCount} article(s)'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total TTC payé',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                      Text(
                        '${order.totalTtc.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action: View PDF
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PdfPreviewPage(order: order),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                label: const Text(
                  'Consulter & Télécharger le Reçu PDF',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action: Share PDF directly
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => PdfInvoiceService.printOrShare(order),
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text(
                  'Partager / Imprimer le PDF',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF263238),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action: Order History / Return to menu
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ClientOrdersPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Historique'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF546E7A),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const CatalogPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                    label: const Text('Nouveau Menu'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF78909C)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF263238),
          ),
        ),
      ],
    );
  }
}
