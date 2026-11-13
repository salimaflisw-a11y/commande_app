import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/supplement_model.dart';

class MenuService extends ChangeNotifier {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;

  MenuService._internal() {
    _initMenu();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription? _categoriesSub;
  StreamSubscription? _itemsSub;
  StreamSubscription? _supplementsSub;

  List<CategoryModel> _categories = [];
  List<MenuItemModel> _items = [];
  List<SupplementModel> _supplements = [];

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<MenuItemModel> get items => List.unmodifiable(_items);
  List<SupplementModel> get supplements => List.unmodifiable(_supplements);
  List<SupplementModel> get availableSupplements =>
      _supplements.where((s) => s.isAvailable).toList();

  /// Distinct supplement groups (e.g. Sauces, Boissons) in first-seen order.
  List<String> supplementGroups([List<SupplementModel>? source]) {
    final groups = <String>[];
    for (final s in source ?? _supplements) {
      final g = s.category.trim();
      if (g.isNotEmpty && !groups.contains(g)) groups.add(g);
    }
    return groups;
  }

  void _initMenu() {
    // Listen to real-time categories from Firestore
    _categoriesSub = _db.collection('categories').snapshots().listen((snapshot) {
      _categories = snapshot.docs
          .where((doc) => doc.data()['isDeleted'] != true)
          .map((doc) => CategoryModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('⚠️ [MenuService] Categories listener error: $e');
    });

    // Listen to real-time menu items from Firestore
    _itemsSub = _db.collection('menu_items').snapshots().listen((snapshot) {
      _items = snapshot.docs
          .where((doc) => doc.data()['isDeleted'] != true)
          .map((doc) => MenuItemModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('⚠️ [MenuService] Menu items listener error: $e');
    });

    // Listen to real-time supplements from Firestore
    _supplementsSub = _db.collection('supplements').snapshots().listen((snapshot) {
      _supplements = snapshot.docs
          .map((doc) => SupplementModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList()
        ..sort((a, b) {
          final byGroup = a.category.toLowerCase().compareTo(b.category.toLowerCase());
          return byGroup != 0 ? byGroup : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      notifyListeners();
    }, onError: (e) {
      debugPrint('⚠️ [MenuService] Supplements listener error: $e');
    });
  }

  List<MenuItemModel> getItemsForCategory(String categoryLabel) {
    final search = categoryLabel.trim().toLowerCase();
    return _items.where((it) => it.categoryLabel.toLowerCase() == search).toList();
  }

  String emojiForCategory(String categoryLabel) {
    final search = categoryLabel.trim().toLowerCase();
    for (final c in _categories) {
      if (c.label.trim().toLowerCase() == search) return c.emoji;
    }
    return '';
  }

  /// Add a brand new category created by the Admin
  Future<CategoryModel> addCategory({
    required String label,
    required String emoji,
    String subtitle = '',
    String bannerImageUrl = '',
  }) async {
    final cleanLabel = label.trim();
    final id = 'cat_${cleanLabel.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final newCat = CategoryModel(
      id: id,
      label: cleanLabel,
      emoji: emoji.trim().isEmpty ? '🍽️' : emoji.trim(),
      subtitle: subtitle.trim(),
      bannerImageUrl: bannerImageUrl.trim().isNotEmpty
          ? bannerImageUrl.trim()
          : 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
    );

    // Save to Firestore
    await _db.collection('categories').doc(id).set(newCat.toJson());

    // Update local state immediately
    _categories.removeWhere((c) => c.id.toLowerCase() == id.toLowerCase());
    _categories.add(newCat);
    notifyListeners();
    return newCat;
  }

  /// Update an existing category in Firestore and local state.
  /// When the label changes, items linked to the old label are moved to the new one.
  Future<void> updateCategory(CategoryModel updatedCat, {String? previousLabel}) async {
    await _db.collection('categories').doc(updatedCat.id).set(updatedCat.toJson(), SetOptions(merge: true));
    final idx = _categories.indexWhere((c) => c.id.toLowerCase() == updatedCat.id.toLowerCase());
    if (idx >= 0) {
      _categories[idx] = updatedCat;
    } else {
      _categories.add(updatedCat);
    }

    if (previousLabel != null &&
        previousLabel.trim().toLowerCase() != updatedCat.label.trim().toLowerCase()) {
      final linkedItems = getItemsForCategory(previousLabel);
      for (final item in linkedItems) {
        await saveMenuItem(item.copyWith(category: updatedCat.label));
      }
    }
    notifyListeners();
  }

  /// Delete a category and all the menu items it contains.
  Future<void> deleteCategory(CategoryModel category) async {
    final linkedItems = getItemsForCategory(category.label);
    for (final item in linkedItems) {
      await deleteMenuItem(item.id);
    }

    await _db.collection('categories').doc(category.id).delete();
    _categories.removeWhere((c) => c.id.toLowerCase() == category.id.toLowerCase());
    notifyListeners();
  }

  /// Create or update a menu item
  Future<MenuItemModel> saveMenuItem(MenuItemModel item) async {
    final id = item.id.trim().isEmpty
        ? _db.collection('menu_items').doc().id
        : item.id.trim();

    final itemWithId = item.copyWith(id: id);
    await _db.collection('menu_items').doc(id).set(itemWithId.toJson());

    final idx = _items.indexWhere((it) => it.id == id);
    if (idx >= 0) {
      _items[idx] = itemWithId;
    } else {
      _items.add(itemWithId);
    }
    notifyListeners();
    return itemWithId;
  }

  /// Delete a menu item
  Future<void> deleteMenuItem(String itemId) async {
    await _db.collection('menu_items').doc(itemId).delete();
    _items.removeWhere((it) => it.id == itemId);
    notifyListeners();
  }

  /// Create or update a supplement
  Future<SupplementModel> saveSupplement(SupplementModel supplement) async {
    final id = supplement.id.trim().isEmpty
        ? _db.collection('supplements').doc().id
        : supplement.id.trim();

    final withId = supplement.copyWith(id: id);
    await _db.collection('supplements').doc(id).set(withId.toJson());

    final idx = _supplements.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _supplements[idx] = withId;
    } else {
      _supplements.add(withId);
    }
    notifyListeners();
    return withId;
  }

  /// Delete a supplement
  Future<void> deleteSupplement(String supplementId) async {
    await _db.collection('supplements').doc(supplementId).delete();
    _supplements.removeWhere((s) => s.id == supplementId);
    notifyListeners();
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _itemsSub?.cancel();
    _supplementsSub?.cancel();
    super.dispose();
  }
}
