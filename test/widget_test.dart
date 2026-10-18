import 'package:flutter_test/flutter_test.dart';
import 'package:commande_app/main.dart';

void main() {
  testWidgets('CatalogPage smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CommandeApp());
    await tester.pump();

    // Verify that CatalogPage elements are present.
    expect(find.text('Menu Numérique'), findsOneWidget);
    expect(find.text('Catégories du restaurant'), findsOneWidget);
    expect(find.text('✨ Tous'), findsOneWidget);
  });
}
