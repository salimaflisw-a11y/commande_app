import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import 'order_service.dart';

/// Manages the 2-hour payment timer for the latest confirmed unpaid order.
///
/// - When an order is confirmed, call [startTimerForOrder].
/// - The deadline is stored in Firestore (`paymentDeadline` field) so it
///   survives page refreshes and browser reloads.
/// - [isBlocked] becomes true once the timer expires without payment.
/// - [remainingTime] ticks every second for the UI countdown.
class PaymentTimerService extends ChangeNotifier {
  static final PaymentTimerService _instance = PaymentTimerService._internal();
  factory PaymentTimerService() => _instance;
  PaymentTimerService._internal();

  static const Duration _paymentWindow = Duration(hours: 2);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// The order whose timer is currently running (or expired).
  OrderModel? _trackedOrder;
  OrderModel? get trackedOrder => _trackedOrder;

  /// Live countdown remaining.
  Duration _remaining = Duration.zero;
  Duration get remaining => _remaining;

  Timer? _ticker;

  /// True when the tracked order's timer has expired and it's still unpaid.
  bool get isBlocked {
    if (_trackedOrder == null) return false;
    if (_trackedOrder!.isPaid) return false;
    return _remaining == Duration.zero &&
        _trackedOrder!.paymentDeadline != null;
  }

  /// True when a valid countdown is running.
  bool get hasActiveTimer =>
      _trackedOrder != null &&
      !_trackedOrder!.isPaid &&
      _trackedOrder!.paymentDeadline != null &&
      _remaining > Duration.zero;

  /// Called from [OrderService] right after a new order is submitted.
  /// Writes the 2-hour deadline to Firestore and starts the local ticker.
  Future<void> startTimerForOrder(OrderModel order) async {
    // Don't restart if same order already tracked.
    if (_trackedOrder?.id == order.id && hasActiveTimer) return;

    final deadline = order.createdAt.add(_paymentWindow);

    // Persist deadline to Firestore.
    await _db.collection('orders').doc(order.id).update({
      'paymentDeadline': Timestamp.fromDate(deadline),
    });

    final updatedOrder = order.copyWith(paymentDeadline: deadline);
    _trackedOrder = updatedOrder;
    _startTicker(deadline);
    notifyListeners();
  }

  /// Called when the app detects an existing unpaid order with a stored
  /// deadline (e.g. after a page reload). Resumes the countdown.
  void resumeTimerForOrder(OrderModel order) {
    if (order.paymentDeadline == null) return;
    if (order.isPaid) return;
    // Don't restart if already tracking same order.
    if (_trackedOrder?.id == order.id && hasActiveTimer) return;

    _trackedOrder = order;
    _startTicker(order.paymentDeadline!);
    notifyListeners();
  }

  /// Call when the order is paid — clears the timer and unblocks.
  void clearTimer() {
    _ticker?.cancel();
    _ticker = null;
    _trackedOrder = null;
    _remaining = Duration.zero;
    notifyListeners();
  }

  void _startTicker(DateTime deadline) {
    _ticker?.cancel();
    _updateRemaining(deadline);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(deadline);
    });
  }

  void _updateRemaining(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    final prev = _remaining;
    _remaining = diff.isNegative ? Duration.zero : diff;

    if (_remaining != prev) {
      notifyListeners();
    }

    // When timer hits zero, also mark in OrderService if still unpaid.
    if (_remaining == Duration.zero && _trackedOrder != null && !_trackedOrder!.isPaid) {
      _ticker?.cancel();
      _ticker = null;
      _onTimerExpired();
    }
  }

  void _onTimerExpired() {
    if (_trackedOrder == null) return;
    debugPrint(
        '⏰ [PAYMENT TIMER] Timer expired for order ${_trackedOrder!.id} — client has unpaid orders!');
    // Mark in Firestore that client has an overdue unpaid order.
    OrderService().markClientLeftWithoutPaying(_trackedOrder!.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

