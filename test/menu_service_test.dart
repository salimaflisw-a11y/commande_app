import 'package:flutter_test/flutter_test.dart';
import 'package:commande_app/models/category_model.dart';
import 'package:commande_app/models/menu_item_model.dart';

void main() {
  group('CategoryModel and MenuItemModel tests', () {
    test('custom category creation and serialization', () {
      const cat = CategoryModel(
        id: 'cat_pizzas',
        label: 'Pizzas',
        emoji: '🍕',
        subtitle: 'Pizzas au feu de bois',
        bannerImageUrl: 'https://example.com/pizza.jpg',
      );

      final json = cat.toJson();
      expect(json['id'], 'cat_pizzas');
      expect(json['label'], 'Pizzas');
      expect(json['emoji'], '🍕');

      final fromJson = CategoryModel.fromJson(json);
      expect(fromJson.id, cat.id);
      expect(fromJson.label, cat.label);
      expect(fromJson.emoji, cat.emoji);
    });

    test('menu item category label and serialization', () {
      final item = MenuItemModel(
        id: 'item_1',
        name: 'Pizza Margherita',
        description: 'Tomate, mozzarella, basilic',
        price: 9.50,
        category: 'Pizzas',
        imageUrl: 'https://example.com/margherita.jpg',
      );

      expect(item.categoryLabel, 'Pizzas');
      final json = item.toJson();
      expect(json['category'], 'Pizzas');

      final deserialized = MenuItemModel.fromJson(json);
      expect(deserialized.categoryLabel, 'Pizzas');
      expect(deserialized.name, 'Pizza Margherita');
    });

    test('legacy Firestore item uses customCategory as its category', () {
      final item = MenuItemModel.fromJson({
        'id': 'item_2',
        'name': 'Tiramisu',
        'category': 'desserts',
        'customCategory': 'Desserts Maison',
        'price': 5.5,
      });

      expect(item.categoryLabel, 'Desserts Maison');
    });
  });
}
