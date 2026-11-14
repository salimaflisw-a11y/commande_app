import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Listen to Firebase Auth state changes automatically
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  String? _lastAuthError;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  String? get lastAuthError => _lastAuthError;

  String get displayName {
    if (_currentUser == null) return 'Visiteur';
    if (isAdmin && _currentUser!.name.trim().isEmpty) {
      return 'Admin';
    }
    return _currentUser!.name.trim().isNotEmpty
        ? _currentUser!.name
        : 'Visiteur';
  }

  /// Called automatically whenever Firebase Auth state changes (login / logout)
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      _currentUser = await _fetchUserProfile(firebaseUser.uid, firebaseUser.email);
    }
    notifyListeners();
  }

  /// Fetch user profile document from Firestore
  Future<UserModel?> _fetchUserProfile(String uid, [String? email]) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson({...doc.data()!, 'id': uid});
      }

      // Fallback: If document was not found by Auth UID, search by email
      if (email != null && email.isNotEmpty) {
        final query = await _db
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final foundDoc = query.docs.first;
          final data = foundDoc.data();
          debugPrint(
              '⚠️ [AuthService] Document ID mismatch: Firestore has doc "${foundDoc.id}" for email "$email", but Firebase Auth UID is "$uid".');
          // Self-heal: ensure the user document exists at users/$uid too
          try {
            await _db.collection('users').doc(uid).set({...data, 'id': uid});
            debugPrint('✅ [AuthService] Automatically created users/$uid with matching role!');
          } catch (syncErr) {
            debugPrint('⚠️ [AuthService] Could not auto-sync doc to uid: $syncErr');
          }
          return UserModel.fromJson({...data, 'id': uid});
        }
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error fetching profile: $e');
      _lastAuthError = 'Erreur Firestore : $e';
      return null;
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _lastAuthError = null;
    try {
      String emailToUse = email.trim();
      // Convenience: if user just enters "admin", complete to "admin@gmail.com"
      if (emailToUse.toLowerCase() == 'admin') {
        emailToUse = 'admin@gmail.com';
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      if (cred.user == null) {
        _lastAuthError = 'Erreur lors de la connexion Firebase.';
        return false;
      }

      final profile = await _fetchUserProfile(cred.user!.uid, emailToUse);
      if (profile != null) {
        _currentUser = profile;
        notifyListeners();
        return true;
      }

      _lastAuthError ??=
          'Authentifié dans Firebase Auth (UID: ${cred.user!.uid}), mais aucun document trouvé dans Firestore sous users/${cred.user!.uid} ou avec email "$emailToUse".';
      debugPrint('⚠️ [AuthService] Profile missing for UID: ${cred.user!.uid}');
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('⚠️ [AuthService] Login failed: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'invalid-email':
          _lastAuthError =
              'Format d\'email non valide. Veuillez entrer une adresse complète (ex: admin@gmail.com).';
          break;
        case 'user-not-found':
          _lastAuthError =
              'Aucun compte trouvé avec cet e-mail dans Firebase Authentication.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          _lastAuthError =
              'Identifiants incorrects. Vérifiez l\'adresse e-mail et le mot de passe dans Firebase Authentication.';
          break;
        case 'user-disabled':
          _lastAuthError = 'Ce compte utilisateur a été désactivé.';
          break;
        case 'network-request-failed':
          _lastAuthError =
              'Erreur réseau. Vérifiez votre connexion Internet.';
          break;
        default:
          _lastAuthError = e.message ?? e.code;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ [AuthService] Login failed: $e');
      _lastAuthError = 'Erreur inattendue : $e';
      return false;
    }
  }

  /// Register a brand new client account
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final normalizedEmail = email.trim().toLowerCase();

    final newUser = UserModel(
      id: uid,
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      role: 'client',
      createdAt: DateTime.now(),
    );

    // Save profile to Firestore
    await _db.collection('users').doc(uid).set(newUser.toJson());

    _currentUser = newUser;
    notifyListeners();
    return newUser;
  }

  /// Disconnect and return to visitor mode
  Future<void> logout() async {
    await _auth.signOut();
    // _onAuthStateChanged will automatically set _currentUser = null
  }
}
