import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final String orderType; // 'Sur place', 'À emporter', 'Livraison'
  final String? tableNumber;
  final String? deliveryAddress;
  final String paymentMethod; // 'Paiement au comptoir'
  final String specialNotes;
  final List<CartItemModel> items;
  final double subtotalHt;
  final double vatRate;
  final double vatAmount;
  final double totalTtc;

  /// Status pour l'admin : 'En attente', 'Livrée', 'Rejetée'
  final String status;

  /// Statut du paiement pour la table livrée : 'unpaid' (Non payée) ou 'paid' (Payée)
  final String paymentStatus;

  /// Vrai si le client a quitté le restaurant sans régler la note
  final bool clientLeftWithoutPaying;

  final bool isSentToManager;

  const OrderModel({
    required this.id,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.orderType,
    this.tableNumber,
    this.deliveryAddress,
    required this.paymentMethod,
    this.specialNotes = '',
    required this.items,
    required this.subtotalHt,
    this.vatRate = 0.10,
    required this.vatAmount,
    required this.totalTtc,
    this.status = 'En attente',
    this.paymentStatus = 'unpaid',
    this.clientLeftWithoutPaying = false,
    this.isSentToManager = true,
  });

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isPending => status == 'En attente';
  bool get isDelivered => status == 'Livrée';
  bool get isRejected => status == 'Rejetée';
  bool get isPaid => paymentStatus == 'paid';
  bool get isUnpaid => paymentStatus == 'unpaid';
  bool get isBlockedDueToUnpaid => clientLeftWithoutPaying;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'orderType': orderType,
      'tableNumber': tableNumber,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'specialNotes': specialNotes,
      'subtotalHt': subtotalHt,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalTtc': totalTtc,
      'status': status,
      'paymentStatus': paymentStatus,
      'clientLeftWithoutPaying': clientLeftWithoutPaying,
      'isSentToManager': isSentToManager,
    };
  }

  OrderModel copyWith({
    String? id,
    DateTime? createdAt,
    String? customerName,
    String? customerPhone,
    String? orderType,
    String? tableNumber,
    String? deliveryAddress,
    String? paymentMethod,
    String? specialNotes,
    List<CartItemModel>? items,
    double? subtotalHt,
    double? vatRate,
    double? vatAmount,
    double? totalTtc,
    String? status,
    String? paymentStatus,
    bool? clientLeftWithoutPaying,
    bool? isSentToManager,
  }) {
    return OrderModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      specialNotes: specialNotes ?? this.specialNotes,
      items: items ?? this.items,
      subtotalHt: subtotalHt ?? this.subtotalHt,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      totalTtc: totalTtc ?? this.totalTtc,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      clientLeftWithoutPaying:
          clientLeftWithoutPaying ?? this.clientLeftWithoutPaying,
      isSentToManager: isSentToManager ?? this.isSentToManager,
    );
  }
}
