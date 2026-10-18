import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

/// Fullscreen security overlay that locks the app over whatever page the client was on
/// if they leave the restaurant without paying for their table order.
class UnpaidBlockedOverlay extends StatelessWidget {
  final OrderModel order;

  const UnpaidBlockedOverlay({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Frosted blur effect over whatever page the client is currently viewing
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Container(
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),

            // Warning dialog card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade900.withValues(alpha: 0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.red.shade400,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Alert Banner
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade700, Colors.red.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_person_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'APPLICATION BLOQUÉE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'IMPAYÉ DÉTECTÉ — DÉPART SANS RÈGLEMENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Body message and bill details
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Vous avez quitté votre table sans régler votre commande au comptoir.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Conformément au règlement de l\'établissement, votre interface reste bloquée sur cette page et toute nouvelle commande est désactivée.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF546E7A),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Unpaid Order Receipt Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBE9E7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Column(
                                  children: [
                                    _buildReceiptRow('Commande :', order.id, isBold: true),
                                    const SizedBox(height: 6),
                                    _buildReceiptRow('Client :', order.customerName),
                                    const SizedBox(height: 6),
                                    _buildReceiptRow('Table :', order.tableNumber ?? 'Non précisée'),
                                    const SizedBox(height: 6),
                                    _buildReceiptRow('Mode paiement :', 'Paiement au comptoir'),
                                    const Divider(height: 18, color: Colors.red),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'TOTAL RESTANT DÛ :',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB71C1C),
                                          ),
                                        ),
                                        Text(
                                          '${order.totalTtc.toStringAsFixed(2)} €',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFFB71C1C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Instructions
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.storefront_rounded, size: 20, color: Colors.grey.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Veuillez vous présenter immédiatement au comptoir de la caisse pour régler votre note et débloquer votre accès.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade800,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Action to settle bill at counter (unblock)
                              ElevatedButton.icon(
                                onPressed: () {
                                  OrderService().settlePaymentAndUnblock(order.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Paiement comptoir de ${order.totalTtc.toStringAsFixed(2)} € enregistré. Accès rétabli !',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF2E7D32),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                                label: const Text(
                                  'Régler au comptoir (Débloquer l\'application)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF263238),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
