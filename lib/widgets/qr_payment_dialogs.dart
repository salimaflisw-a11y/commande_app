import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/payment_timer_service.dart';

/// Helper formatting prefix for payment QR payload
const String kPaymentQrPrefix = 'RESTO_PAY:';

/// Generates the payload encoded in the cashier's QR code
String generatePaymentQrData(OrderModel order) {
  return '$kPaymentQrPrefix${order.id}';
}

/// Parses an order ID from the scanned QR string
String? parseOrderIdFromQr(String rawData) {
  final trimmed = rawData.trim();
  if (trimmed.startsWith(kPaymentQrPrefix)) {
    return trimmed.substring(kPaymentQrPrefix.length).trim();
  }
  // Also support JSON payload format
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      final map = jsonDecode(trimmed) as Map<String, dynamic>;
      if (map.containsKey('orderId')) return map['orderId']?.toString();
    } catch (_) {}
  }
  // Direct order ID fallback
  if (trimmed.isNotEmpty && !trimmed.contains(' ')) {
    return trimmed;
  }
  return null;
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. CASHIER MODAL: Displays the Payment QR Code to the client
// ══════════════════════════════════════════════════════════════════════════════
class CashierQrPaymentDialog extends StatelessWidget {
  final OrderModel order;

  const CashierQrPaymentDialog({super.key, required this.order});

  static Future<void> show(BuildContext context, OrderModel order) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CashierQrPaymentDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);
    final qrData = generatePaymentQrData(order);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_2_rounded,
                            color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'QR Code Caisse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                'Présentez ce QR Code au client pour valider son règlement et stopper le minuteur de 2 heures.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // Order details summary chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande : ${order.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Client : ${order.customerName} (${order.tableNumber ?? "Comptoir"})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${order.totalTtc.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 210.0,
                  gapless: false,
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(36, 36),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Manual Code for fallback
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.key_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Code de secours : ${order.id}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Cashier direct validation button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await OrderService().settlePaymentAndUnblock(order.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Paiement validé pour la commande ${order.id} ! Le minuteur a été stoppé.',
                          ),
                          backgroundColor: const Color(0xFF2E7D32),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'Encaisser manuellement en caisse',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. CLIENT MODAL: Scans the Cashier's QR Code to confirm payment & stop timer
// ══════════════════════════════════════════════════════════════════════════════
class ClientQrScannerDialog extends StatefulWidget {
  final String? targetOrderId;

  const ClientQrScannerDialog({super.key, this.targetOrderId});

  static Future<bool?> show(BuildContext context, {String? targetOrderId}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ClientQrScannerDialog(targetOrderId: targetOrderId),
    );
  }

  @override
  State<ClientQrScannerDialog> createState() => _ClientQrScannerDialogState();
}

class _ClientQrScannerDialogState extends State<ClientQrScannerDialog> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  final TextEditingController _manualInputController = TextEditingController();
  bool _isProcessing = false;
  bool _hasCameraError = false;
  String _cameraErrorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.targetOrderId != null) {
      _manualInputController.text = widget.targetOrderId!;
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _handleScannedCode(String rawCode) async {
    if (_isProcessing) return;

    final parsedOrderId = parseOrderIdFromQr(rawCode);
    if (parsedOrderId == null || parsedOrderId.isEmpty) {
      _showFeedback(
        'Format de QR Code invalide. Veuillez scanner le QR fourni par le caissier.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Settle payment in Firestore & unblock
      await OrderService().settlePaymentAndUnblock(parsedOrderId);

      // Stop the 2-hour payment countdown
      PaymentTimerService().clearTimer();

      if (!mounted) return;

      Navigator.of(context).pop(true);

      _showSuccessDialog(parsedOrderId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      _showFeedback('Erreur lors de la validation : $e', isError: true);
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28),
            SizedBox(width: 10),
            Text('Paiement Validé !', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Votre règlement pour la commande $orderId a été enregistré avec succès.\n\nLe minuteur de 2 heures a été arrêté et vous pouvez commander à nouveau !',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded,
                          color: primaryColor, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Scanner QR Caisse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Text(
                'Scannez le QR Code affiché par le caissier au comptoir pour valider votre paiement et stopper le minuteur.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
              ),
              const SizedBox(height: 16),

              // Camera viewfinder or fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!_hasCameraError)
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              final raw = barcode.rawValue;
                              if (raw != null && raw.isNotEmpty) {
                                _handleScannedCode(raw);
                                break;
                              }
                            }
                          },
                          errorBuilder: (context, error) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_hasCameraError) {
                                setState(() {
                                  _hasCameraError = true;
                                  _cameraErrorMessage = error.errorDetails?.message ??
                                      'Caméra non disponible sur cet appareil';
                                });
                              }
                            });
                            return _buildCameraFallback();
                          },
                        )
                      else
                        _buildCameraFallback(),

                      // Animated scan viewfinder frame overlay
                      if (!_hasCameraError)
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.center_focus_strong_rounded,
                              size: 48,
                              color: Colors.white70,
                            ),
                          ),
                        ),

                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Manual code entry fallback (ideal for desktop / testing)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualInputController,
                      decoration: InputDecoration(
                        hintText: 'Ou entrez le code / ID commande...',
                        hintStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            final val = _manualInputController.text.trim();
                            if (val.isNotEmpty) {
                              _handleScannedCode(val);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      color: const Color(0xFF263238),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40),
          const SizedBox(height: 10),
          const Text(
            'Caméra indisponible ou permissions requises',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _cameraErrorMessage.isNotEmpty
                ? _cameraErrorMessage
                : 'Utilisez la saisie manuelle ci-dessous avec le code fourni par le caissier.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

