import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import 'cart_service.dart';

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
      notifyListeners();
    }, onError: (e) {
      debugPrint('⚠️ [OrderService] Firestore listen error: $e');
    });
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

    debugPrint(
        '🔔 [ADMIN COMMANDE] Reçue (${order.status}) : ${order.id} | '
        'Client: ${order.customerName} | Table: ${order.tableNumber ?? "N/A"} | '
        'Paiement: ${order.paymentStatus}');

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

  /// Client settles the bill: unblocks the app and marks order as paid
  Future<void> settlePaymentAndUnblock(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'paymentStatus': 'paid',
      'clientLeftWithoutPaying': false,
    });
    debugPrint(
        '✅ [PAIEMENT COMPTOIR EFFECTUÉ] Commande $orderId réglée. Application débloquée.');
  }
}
