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

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  String get displayName => _currentUser?.name ?? 'Visiteur';

  /// Called automatically whenever Firebase Auth state changes (login / logout)
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      _currentUser = await _fetchUserProfile(firebaseUser.uid);
    }
    notifyListeners();
  }

  /// Fetch user profile document from Firestore
  Future<UserModel?> _fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson({...doc.data()!, 'id': uid});
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error fetching profile: $e');
      return null;
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('⚠️ [AuthService] Login failed: ${e.code}');
      return false;
    }
  }

  /// Register a brand new client account
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    String address = '',
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
      address: address.trim().isEmpty ? 'Sur place / Comptoir' : address.trim(),
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
