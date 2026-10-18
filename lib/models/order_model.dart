import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final String orderType; // 'Sur place', 'À emporter', 'Livraison'
  final String? tableNumber;
  final String? deliveryAddress;
  final String paymentMethod; // 'Espèces', 'Carte Bancaire', 'En ligne'
  final String specialNotes;
  final List<CartItemModel> items;
  final double subtotalHt;
  final double vatRate;
  final double vatAmount;
  final double totalTtc;
  final String status;
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
    this.status = 'Envoyée au responsable',
    this.isSentToManager = true,
  });

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

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
      isSentToManager: isSentToManager ?? this.isSentToManager,
    );
  }
}
