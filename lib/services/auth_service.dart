import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Seed some registered clients for quick testing
    _registeredUsers.addAll([
      UserModel(
        id: 'usr_001',
        name: 'Salim Client',
        email: 'salim@restaurant.fr',
        phone: '06 12 34 56 78',
        address: '15 Avenue des Champs, Paris',
        role: 'client',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserModel(
        id: 'usr_002',
        name: 'Sophie Martin',
        email: 'sophie@client.fr',
        phone: '07 88 99 00 11',
        address: '8 Rue Gourmande, Lyon',
        role: 'client',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);
  }

  // Current logged in user (null = Visitor)
  UserModel? _currentUser;

  // In-memory list of registered clients
  final List<UserModel> _registeredUsers = [];

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get displayName => _currentUser?.name ?? 'Visiteur';

  List<UserModel> get registeredUsers => List.unmodifiable(_registeredUsers);

  /// Authenticate with email & password
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final trimmedEmail = email.trim().toLowerCase();
    
    // Look for matching user in registered list
    final existingUser = _registeredUsers.firstWhere(
      (u) => u.email.toLowerCase() == trimmedEmail,
      orElse: () {
        // If not found in seed list, create a client account automatically on the fly
        final nameFromEmail = trimmedEmail.split('@').first;
        final capitalized = nameFromEmail.isNotEmpty
            ? '${nameFromEmail[0].toUpperCase()}${nameFromEmail.substring(1)}'
            : 'Client';
        final newUser = UserModel(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: capitalized,
          email: trimmedEmail,
          phone: '06 00 00 00 00',
          address: 'Adresse non renseignée',
          role: 'client',
          createdAt: DateTime.now(),
        );
        _registeredUsers.add(newUser);
        return newUser;
      },
    );

    _currentUser = existingUser;
    notifyListeners();
    return true;
  }

  /// Register a brand new client account
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    String address = '',
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      address: address.trim().isEmpty ? 'Sur place / Comptoir' : address.trim(),
      role: 'client',
      createdAt: DateTime.now(),
    );

    _registeredUsers.removeWhere((u) => u.email.toLowerCase() == newUser.email);
    _registeredUsers.add(newUser);
    _currentUser = newUser;
    notifyListeners();

    return newUser;
  }

  /// One-tap demo client login for instant testing
  void loginAsDemo() {
    _currentUser = _registeredUsers.first;
    notifyListeners();
  }

  /// Disconnect client and return to visitor mode
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
