import 'package:flutter_test/flutter_test.dart';
import 'package:commande_app/main.dart';

void main() {
  testWidgets('RegisterPage smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CommandeApp());

    // Verify that register page elements are present.
    expect(find.text('Inscription Client'), findsOneWidget);
    expect(find.text('Créer un Compte'), findsOneWidget);
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.text('S\'inscrire'), findsOneWidget);
  });
}
