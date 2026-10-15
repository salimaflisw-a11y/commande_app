import 'package:flutter/material.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';
import 'screens/catalog_page.dart';

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
      },
    );
  }
}
