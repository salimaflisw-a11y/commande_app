import 'package:flutter/material.dart';
import 'services/order_service.dart';
import 'widgets/unpaid_blocked_overlay.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';
import 'screens/catalog_page.dart';
import 'screens/order_checkout_page.dart';
import 'screens/client_orders_page.dart';

void main() {
  runApp(const CommandeApp());
}

class CommandeApp extends StatelessWidget {
  const CommandeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Commande Restaurant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100),
          primary: const Color(0xFFE65100),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF263238),
        ),
      ),
      initialRoute: '/catalog',
      routes: {
        '/': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/catalog': (context) => const CatalogPage(),
        '/checkout': (context) => const OrderCheckoutPage(),
        '/orders': (context) => const ClientOrdersPage(),
      },
      // ── Global anti-theft freeze: freezes the app over whatever page the client is viewing ──
      builder: (context, child) {
        return ListenableBuilder(
          listenable: OrderService(),
          builder: (context, _) {
            final orderService = OrderService();
            final isBlocked = orderService.isCurrentClientBlocked;
            final unpaidOrder = orderService.blockingUnpaidOrder;

            return Stack(
              children: [
                // Active screen underneath (all taps disabled when unpaid)
                if (child != null)
                  IgnorePointer(
                    ignoring: isBlocked,
                    child: child,
                  ),

                // Freezing security modal directly over the last viewed page
                if (isBlocked && unpaidOrder != null)
                  UnpaidBlockedOverlay(order: unpaidOrder),
              ],
            );
          },
        );
      },
    );
  }
}
