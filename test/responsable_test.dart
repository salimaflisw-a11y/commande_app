import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commande_app/services/auth_service.dart';
import 'package:commande_app/services/order_service.dart';
import 'package:commande_app/services/menu_service.dart';
import 'package:commande_app/screens/responsable_dashboard_page.dart';

void main() {
  group('Responsable & Auth Tests', () {
    test('AuthService distinguishes Client and Responsable roles', () async {
      final auth = AuthService();

      // Test Responsable login
      final respUser = await auth.login(
        email: 'responsable@restaurant.com',
        password: 'admin',
        preferredRole: 'responsable',
      );
      expect(respUser.role, equals('responsable'));
      expect(auth.isResponsable, isTrue);
      expect(auth.isClient, isFalse);

      // Test Client login
      final clientUser = await auth.login(
        email: 'client@example.com',
        password: '123',
        preferredRole: 'client',
      );
      expect(clientUser.role, equals('client'));
      expect(auth.isResponsable, isFalse);
      expect(auth.isClient, isTrue);
    });

    test('OrderService allows status updates and computes sales statistics', () {
      final orderService = OrderService();
      expect(orderService.orders.isNotEmpty, isTrue);

      final firstOrder = orderService.orders.first;
      final originalStatus = firstOrder.status;

      // Update status to "En préparation"
      orderService.updateOrderStatus(firstOrder.id, 'En préparation');
      final updatedOrder = orderService.orders.firstWhere((o) => o.id == firstOrder.id);
      expect(updatedOrder.status, equals('En préparation'));

      // Check statistics getters
      expect(orderService.totalRevenue, greaterThan(0));
      expect(orderService.totalOrdersCount, greaterThan(0));
      expect(orderService.averageOrderValue, greaterThan(0));

      // Restore status
      orderService.updateOrderStatus(firstOrder.id, originalStatus);
    });

    test('MenuService supports full CRUD for categories and food items', () {
      final menuService = MenuService();
      final initialCatCount = menuService.categories.length;
      final initialItemCount = menuService.items.length;

      // 1. Add Category
      menuService.addCategory(
        label: 'Pizzas Test',
        emoji: '🍕',
        subtitle: 'Pizzas artisanales',
        bannerImageUrl: '',
      );
      expect(menuService.categories.length, equals(initialCatCount + 1));
      final newCat = menuService.categories.last;
      expect(newCat.label, equals('Pizzas Test'));

      // 2. Update Category
      menuService.updateCategory(id: newCat.id, label: 'Pizzas Gourmet');
      expect(menuService.getCategoryById(newCat.id)?.label, equals('Pizzas Gourmet'));

      // 3. Add Item to Category
      menuService.addItem(
        name: 'Pizza Margherita Test',
        description: 'Sauce tomate et mozzarella',
        price: 10.50,
        category: newCat,
        imageUrl: '',
      );
      expect(menuService.items.length, equals(initialItemCount + 1));
      final newItem = menuService.items.last;
      expect(newItem.name, equals('Pizza Margherita Test'));
      expect(newItem.price, equals(10.50));

      // 4. Update Item
      final modifiedItem = newItem.copyWith(name: 'Pizza Margherita Extra', price: 12.00);
      menuService.updateItem(modifiedItem);
      expect(menuService.getItemById(newItem.id)?.name, equals('Pizza Margherita Extra'));
      expect(menuService.getItemById(newItem.id)?.price, equals(12.00));

      // 5. Delete Item
      menuService.deleteItem(newItem.id);
      expect(menuService.getItemById(newItem.id), isNull);

      // 6. Delete Category (and associated items)
      menuService.deleteCategory(newCat.id);
      expect(menuService.getCategoryById(newCat.id), isNull);
    });

    testWidgets('ResponsableDashboardPage displays orders, menu CRUD and statistics tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsableDashboardPage(),
        ),
      );

      // Verify Tab headers
      expect(find.text('Commandes'), findsOneWidget);
      expect(find.text('Gestion Menu'), findsOneWidget);
      expect(find.text('Statistiques'), findsOneWidget);
      expect(find.text('Espace Responsable'), findsOneWidget);

      // Switch to Gestion Menu tab
      await tester.tap(find.text('Gestion Menu'));
      await tester.pumpAndSettle();

      // Verify sub-tabs and action button
      expect(find.textContaining('Plats'), findsWidgets);
      expect(find.textContaining('Catégories'), findsWidgets);
      expect(find.text('Nouveau Plat'), findsOneWidget);

      // Switch to Statistiques tab
      await tester.tap(find.text('Statistiques'));
      await tester.pumpAndSettle();

      // Verify KPI titles
      expect(find.text('Indicateurs Clés de Vente'), findsOneWidget);
      expect(find.text('Chiffre d\'Affaires'), findsOneWidget);
      expect(find.text('Total Commandes'), findsOneWidget);
    });
  });
}
