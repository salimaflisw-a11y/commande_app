import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import 'cart_service.dart';
import 'payment_timer_service.dart';

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal() {
    listenToOrders();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSubscription;

  List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders);
  OrderModel? get latestOrder => _orders.isNotEmpty ? _orders.first : null;

  /// Check if the current client is blocked (left without paying)
  bool get isCurrentClientBlocked =>
      _orders.any((o) => o.clientLeftWithoutPaying);

  /// The unpaid order that triggered the block
  OrderModel? get blockingUnpaidOrder =>
      _orders.where((o) => o.clientLeftWithoutPaying).firstOrNull;

  /// True when the client has any confirmed unpaid order (regardless of timer).
  bool get hasAnyUnpaidOrder =>
      _orders.any((o) => o.isUnpaid && !o.isRejected);

  /// Start listening to orders in real time.
  /// Pass [forUserId] to filter by client; omit to get all (admin mode).
  void listenToOrders({String? forUserId}) {
    _ordersSubscription?.cancel();

    Query<Map<String, dynamic>> query = _db
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (forUserId != null) {
      query = query.where('customerId', isEqualTo: forUserId);
    }

    _ordersSubscription = query.snapshots().listen((snapshot) {
      _orders = snapshot.docs.map((doc) {
        return OrderModel.fromJson({...doc.data(), 'id': doc.id});
      }).toList();

      // Auto-resume countdown for any existing unpaid order that has a deadline stored.
      _autoResumePaymentTimer();

      // Clear timer if the latest tracked order was paid.
      _autoClearTimerIfPaid();

      notifyListeners();
    }, onError: (e) {
      debugPrint('⚠️ [OrderService] Firestore listen error: $e');
    });
  }

  /// Auto-resumes the payment countdown for any unpaid order that already has
  /// a stored deadline (e.g. after a browser refresh).
  void _autoResumePaymentTimer() {
    final timerService = PaymentTimerService();
    final unpaidWithDeadline = _orders.where(
      (o) => o.isUnpaid && o.paymentDeadline != null && !o.clientLeftWithoutPaying,
    );
    if (unpaidWithDeadline.isNotEmpty) {
      timerService.resumeTimerForOrder(unpaidWithDeadline.first);
    }
  }

  /// Clears the payment timer when the tracked order has been marked as paid.
  void _autoClearTimerIfPaid() {
    final timerService = PaymentTimerService();
    final tracked = timerService.trackedOrder;
    if (tracked == null) return;
    final inFirestore = _orders.where((o) => o.id == tracked.id).firstOrNull;
    if (inFirestore != null && inFirestore.isPaid) {
      timerService.clearTimer();
    }
  }

  /// Generates a secure, human-readable cashier validation code (e.g. SEC-8K2A)
  static String generateSecurityCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random();
    final buffer = StringBuffer('SEC-');
    for (var i = 0; i < 4; i++) {
      buffer.write(chars[rnd.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  /// Creates and submits a new order to Firestore
  Future<OrderModel> submitOrder({
    required String customerName,
    required String customerPhone,
    required String orderType,
    String? tableNumber,
    String? deliveryAddress,
    required String paymentMethod,
    String specialNotes = '',
    List<CartItemModel>? cartItems,
    String? customerId,
  }) async {
    final cart = CartService();
    final itemsToOrder = cartItems ?? List<CartItemModel>.from(cart.items);

    if (itemsToOrder.isEmpty) {
      throw Exception('Impossible de valider une commande vide');
    }

    final now = DateTime.now();
    final totalTtc =
        itemsToOrder.fold(0.0, (acc, item) => acc + item.totalPrice);
    const vatRate = 0.10;
    final subtotalHt = totalTtc / (1.0 + vatRate);
    final vatAmount = totalTtc - subtotalHt;
    final securityCode = generateSecurityCode();

    final orderData = <String, dynamic>{
      'createdAt': Timestamp.fromDate(now),
      'customerName':
          customerName.trim().isEmpty ? 'Client Invité' : customerName.trim(),
      'customerPhone':
          customerPhone.trim().isEmpty ? 'Non renseigné' : customerPhone.trim(),
      'customerId': customerId ?? '',
      'orderType': orderType,
      'tableNumber': tableNumber,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'specialNotes': specialNotes.trim(),
      'items': itemsToOrder.map((i) => i.toJson()).toList(),
      'subtotalHt': subtotalHt,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalTtc': totalTtc,
      'status': 'En attente',
      'paymentStatus': 'unpaid',
      'clientLeftWithoutPaying': false,
      'isSentToManager': true,
      'paymentSecurityCode': securityCode,
    };

    // Save to Firestore — auto-generates a document ID
    final docRef = await _db.collection('orders').add(orderData);

    final order = OrderModel.fromJson({
      ...orderData,
      'id': docRef.id,
      'createdAt': now.toIso8601String(), // fromJson accepts ISO string too
    });

    cart.clear();
    notifyListeners();

    // Start the 2-hour payment countdown for this new order.
    await PaymentTimerService().startTimerForOrder(order);

    debugPrint(
        '🔔 [ADMIN COMMANDE] Reçue (${order.status}) : ${order.id} | '
        'Client: ${order.customerName} | Table: ${order.tableNumber ?? "N/A"} | '
        'Paiement: ${order.paymentStatus} | Code caisse: $securityCode');

    return order;
  }

  /// Admin sets order status: 'En attente', 'Livrée', 'Rejetée'
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({'status': newStatus});
    debugPrint('🔔 [ADMIN STATUS CHANGE] Commande $orderId -> $newStatus');
  }

  /// Admin / Server sets payment status: 'paid' or 'unpaid'
  Future<void> updatePaymentStatus(
      String orderId, String newPaymentStatus) async {
    final updates = <String, dynamic>{'paymentStatus': newPaymentStatus};
    if (newPaymentStatus == 'paid') {
      updates['clientLeftWithoutPaying'] = false;
    }
    await _db.collection('orders').doc(orderId).update(updates);
    debugPrint(
        '💳 [ADMIN PAYMENT STATUS] Commande $orderId -> $newPaymentStatus');
  }

  /// Triggered if the client leaves without paying: freezes the app
  Future<void> markClientLeftWithoutPaying(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'Livrée',
      'paymentStatus': 'unpaid',
      'clientLeftWithoutPaying': true,
    });
    debugPrint(
        '🚨 [ALERTE SÉCURITÉ RESTAURANT] Client parti sans payer pour $orderId !');
  }

  /// Ensures that an order has a payment security code (generates and persists one if missing).
  Future<String> ensurePaymentSecurityCode(OrderModel order) async {
    if (order.paymentSecurityCode != null &&
        order.paymentSecurityCode!.trim().isNotEmpty) {
      return order.paymentSecurityCode!;
    }
    final newCode = generateSecurityCode();
    await _db.collection('orders').doc(order.id).update({
      'paymentSecurityCode': newCode,
    });
    return newCode;
  }

  /// Client settles the bill at the cashier: validates the cashier security code against Firestore.
  /// Strictly prevents unauthorized clients from unblocking orders with fake scans.
  Future<void> settlePaymentWithVerification({
    required String orderId,
    required String securityCode,
  }) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (!doc.exists) {
      throw Exception('Commande introuvable dans le système (#$orderId).');
    }

    final data = doc.data()!;
    final currentPaymentStatus = data['paymentStatus'] as String? ?? 'unpaid';
    if (currentPaymentStatus == 'paid') {
      PaymentTimerService().clearTimer();
      return; // Already paid
    }

    final storedSecurityCode = data['paymentSecurityCode'] as String?;
    final cleanInputCode = securityCode.trim().toUpperCase();

    if (storedSecurityCode == null || storedSecurityCode.trim().isEmpty) {
      // Legacy order with no security code yet: require cashier direct action
      throw Exception(
        'Cette commande nécessite une validation directe par le caissier au comptoir.',
      );
    }

    if (storedSecurityCode.trim().toUpperCase() != cleanInputCode) {
      throw Exception(
        'Code de sécurité caisse incorrect. Veuillez scanner le QR Code officiel présenté par le caissier.',
      );
    }

    // Security check passed: mark order as paid and unblock
    await _db.collection('orders').doc(orderId).update({
      'paymentStatus': 'paid',
      'clientLeftWithoutPaying': false,
    });
    PaymentTimerService().clearTimer();
    debugPrint(
        '✅ [PAIEMENT VALIDÉ PAR QR CAISSE] Commande $orderId réglée avec le code $cleanInputCode.');
  }

  /// Cashier settles the bill directly from the POS / Admin tablet
  Future<void> settlePaymentAndUnblock(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'paymentStatus': 'paid',
      'clientLeftWithoutPaying': false,
    });
    PaymentTimerService().clearTimer();
    debugPrint(
        '✅ [PAIEMENT COMPTOIR EFFECTUÉ] Commande $orderId réglée. Application débloquée.');
  }
}
