import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Modal popup displayed to visitors when attempting to add products to cart
class AuthPopup extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback? onSuccess;
  final String? customMessage;

  const AuthPopup({
    super.key,
    this.primaryColor = const Color(0xFFE65100),
    this.onSuccess,
    this.customMessage,
  });

  /// Displays the AuthPopup dialog in front of the visitor
  static Future<bool> show(
    BuildContext context, {
    Color primaryColor = const Color(0xFFE65100),
    VoidCallback? onSuccess,
    String? customMessage,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AuthPopup(
            primaryColor: primaryColor,
            onSuccess: onSuccess,
            customMessage: customMessage,
          ),
        ),
      ),
    );

    return result ?? false;
  }

  @override
  State<AuthPopup> createState() => _AuthPopupState();
}

class _AuthPopupState extends State<AuthPopup> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController(text: 'salim@restaurant.fr');
  final _loginPasswordController = TextEditingController(text: '123456');
  bool _loginObscure = true;
  bool _loginLoading = false;

  // Register form controllers
  final _registerFormKey = GlobalKey<FormState>();
  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _regObscure = true;
  bool _regLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _loginLoading = true);
    await AuthService().login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _loginLoading = false);

    _completeSuccess('Bon retour parmi nous, ${AuthService().currentUser?.name} !');
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _regLoading = true);
    final user = await AuthService().register(
      name: _regNameController.text.trim(),
      email: _regEmailController.text.trim(),
      phone: _regPhoneController.text.trim(),
      password: _regPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _regLoading = false);

    _completeSuccess('Bienvenue ${user.name} ! Votre compte client est activé.');
  }

  void _completeSuccess(String message) {
    Navigator.of(context).pop(true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Banner ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Espace Client',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Devenez client pour commander',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.customMessage ??
                      'Vous pouvez consulter le menu librement. Pour ajouter des articles au panier, veuillez vous connecter ou créer un compte client.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // ── Tabs Header ────────────────────────────────────────────────────
          Container(
            color: Colors.grey.shade100,
            child: TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.login_rounded, size: 18),
                  text: 'Se connecter',
                ),
                Tab(
                  icon: Icon(Icons.person_add_alt_1_rounded, size: 18),
                  text: 'Créer un compte',
                ),
              ],
            ),
          ),

          // ── Tabs Content ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 290,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(primary),
                  _buildRegisterTab(primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab(Color primary) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'exemple@domaine.com',
              prefixIcon: Icon(Icons.email_outlined, color: primary, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9F9FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Veuillez saisir votre email';
              if (!val.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _loginObscure,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: primary, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(() => _loginObscure = !_loginObscure),
              ),
              filled: true,
              fillColor: const Color(0xFFF9F9FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Mot de passe obligatoire';
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loginLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _loginLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Connexion & Ajouter au panier',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(Color primary) {
    return Form(
      key: _registerFormKey,
      child: ListView(
        padding: const EdgeInsets.only(top: 4),
        children: [
          TextFormField(
            controller: _regNameController,
            decoration: InputDecoration(
              labelText: 'Nom & Prénom',
              prefixIcon: Icon(Icons.person_outline_rounded, color: primary, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9F9FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Indiquez votre nom complet' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_android_rounded, color: primary, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9F9FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Numéro de téléphone requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined, color: primary, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9F9FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email requis';
              if (!val.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _regPasswordController,
            obscureText: _regObscure,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: primary, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _regObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(() => _regObscure = !_regObscure),
              ),
              filled: true,
              fillColor: const Color(0xFFF9F9FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (val) =>
                val == null || val.length < 4 ? 'Au moins 4 caractères' : null,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _regLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _regLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Créer mon compte & Commander',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
