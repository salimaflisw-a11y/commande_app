import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import 'cart_service.dart';

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders);

  OrderModel? get latestOrder => _orders.isNotEmpty ? _orders.first : null;

  /// Check if client is blocked because they left without paying for an order
  bool get isCurrentClientBlocked =>
      _orders.any((o) => o.clientLeftWithoutPaying);

  /// The unpaid order that triggered the block
  OrderModel? get blockingUnpaidOrder =>
      _orders.where((o) => o.clientLeftWithoutPaying).firstOrNull;

  /// Creates and submits a new order, transmitting it to the restaurant manager
  Future<OrderModel> submitOrder({
    required String customerName,
    required String customerPhone,
    required String orderType,
    String? tableNumber,
    String? deliveryAddress,
    required String paymentMethod,
    String specialNotes = '',
    List<CartItemModel>? cartItems,
  }) async {
    final cart = CartService();
    final itemsToOrder = cartItems ?? List<CartItemModel>.from(cart.items);

    if (itemsToOrder.isEmpty) {
      throw Exception('Impossible de valider une commande vide');
    }

    // Order number generation
    final now = DateTime.now();
    final orderNumber =
        'CMD-${now.year}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final totalTtc =
        itemsToOrder.fold(0.0, (sum, item) => sum + item.totalPrice);
    const vatRate = 0.10; // 10%
    final subtotalHt = totalTtc / (1.0 + vatRate);
    final vatAmount = totalTtc - subtotalHt;

    final order = OrderModel(
      id: orderNumber,
      createdAt: now,
      customerName:
          customerName.trim().isEmpty ? 'Client Invité' : customerName.trim(),
      customerPhone:
          customerPhone.trim().isEmpty ? 'Non renseigné' : customerPhone.trim(),
      orderType: orderType,
      tableNumber: tableNumber,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      specialNotes: specialNotes.trim(),
      items: itemsToOrder,
      subtotalHt: subtotalHt,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalTtc: totalTtc,
      // 1. Initial status for admin: 'En attente'
      status: 'En attente',
      // 2. Client pays after eating at the table: 'unpaid'
      paymentStatus: 'unpaid',
      clientLeftWithoutPaying: false,
      isSentToManager: true,
    );

    // Simulate instant real-time network sync with Firebase / Restaurant Manager backend
    await Future.delayed(const Duration(milliseconds: 600));

    _orders.insert(0, order);
    cart.clear();
    notifyListeners();

    debugPrint(
        '🔔 [ADMIN COMMANDE] Reçue (${order.status}) : ${order.id} | Client: ${order.customerName} | Table: ${order.tableNumber ?? "N/A"} | Paiement: ${order.paymentStatus}');

    return order;
  }

  /// Admin sets order status: 'En attente', 'Livrée', 'Rejetée'
  void updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      notifyListeners();
      debugPrint('🔔 [ADMIN STATUS CHANGE] Commande $orderId -> $newStatus');
    }
  }

  /// Admin / Server sets payment status for delivered table order: 'paid' or 'unpaid'
  void updatePaymentStatus(String orderId, String newPaymentStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final wasBlocked = _orders[index].clientLeftWithoutPaying;
      _orders[index] = _orders[index].copyWith(
        paymentStatus: newPaymentStatus,
        clientLeftWithoutPaying:
            newPaymentStatus == 'paid' ? false : wasBlocked,
      );
      notifyListeners();
      debugPrint(
          '💳 [ADMIN PAYMENT STATUS] Commande $orderId -> $newPaymentStatus');
    }
  }

  /// Triggered if the client leaves without paying: freezes the app immediately!
  void markClientLeftWithoutPaying(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: 'Livrée',
        paymentStatus: 'unpaid',
        clientLeftWithoutPaying: true,
      );
      notifyListeners();
      debugPrint(
          '🚨 [ALERTE SÉCURITÉ RESTAURANT] Client parti sans payer pour la commande $orderId ! Application bloquée.');
    }
  }

  /// Client settles the bill at the counter: unblocks the app and marks order as paid
  void settlePaymentAndUnblock(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        paymentStatus: 'paid',
        clientLeftWithoutPaying: false,
      );
      notifyListeners();
      debugPrint(
          '✅ [PAIEMENT COMPTOIR EFFECTUÉ] Commande $orderId réglée au comptoir. Application débloquée.');
    }
  }
}
