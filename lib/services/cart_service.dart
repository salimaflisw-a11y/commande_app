import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Taux de TVA restaurant (10%)
  double get vatRate => 0.10;

  /// Total TTC
  double get totalTtc => totalAmount;

  /// Total Hors Taxes (HT)
  double get subtotalHt => totalTtc / (1.0 + vatRate);

  /// Montant de la TVA (10%)
  double get vatAmount => totalTtc - subtotalHt;

  void addItem(CartItemModel newItem) {
    _items.add(newItem);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
