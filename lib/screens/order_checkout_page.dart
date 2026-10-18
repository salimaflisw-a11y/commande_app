import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import 'order_success_page.dart';

class OrderCheckoutPage extends StatefulWidget {
  const OrderCheckoutPage({super.key});

  @override
  State<OrderCheckoutPage> createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _tableController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  String _selectedOrderType = 'Sur place'; // 'Sur place', 'À emporter', 'Livraison'
  final String _selectedPayment = 'Paiement au comptoir'; // Only payment method allowed
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _tableController = TextEditingController(text: 'Table 1');
    _addressController = TextEditingController(text: user?.address ?? '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _tableController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cart = CartService();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide !'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = await OrderService().submitOrder(
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        orderType: _selectedOrderType,
        tableNumber: _selectedOrderType == 'Sur place' ? _tableController.text.trim() : null,
        deliveryAddress: _selectedOrderType == 'Livraison' ? _addressController.text.trim() : null,
        paymentMethod: _selectedPayment,
        specialNotes: _notesController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la validation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);
    final cart = CartService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'Validation & Addition',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF263238),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: const Color(0xFF263238),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
          children: [
            // ── 1. ADDITION & BILLET RÉCAPITULATIF ─────────────────────────
            _buildAdditionReceiptCard(cart, primaryColor),

            const SizedBox(height: 20),

            // ── 2. MODE DE CONSOMMATION ────────────────────────────────────
            _buildSectionHeader('Mode de commande', Icons.restaurant_outlined, primaryColor),
            const SizedBox(height: 10),
            _buildOrderTypeSelector(primaryColor),

            if (_selectedOrderType == 'Sur place') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _tableController,
                decoration: _buildInputDecoration(
                  label: 'Numéro de Table',
                  hint: 'Ex: Table 4, Terrasse 2...',
                  icon: Icons.table_restaurant_outlined,
                  primaryColor: primaryColor,
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Veuillez préciser la table' : null,
              ),
            ] else if (_selectedOrderType == 'Livraison') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: _buildInputDecoration(
                  label: 'Adresse de livraison',
                  hint: 'Rue, N°, Bâtiment, Code postal...',
                  icon: Icons.location_on_outlined,
                  primaryColor: primaryColor,
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Précisez votre adresse' : null,
              ),
            ],

            const SizedBox(height: 22),

            // ── 3. COORDONNÉES DU CLIENT ──────────────────────────────────
            _buildSectionHeader('Vos coordonnées', Icons.person_outline_rounded, primaryColor),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration(
                label: 'Nom & Prénom',
                hint: 'Ex: Jean Dupont',
                icon: Icons.person_rounded,
                primaryColor: primaryColor,
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Indiquez votre nom' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _buildInputDecoration(
                label: 'Téléphone',
                hint: 'Ex: 06 12 34 56 78',
                icon: Icons.phone_android_rounded,
                primaryColor: primaryColor,
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Indiquez un téléphone valide' : null,
            ),

            const SizedBox(height: 22),

            // ── 4. MOYEN DE RÈGLEMENT ──────────────────────────────────────
            _buildSectionHeader('Mode de paiement', Icons.payment_outlined, primaryColor),
            const SizedBox(height: 10),
            _buildPaymentMethodSelector(primaryColor),

            const SizedBox(height: 22),

            // ── 5. INSTRUCTIONS SPÉCIALES ─────────────────────────────────
            _buildSectionHeader('Instructions cuisine (optionnel)', Icons.note_alt_outlined, primaryColor),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: _buildInputDecoration(
                label: 'Remarques cuisine',
                hint: 'Ex: sonnette en panne, servi bien chaud...',
                icon: Icons.chat_bubble_outline_rounded,
                primaryColor: primaryColor,
              ),
            ),
          ],
        ),
      ),

      // ── BOTTOM FLOATING CONFIRMATION BUTTON ──────────────────────────────
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleConfirmOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
            child: _isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Envoi au restaurant en cours...',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Valider & Envoyer',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cart.totalAmount.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionReceiptCard(CartService cart, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header of addition
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Addition & Détail TVA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const Spacer(),
                Text(
                  '${cart.itemCount} article(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Items summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              children: cart.items.map((cartItem) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cartItem.quantity}x',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cartItem.item.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF263238),
                              ),
                            ),
                            if (cartItem.supplements.isNotEmpty)
                              Text(
                                '+ ${cartItem.supplements.map((s) => '${s.name} x${s.quantity}').join(', ')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${cartItem.totalPrice.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Dashed receipt separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                32,
                (index) => Expanded(
                  child: Container(
                    color: index.isEven ? Colors.grey.shade300 : Colors.transparent,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Tax breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildReceiptLine(
                  'Sous-total Hors Taxes (HT)',
                  '${cart.subtotalHt.toStringAsFixed(2)} €',
                ),
                const SizedBox(height: 6),
                _buildReceiptLine(
                  'T.V.A. (10.00%)',
                  '${cart.vatAmount.toStringAsFixed(2)} €',
                  color: const Color(0xFF546E7A),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total TTC à payer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    Text(
                      '${cart.totalTtc.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptLine(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color ?? const Color(0xFF78909C),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? const Color(0xFF263238),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTypeSelector(Color primaryColor) {
    final types = [
      {'label': 'Sur place', 'icon': Icons.table_restaurant_rounded},
      {'label': 'À emporter', 'icon': Icons.shopping_bag_outlined},
      {'label': 'Livraison', 'icon': Icons.delivery_dining_rounded},
    ];

    return Row(
      children: types.map((type) {
        final label = type['label'] as String;
        final icon = type['icon'] as IconData;
        final isSelected = _selectedOrderType == label;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedOrderType = label),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, color: isSelected ? primaryColor : Colors.grey.shade600, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primaryColor : const Color(0xFF263238),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodSelector(Color primaryColor) {
    const paymentName = 'Paiement au comptoir (après le repas)';

    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.point_of_sale_rounded,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        paymentName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Unique option',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Le client paie au comptoir (espèces ou carte bancaire) après avoir terminé son repas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_circle_rounded,
            color: primaryColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required Color primaryColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }
}
