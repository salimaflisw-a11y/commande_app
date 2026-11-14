import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';

class ReviewFormPage extends StatefulWidget {
  final OrderModel? order;

  const ReviewFormPage({super.key, this.order});

  static Future<bool?> open(BuildContext context, {OrderModel? order}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewFormPage(order: order),
      ),
    );
  }

  @override
  State<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<ReviewFormPage> {
  static const Color primaryColor = Color(0xFFE65100);

  String? _existingReviewId;

  // Aspect ratings (1 to 5)
  int _foodRating = 5;
  final Set<String> _selectedFoodTags = {};

  int _serviceRating = 5;
  final Set<String> _selectedServiceTags = {};

  int _speedRating = 5;
  final Set<String> _selectedSpeedTags = {};

  int _ambianceRating = 5;
  final Set<String> _selectedAmbianceTags = {};

  int _valueRating = 5;
  final Set<String> _selectedValueTags = {};

  bool _wouldRecommend = true;
  late final TextEditingController _nameController;
  final TextEditingController _noteController = TextEditingController();

  bool _isSubmitting = false;

  // Preset quick tags for each aspect
  static const List<String> foodOptions = [
    'Délicieux',
    'Bien chaud',
    'Portion généreuse',
    'Saveurs équilibrées',
    'Présentation soignée',
    'Ingrédients frais',
    'Cuisson parfaite',
  ];

  static const List<String> serviceOptions = [
    'Personnel souriant',
    'Accueil chaleureux',
    'À l\'écoute',
    'Très serviable',
    'Attentif aux besoins',
    'Professionnel',
  ];

  static const List<String> speedOptions = [
    'Ultra rapide',
    'Temps d\'attente parfait',
    'Service fluide',
    'Plats servis chauds ensemble',
    'Commande prise sans délai',
  ];

  static const List<String> ambianceOptions = [
    'Très propre & net',
    'Cadre agréable',
    'Ambiance conviviale',
    'Musique bien dosée',
    'Table impeccable',
    'Climatisation / Température top',
  ];

  static const List<String> valueOptions = [
    'Excellent rapport Q/P',
    'Prix très abordables',
    'Portions généreuses',
    'Vaut vraiment le détour',
    'Formule avantageuse',
  ];

  @override
  void initState() {
    super.initState();
    final auth = AuthService();
    final initialName = widget.order?.customerName.isNotEmpty == true
        ? widget.order!.customerName
        : (auth.isLoggedIn ? auth.displayName : '');
    _nameController = TextEditingController(text: initialName);

    // If an existing review exists for this order, pre-fill it for Update (CRUD)
    final existing = ReviewService().getReviewForOrder(widget.order?.id);
    if (existing != null) {
      _existingReviewId = existing.id;
      _foodRating = existing.foodRating;
      _selectedFoodTags.addAll(existing.foodTags);
      _serviceRating = existing.serviceRating;
      _selectedServiceTags.addAll(existing.serviceTags);
      _speedRating = existing.speedRating;
      _selectedSpeedTags.addAll(existing.speedTags);
      _ambianceRating = existing.ambianceRating;
      _selectedAmbianceTags.addAll(existing.ambianceTags);
      _valueRating = existing.valueRating;
      _selectedValueTags.addAll(existing.valueTags);
      _wouldRecommend = existing.wouldRecommend;
      _noteController.text = existing.additionalNote;
    } else {
      // Default pre-selected tags for a great initial experience
      _selectedFoodTags.add('Délicieux');
      _selectedServiceTags.add('Personnel souriant');
      _selectedSpeedTags.add('Temps d\'attente parfait');
      _selectedAmbianceTags.add('Très propre & net');
      _selectedValueTags.add('Excellent rapport Q/P');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _computedOverall {
    return (_foodRating +
            _serviceRating +
            _speedRating +
            _ambianceRating +
            _valueRating) /
        5.0;
  }

  String _ratingLabel(int stars) {
    switch (stars) {
      case 5:
        return 'Excellent ! ⭐⭐⭐⭐⭐';
      case 4:
        return 'Très bon ⭐⭐⭐⭐';
      case 3:
        return 'Bon ⭐⭐⭐';
      case 2:
        return 'Moyen ⭐⭐';
      case 1:
      default:
        return 'Décevant ⭐';
    }
  }

  Color _ratingColor(int stars) {
    switch (stars) {
      case 5:
        return const Color(0xFF2E7D32);
      case 4:
        return const Color(0xFF43A047);
      case 3:
        return const Color(0xFFFB8C00);
      case 2:
        return const Color(0xFFFF9800);
      case 1:
      default:
        return const Color(0xFFE53935);
    }
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    final clientName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Client';

    setState(() => _isSubmitting = true);

    try {
      final auth = AuthService();
      final review = ReviewModel.create(
        id: _existingReviewId ?? '',
        clientId: auth.currentUser?.id,
        clientName: clientName,
        clientPhone: widget.order?.customerPhone,
        orderId: widget.order?.id,
        orderNumber: widget.order != null
            ? (widget.order!.id.length >= 6
                ? widget.order!.id.substring(widget.order!.id.length - 6).toUpperCase()
                : widget.order!.id)
            : null,
        orderType: widget.order?.orderType,
        tableNumber: widget.order?.tableNumber,
        foodRating: _foodRating,
        foodTags: _selectedFoodTags.toList(),
        serviceRating: _serviceRating,
        serviceTags: _selectedServiceTags.toList(),
        speedRating: _speedRating,
        speedTags: _selectedSpeedTags.toList(),
        ambianceRating: _ambianceRating,
        ambianceTags: _selectedAmbianceTags.toList(),
        valueRating: _valueRating,
        valueTags: _selectedValueTags.toList(),
        wouldRecommend: _wouldRecommend,
        additionalNote: _noteController.text.trim(),
      );

      await ReviewService().submitReview(review);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Merci beaucoup ! Votre évaluation a été transmise à l\'équipe.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi : $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final overall = _computedOverall;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Évaluation de votre expérience',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFF263238),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: const Color(0xFF263238),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order details if provided
            if (widget.order != null) _buildOrderInfoCard(),

            // Top Live Score Summary Card
            _buildOverallScoreCard(overall),
            const SizedBox(height: 16),

            // Form Description Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: primaryColor, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Formulaire rapide : sélectionnez votre note pour chaque aspect et touchez les critères correspondants.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF37474F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Aspect: Nourriture
            _buildAspectCard(
              title: 'Qualité des Plats & Boissons',
              subtitle: 'Goût, fraîcheur, température et portions',
              icon: Icons.restaurant_rounded,
              accentColor: const Color(0xFFD84315),
              currentRating: _foodRating,
              onRatingChanged: (val) => setState(() => _foodRating = val),
              options: foodOptions,
              selectedTags: _selectedFoodTags,
            ),
            const SizedBox(height: 16),

            // 2. Aspect: Service
            _buildAspectCard(
              title: 'Service & Accueil',
              subtitle: 'Amabilité, courtoisie et écoute du personnel',
              icon: Icons.volunteer_activism_rounded,
              accentColor: const Color(0xFF1565C0),
              currentRating: _serviceRating,
              onRatingChanged: (val) => setState(() => _serviceRating = val),
              options: serviceOptions,
              selectedTags: _selectedServiceTags,
            ),
            const SizedBox(height: 16),

            // 3. Aspect: Rapidité
            _buildAspectCard(
              title: 'Rapidité & Délais',
              subtitle: 'Temps de préparation et attente de service',
              icon: Icons.bolt_rounded,
              accentColor: const Color(0xFFE65100),
              currentRating: _speedRating,
              onRatingChanged: (val) => setState(() => _speedRating = val),
              options: speedOptions,
              selectedTags: _selectedSpeedTags,
            ),
            const SizedBox(height: 16),

            // 4. Aspect: Ambiance & Propreté
            _buildAspectCard(
              title: 'Ambiance & Propreté',
              subtitle: 'Hygiène des tables, confort et atmosphère',
              icon: Icons.cleaning_services_rounded,
              accentColor: const Color(0xFF00897B),
              currentRating: _ambianceRating,
              onRatingChanged: (val) => setState(() => _ambianceRating = val),
              options: ambianceOptions,
              selectedTags: _selectedAmbianceTags,
            ),
            const SizedBox(height: 16),

            // 5. Aspect: Rapport Qualité/Prix
            _buildAspectCard(
              title: 'Rapport Qualité / Prix',
              subtitle: 'Tarifs par rapport à la qualité servie',
              icon: Icons.price_check_rounded,
              accentColor: const Color(0xFF6A1B9A),
              currentRating: _valueRating,
              onRatingChanged: (val) => setState(() => _valueRating = val),
              options: valueOptions,
              selectedTags: _selectedValueTags,
            ),
            const SizedBox(height: 16),

            // Recommendation Selector
            _buildRecommendationCard(),
            const SizedBox(height: 16),

            // Client Name & Optional Short Note
            _buildClientInfoSection(),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Envoi en cours...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_existingReviewId != null ? Icons.check_circle_rounded : Icons.send_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _existingReviewId != null ? 'Mettre à jour mon évaluation' : 'Envoyer mon évaluation',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final o = widget.order!;
    final shortId = o.id.length >= 6
        ? o.id.substring(o.id.length - 6).toUpperCase()
        : o.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande #$shortId • ${o.orderType}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF263238)),
                ),
                if (o.tableNumber != null && o.tableNumber!.isNotEmpty)
                  Text(
                    'Table : ${o.tableNumber}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Confirmée',
              style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(double overall) {
    final label = _ratingLabel(overall.round().clamp(1, 5));
    final color = _ratingColor(overall.round().clamp(1, 5));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                overall.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score global de votre visite',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF546E7A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Moyenne calculée automatiquement sur vos 5 critères ci-dessous',
                  style: TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required int currentRating,
    required ValueChanged<int> onRatingChanged,
    required List<String> options,
    required Set<String> selectedTags,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aspect Title Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF263238),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF78909C)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _ratingColor(currentRating).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$currentRating / 5',
                  style: TextStyle(
                    color: _ratingColor(currentRating),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rating Bar (Interactive Stars)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int star = 1; star <= 5; star++)
                  InkWell(
                    onTap: () => onRatingChanged(star),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Icon(
                        star <= currentRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: star <= currentRating
                            ? const Color(0xFFFFB300)
                            : Colors.grey.shade400,
                        size: 34,
                      ),
                    ),
                  ),
                Text(
                  _ratingLabel(currentRating).split(' ').first,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _ratingColor(currentRating),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick selection chips
          const Text(
            'Choisissez les points clés constatés :',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF546E7A),
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.map((opt) {
              final isSelected = selectedTags.contains(opt);
              return FilterChip(
                label: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : const Color(0xFF37474F),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                avatar: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
                selectedColor: accentColor,
                backgroundColor: const Color(0xFFF1F3F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? accentColor : Colors.transparent,
                  ),
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      selectedTags.add(opt);
                    } else {
                      selectedTags.remove(opt);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.recommend_rounded, color: primaryColor, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recommanderiez-vous notre restaurant ?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: Color(0xFF263238),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('👍 Oui, absolument', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  selected: _wouldRecommend,
                  selectedColor: const Color(0xFF2E7D32),
                  labelStyle: TextStyle(
                    color: _wouldRecommend ? Colors.white : const Color(0xFF37474F),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val) setState(() => _wouldRecommend = true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('👎 Non, pas trop', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  selected: !_wouldRecommend,
                  selectedColor: const Color(0xFFE53935),
                  labelStyle: TextStyle(
                    color: !_wouldRecommend ? Colors.white : const Color(0xFF37474F),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val) setState(() => _wouldRecommend = false);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations complémentaires (facultatif)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Votre prénom ou pseudo',
              prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 180,
            decoration: InputDecoration(
              labelText: 'Un commentaire ou compliment rapide ? (Optionnel)',
              hintText: 'Ex: Superbe accueil et tiramisu incroyable !',
              prefixIcon: const Icon(Icons.edit_note_rounded, color: primaryColor),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
