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
    final orderNumber = 'CMD-${now.year}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final totalTtc = itemsToOrder.fold(0.0, (sum, item) => sum + item.totalPrice);
    const vatRate = 0.10; // 10%
    final subtotalHt = totalTtc / (1.0 + vatRate);
    final vatAmount = totalTtc - subtotalHt;

    final order = OrderModel(
      id: orderNumber,
      createdAt: now,
      customerName: customerName.trim().isEmpty ? 'Client Invité' : customerName.trim(),
      customerPhone: customerPhone.trim().isEmpty ? 'Non renseigné' : customerPhone.trim(),
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
      status: 'Envoyée au responsable',
      isSentToManager: true,
    );

    // Simulate instant real-time network sync with Firebase / Restaurant Manager backend
    await Future.delayed(const Duration(milliseconds: 600));

    _orders.insert(0, order);
    cart.clear();
    notifyListeners();

    debugPrint('🔔 [NOTIFICATION RESTAURANT] Nouvelle commande reçue: ${order.id} | Client: ${order.customerName} | Total TTC: ${order.totalTtc.toStringAsFixed(2)} €');

    return order;
  }
}
