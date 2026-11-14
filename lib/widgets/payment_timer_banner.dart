import 'package:flutter/material.dart';
import '../services/payment_timer_service.dart';
import 'qr_payment_dialogs.dart';

/// A compact, animated countdown chip to be placed in the app's leading area
/// (or anywhere else in the UI) when the client has an active payment timer.
///
/// Shows green → orange → red as time runs out.
/// When time is up, shows a red "IMPAYÉ" badge.
/// Tapping it opens the QR code scanner to validate payment.
class PaymentTimerBanner extends StatelessWidget {
  const PaymentTimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PaymentTimerService(),
      builder: (context, _) {
        final timer = PaymentTimerService();

        // Don't show anything if no active timer and not blocked.
        if (!timer.hasActiveTimer && !timer.isBlocked) {
          return const SizedBox.shrink();
        }

        if (timer.isBlocked) {
          return const _BlockedChip();
        }

        return _CountdownChip(remaining: timer.remaining);
      },
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final Duration remaining;

  const _CountdownChip({required this.remaining});

  Color get _chipColor {
    final totalSeconds = remaining.inSeconds;
    if (totalSeconds > 60 * 90) return const Color(0xFF2E7D32); // green > 90 min
    if (totalSeconds > 60 * 30) return const Color(0xFFF57C00); // orange > 30 min
    return const Color(0xFFC62828); // red < 30 min
  }

  String get _label {
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '⏳ ${h}h${m}m${s}s';
    return '⏳ ${m}m${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Appuyez pour scanner le QR Code du caissier',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ClientQrScannerDialog.show(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _chipColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _chipColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _label,
                style: TextStyle(
                  color: _chipColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.qr_code_scanner_rounded, size: 12, color: _chipColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedChip extends StatelessWidget {
  const _BlockedChip();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Commande impayée : scannez le QR code de la caisse',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ClientQrScannerDialog.show(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade700, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 11, color: Colors.red.shade800),
              const SizedBox(width: 4),
              Text(
                'IMPAYÉ',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.qr_code_scanner_rounded, size: 12, color: Colors.red.shade800),
            ],
          ),
        ),
      ),
    );
  }
}
