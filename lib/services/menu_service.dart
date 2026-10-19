import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';

/// Service centralisant la gestion du menu (Plats et Catégories) en temps réel.
/// Permet au responsable d'effectuer le CRUD complet sur le menu.
class MenuService extends ChangeNotifier {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;

  MenuService._internal() {
    _initDefaultData();
  }

  final List<CategoryModel> _categories = [];
  final List<MenuItemModel> _items = [];

  // ── GETTERS ───────────────────────────────────────────────────────────────
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<MenuItemModel> get items => List.unmodifiable(_items);

  /// Récupère tous les plats appartenant à une catégorie donnée
  List<MenuItemModel> getItemsByCategory(CategoryInfo category) {
    return _items.where((item) => item.category.id == category.id).toList();
  }

  /// Récupère une catégorie par son identifiant
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Récupère un plat par son identifiant
  MenuItemModel? getItemById(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── CATEGORY CRUD ─────────────────────────────────────────────────────────

  /// Ajouter une nouvelle catégorie
  void addCategory({
    required String label,
    required String emoji,
    required String subtitle,
    required String bannerImageUrl,
  }) {
    final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final category = CategoryModel(
      id: newId,
      label: label.trim(),
      emoji: emoji.trim().isEmpty ? '🍽️' : emoji.trim(),
      subtitle: subtitle.trim(),
      bannerImageUrl: bannerImageUrl.trim().isNotEmpty
          ? bannerImageUrl.trim()
          : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
      isDefault: false,
    );

    _categories.add(category);
    notifyListeners();
    debugPrint('✅ [MenuService] Catégorie ajoutée: ${category.label} (${category.id})');
  }

  /// Modifier une catégorie existante
  void updateCategory({
    required String id,
    String? label,
    String? emoji,
    String? subtitle,
    String? bannerImageUrl,
  }) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = _categories[index];
      final updated = old.copyWith(
        label: label?.trim().isNotEmpty == true ? label!.trim() : old.label,
        emoji: emoji?.trim().isNotEmpty == true ? emoji!.trim() : old.emoji,
        subtitle: subtitle?.trim().isNotEmpty == true ? subtitle!.trim() : old.subtitle,
        bannerImageUrl: bannerImageUrl?.trim().isNotEmpty == true
            ? bannerImageUrl!.trim()
            : old.bannerImageUrl,
      );
      _categories[index] = updated;

      // Met à jour la catégorie dans les plats associés
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].category.id == id) {
          _items[i] = _items[i].copyWith(category: updated);
        }
      }

      notifyListeners();
      debugPrint('🔄 [MenuService] Catégorie mise à jour: ${updated.label}');
    }
  }

  /// Supprimer une catégorie et ses plats associés
  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    // Supprime également les plats associés à cette catégorie
    _items.removeWhere((item) => item.category.id == id);
    notifyListeners();
    debugPrint('🗑️ [MenuService] Catégorie $id et ses plats supprimés');
  }

  // ── FOOD ITEM (PRODUCT) CRUD ──────────────────────────────────────────────

  /// Ajouter un nouveau plat
  void addItem({
    required String name,
    required String description,
    required double price,
    required CategoryInfo category,
    required String imageUrl,
    String prepTime = '15 min',
    int calories = 400,
    bool isPopular = false,
    bool isVegetarian = false,
    List<String> ingredients = const [],
  }) {
    final newId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = MenuItemModel(
      id: newId,
      name: name.trim(),
      description: description.trim(),
      price: price,
      category: category,
      imageUrl: imageUrl.trim().isNotEmpty
          ? imageUrl.trim()
          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      rating: 4.8,
      reviewsCount: 1,
      isPopular: isPopular,
      isVegetarian: isVegetarian,
      prepTime: prepTime.trim().isNotEmpty ? prepTime.trim() : '15 min',
      calories: calories > 0 ? calories : 350,
      ingredients: ingredients,
    );

    _items.add(newItem);
    notifyListeners();
    debugPrint('✅ [MenuService] Plat ajouté: ${newItem.name} | Prix: ${newItem.price} €');
  }

  /// Modifier un plat existant
  void updateItem(MenuItemModel updatedItem) {
    final index = _items.indexWhere((i) => i.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
      debugPrint('🔄 [MenuService] Plat mis à jour: ${updatedItem.name} | Prix: ${updatedItem.price} €');
    }
  }

  /// Supprimer un plat
  void deleteItem(String itemId) {
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();
    debugPrint('🗑️ [MenuService] Plat supprimé: $itemId');
  }

  // ── INITIAL DATA SEED ─────────────────────────────────────────────────────

  void _initDefaultData() {
    // 1. Initialise les catégories par défaut depuis MenuCategory
    for (final cat in MenuCategory.values) {
      _categories.add(CategoryModel.fromCategoryInfo(cat));
    }

    // 2. Initialise les plats par défaut depuis sampleMenuItems
    _items.addAll(sampleMenuItems);
  }

  /// Réinitialiser les données aux valeurs par défaut
  void resetToDefaults() {
    _categories.clear();
    _items.clear();
    _initDefaultData();
    notifyListeners();
  }
}
