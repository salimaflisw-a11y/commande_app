import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Service de gestion de l'authentification et des rôles utilisateurs (Client / Responsable).
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isResponsable => _currentUser?.role == 'responsable';
  bool get isClient => _currentUser?.role == 'client';

  /// Comptes de démonstration préconfigurés
  static final UserModel defaultResponsable = UserModel(
    id: 'RESP-001',
    name: 'Chef & Gérant Restaurant',
    email: 'responsable@restaurant.com',
    phone: '06 99 88 77 66',
    address: 'Bureau Restaurant - Paris',
    role: 'responsable',
    createdAt: DateTime(2026, 1, 1),
  );

  static final UserModel defaultClient = UserModel(
    id: 'CLI-001',
    name: 'Salim Amrani',
    email: 'client@example.com',
    phone: '06 12 34 56 78',
    address: '15 Rue de Rivoli, 75001 Paris',
    role: 'client',
    createdAt: DateTime(2026, 2, 10),
  );

  /// Connexion utilisateur avec détection automatique du rôle
  Future<UserModel> login({
    required String email,
    required String password,
    String? preferredRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final cleanEmail = email.trim().toLowerCase();

    // Détection du rôle selon l'e-mail ou le rôle spécifié
    if (preferredRole == 'responsable' ||
        cleanEmail.contains('responsable') ||
        cleanEmail.contains('admin') ||
        cleanEmail.contains('gerant')) {
      _currentUser = UserModel(
        id: 'RESP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        name: cleanEmail.contains('admin') ? 'Administrateur' : 'Responsable Restaurant',
        email: cleanEmail,
        phone: '06 99 88 77 66',
        address: 'Bureau de direction',
        role: 'responsable',
        createdAt: DateTime.now(),
      );
    } else {
      _currentUser = UserModel(
        id: 'CLI-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        name: cleanEmail.split('@').first.toUpperCase(),
        email: cleanEmail,
        phone: '06 12 34 56 78',
        address: 'Paris, France',
        role: 'client',
        createdAt: DateTime.now(),
      );
    }

    notifyListeners();
    return _currentUser!;
  }

  /// Connexion directe en tant que responsable (pratique pour les démos & tests de l'enseignante)
  Future<UserModel> loginAsResponsable() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = defaultResponsable;
    notifyListeners();
    return _currentUser!;
  }

  /// Connexion directe en tant que client
  Future<UserModel> loginAsClient() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = defaultClient;
    notifyListeners();
    return _currentUser!;
  }

  /// Déconnexion
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
