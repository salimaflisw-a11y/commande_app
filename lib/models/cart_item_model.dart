import 'menu_item_model.dart';

class SupplementItem {
  final String id;
  final String name;
  final String category;
  final double unitPrice;
  final int quantity;

  const SupplementItem({
    required this.id,
    required this.name,
    this.category = 'Extras',
    required this.unitPrice,
    this.quantity = 1,
  });

  double get totalPrice => unitPrice * quantity;

  SupplementItem copyWith({
    String? id,
    String? name,
    String? category,
    double? unitPrice,
    int? quantity,
  }) {
    return SupplementItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  factory SupplementItem.fromJson(Map<String, dynamic> json) {
    return SupplementItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Extras',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class CartItemModel {
  final String id;
  final MenuItemModel item;
  final List<String> selectedIngredients;
  final List<String> removedIngredients;
  final List<SupplementItem> supplements;
  final int quantity;
  final String specialInstructions;
  final double? _customExtraPrice;

  const CartItemModel({
    required this.id,
    required this.item,
    required this.selectedIngredients,
    this.removedIngredients = const [],
    this.supplements = const [],
    this.quantity = 1,
    this.specialInstructions = '',
    double? extraPricePerUnit,
    List<String>? extraIngredients,
  }) : _customExtraPrice = extraPricePerUnit;

  // Backwards compatibility for String-based extraIngredients
  List<String> get extraIngredients => supplements.isNotEmpty
      ? supplements
          .map((s) => s.quantity > 1
              ? '${s.name} x${s.quantity} (+${s.totalPrice.toStringAsFixed(2)} €)'
              : '${s.name} (+${s.totalPrice.toStringAsFixed(2)} €)')
          .toList()
      : const [];

  double get extraPricePerUnit {
    if (supplements.isNotEmpty) {
      return supplements.fold(0.0, (sum, s) => sum + s.totalPrice);
    }
    return _customExtraPrice ?? 0.0;
  }

  double get unitPrice => item.price + extraPricePerUnit;
  double get totalPrice => unitPrice * quantity;

  CartItemModel copyWith({
    String? id,
    MenuItemModel? item,
    List<String>? selectedIngredients,
    List<String>? removedIngredients,
    List<SupplementItem>? supplements,
    int? quantity,
    String? specialInstructions,
    double? extraPricePerUnit,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      item: item ?? this.item,
      selectedIngredients: selectedIngredients ?? this.selectedIngredients,
      removedIngredients: removedIngredients ?? this.removedIngredients,
      supplements: supplements ?? this.supplements,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      extraPricePerUnit: extraPricePerUnit ?? this.extraPricePerUnit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': item.id,
      'itemName': item.name,
      'itemPrice': item.price,
      'itemCategory': item.category,
      'itemImageUrl': item.imageUrl,
      'selectedIngredients': selectedIngredients,
      'removedIngredients': removedIngredients,
      'supplements': supplements.map((s) => s.toJson()).toList(),
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Rebuild a minimal MenuItemModel from the snapshot stored in Firestore
    final menuItem = MenuItemModel(
      id: json['itemId'] as String? ?? '',
      name: json['itemName'] as String? ?? '',
      price: (json['itemPrice'] as num?)?.toDouble() ?? 0.0,
      category: json['itemCategory'] as String? ?? '',
      imageUrl: json['itemImageUrl'] as String? ?? '',
      description: '',
      ingredients: const [],
    );

    final rawSupplements = json['supplements'] as List<dynamic>? ?? [];

    return CartItemModel(
      id: json['id'] as String? ?? '',
      item: menuItem,
      selectedIngredients:
          (json['selectedIngredients'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList(),
      removedIngredients:
          (json['removedIngredients'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList(),
      supplements: rawSupplements
          .map((e) => SupplementItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      specialInstructions: json['specialInstructions'] as String? ?? '',
    );
  }
}
