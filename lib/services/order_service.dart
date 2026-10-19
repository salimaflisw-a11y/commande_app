import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';
import 'cart_service.dart';

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;

  OrderService._internal() {
    _initDemoOrders();
  }

  final List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders);

  OrderModel? get latestOrder => _orders.isNotEmpty ? _orders.first : null;

  // --- Statistiques de ventes & Suivi des commandes ---
  double get totalRevenue => _orders.fold(0.0, (sum, item) => sum + item.totalTtc);
  int get totalOrdersCount => _orders.length;
  int get pendingOrdersCount =>
      _orders.where((o) => o.status == 'Envoyée au responsable').length;
  int get preparingOrdersCount =>
      _orders.where((o) => o.status == 'En préparation').length;
  int get readyOrdersCount =>
      _orders.where((o) => o.status == 'Prête').length;
  int get completedOrdersCount =>
      _orders.where((o) => o.status == 'Livrée / Servie').length;
  double get averageOrderValue =>
      _orders.isEmpty ? 0.0 : totalRevenue / _orders.length;

  /// Met à jour le statut d'une commande (ex: "En préparation", "Prête", "Livrée / Servie")
  void updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      notifyListeners();
      debugPrint('🔄 Statut commande $orderId mis à jour: $newStatus');
    }
  }

  /// Supprime une commande
  void deleteOrder(String orderId) {
    _orders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

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

  /// Initialise quelques commandes de test réalistes pour la démonstration
  void _initDemoOrders() {
    if (_orders.isNotEmpty) return;

    final now = DateTime.now();

    // 1. Commande récente en attente
    _orders.add(
      OrderModel(
        id: 'CMD-202610-8841',
        createdAt: now.subtract(const Duration(minutes: 8)),
        customerName: 'Karim Benali',
        customerPhone: '06 14 25 36 47',
        orderType: 'Sur place',
        tableNumber: 'Table 7',
        paymentMethod: 'Carte Bancaire',
        specialNotes: 'Bien cuit s\'il vous plaît, sans oignons.',
        items: [
          CartItemModel(
            id: 'item_demo_1',
            item: sampleMenuItems[0], // Burger Smash
            selectedIngredients: sampleMenuItems[0].ingredients,
            supplements: const [
              SupplementItem(
                id: 'sup_cheese',
                name: 'Double Cheddar Fondu',
                category: 'Fromages',
                unitPrice: 1.50,
                quantity: 1,
              ),
              SupplementItem(
                id: 'sup_frites',
                name: 'Grande portion Frites Maison',
                category: 'Accompagnements',
                unitPrice: 2.80,
                quantity: 1,
              ),
            ],
            quantity: 2,
          ),
          CartItemModel(
            id: 'item_demo_2',
            item: sampleMenuItems[12], // Boisson / Soda
            selectedIngredients: const [],
            quantity: 2,
          ),
        ],
        subtotalHt: 31.82,
        vatRate: 0.10,
        vatAmount: 3.18,
        totalTtc: 35.00,
        status: 'Envoyée au responsable',
        isSentToManager: true,
      ),
    );

    // 2. Commande en préparation
    _orders.add(
      OrderModel(
        id: 'CMD-202610-7219',
        createdAt: now.subtract(const Duration(minutes: 25)),
        customerName: 'Sophie Martin',
        customerPhone: '07 88 99 00 11',
        orderType: 'Livraison',
        deliveryAddress: '14 Rue de la Paix, 75002 Paris (Bâtiment B, Apt 14)',
        paymentMethod: 'En ligne',
        specialNotes: 'Sonner à l\'interphone Martin',
        items: [
          CartItemModel(
            id: 'item_demo_3',
            item: sampleMenuItems[4], // Saumon rôti
            selectedIngredients: sampleMenuItems[4].ingredients,
            quantity: 1,
          ),
          CartItemModel(
            id: 'item_demo_4',
            item: sampleMenuItems[18], // Dessert Tiramisu
            selectedIngredients: const [],
            quantity: 1,
          ),
        ],
        subtotalHt: 20.64,
        vatRate: 0.10,
        vatAmount: 2.06,
        totalTtc: 22.70,
        status: 'En préparation',
        isSentToManager: true,
      ),
    );

    // 3. Commande terminée
    _orders.add(
      OrderModel(
        id: 'CMD-202610-5104',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        customerName: 'Yassine Touati',
        customerPhone: '06 55 44 33 22',
        orderType: 'À emporter',
        paymentMethod: 'Espèces',
        items: [
          CartItemModel(
            id: 'item_demo_5',
            item: sampleMenuItems[2], // Tacos
            selectedIngredients: sampleMenuItems[2].ingredients,
            quantity: 1,
          ),
        ],
        subtotalHt: 8.64,
        vatRate: 0.10,
        vatAmount: 0.86,
        totalTtc: 9.50,
        status: 'Livrée / Servie',
        isSentToManager: true,
      ),
    );
  }
}
