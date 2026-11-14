import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class AdminReviewsView extends StatefulWidget {
  final Color primaryColor;

  const AdminReviewsView({super.key, required this.primaryColor});

  @override
  State<AdminReviewsView> createState() => _AdminReviewsViewState();
}

class _AdminReviewsViewState extends State<AdminReviewsView> {
  String _selectedFilter = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _ratingColor(double score) {
    if (score >= 4.5) return const Color(0xFF2E7D32);
    if (score >= 3.5) return const Color(0xFF43A047);
    if (score >= 2.5) return const Color(0xFFFB8C00);
    if (score >= 1.5) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final reviewService = ReviewService();
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return ListenableBuilder(
      listenable: reviewService,
      builder: (context, _) {
        final allReviews = reviewService.reviews;

        // Apply filters
        List<ReviewModel> filteredReviews = allReviews.where((r) {
          if (_selectedFilter == '5 étoiles' && r.overallRating < 4.5) {
            return false;
          }
          if (_selectedFilter == '4 étoiles' &&
              (r.overallRating < 3.5 || r.overallRating >= 4.5)) {
            return false;
          }
          if (_selectedFilter == '≤ 3 étoiles' && r.overallRating >= 3.5) {
            return false;
          }
          if (_selectedFilter == 'Recommandés' && !r.wouldRecommend) {
            return false;
          }

          final query = _searchController.text.trim().toLowerCase();
          if (query.isNotEmpty) {
            final matchName = r.clientName.toLowerCase().contains(query);
            final matchTable = (r.tableNumber ?? '').toLowerCase().contains(query);
            final matchOrder = (r.orderNumber ?? '').toLowerCase().contains(query);
            final matchNote = r.additionalNote.toLowerCase().contains(query);
            final matchTags = r.foodTags.any((t) => t.toLowerCase().contains(query)) ||
                r.serviceTags.any((t) => t.toLowerCase().contains(query)) ||
                r.speedTags.any((t) => t.toLowerCase().contains(query));
            return matchName || matchTable || matchOrder || matchNote || matchTags;
          }

          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KPI / Analytics Header Card
            _buildAnalyticsHeaderCard(reviewService),
            const SizedBox(height: 16),

            // Aspect Breakdown Cards
            _buildAspectsBreakdownCard(reviewService),
            const SizedBox(height: 16),

            // Filters & Search Bar
            _buildFiltersAndSearchBar(),
            const SizedBox(height: 16),

            // Review Count Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Avis reçus (${filteredReviews.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF263238),
                  ),
                ),
                if (_selectedFilter != 'Tous' || _searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'Tous';
                        _searchController.clear();
                      });
                    },
                    child: const Text('Réinitialiser filtres'),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Reviews List
            if (filteredReviews.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final review = filteredReviews[index];
                  return _buildReviewCard(review, dateFormat);
                },
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsHeaderCard(ReviewService reviewService) {
    final overall = reviewService.averageOverall;
    final total = reviewService.totalCount;
    final recommendRate = reviewService.recommendationRatePercentage;
    final color = _ratingColor(overall);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.reviews_rounded, color: widget.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satisfaction Globale Clients',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF263238),
                    ),
                  ),
                  Text(
                    'Synthèse en temps réel de tous les aspects',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF78909C)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Big Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total > 0 ? overall.toStringAsFixed(1) : '–',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 28),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total avis',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF546E7A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Sub statistics
              Expanded(
                child: Column(
                  children: [
                    _buildQuickKpiRow(
                      icon: Icons.thumb_up_alt_rounded,
                      iconColor: const Color(0xFF2E7D32),
                      title: 'Taux de recommandation',
                      value: '$recommendRate%',
                    ),
                    const Divider(height: 16),
                    _buildQuickKpiRow(
                      icon: Icons.verified_user_rounded,
                      iconColor: const Color(0xFF1976D2),
                      title: 'Évaluations vérifiées',
                      value: '$total',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickKpiRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF546E7A)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF263238)),
        ),
      ],
    );
  }

  Widget _buildAspectsBreakdownCard(ReviewService reviewService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Moyenne par aspect de l\'expérience',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 14),
          _buildAspectBarRow(
            label: 'Nourriture & Plats',
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFFD84315),
            score: reviewService.averageFood,
          ),
          const SizedBox(height: 10),
          _buildAspectBarRow(
            label: 'Service & Accueil',
            icon: Icons.volunteer_activism_rounded,
            iconColor: const Color(0xFF1565C0),
            score: reviewService.averageService,
          ),
          const SizedBox(height: 10),
          _buildAspectBarRow(
            label: 'Rapidité & Délais',
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFE65100),
            score: reviewService.averageSpeed,
          ),
          const SizedBox(height: 10),
          _buildAspectBarRow(
            label: 'Ambiance & Propreté',
            icon: Icons.cleaning_services_rounded,
            iconColor: const Color(0xFF00897B),
            score: reviewService.averageAmbiance,
          ),
          const SizedBox(height: 10),
          _buildAspectBarRow(
            label: 'Rapport Qualité/Prix',
            icon: Icons.price_check_rounded,
            iconColor: const Color(0xFF6A1B9A),
            score: reviewService.averageValue,
          ),
        ],
      ),
    );
  }

  Widget _buildAspectBarRow({
    required String label,
    required IconData icon,
    required Color iconColor,
    required double score,
  }) {
    final progress = (score / 5.0).clamp(0.0, 1.0);
    final color = _ratingColor(score);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF37474F),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 44,
          child: Text(
            '${score > 0 ? score.toStringAsFixed(1) : '–'} / 5',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearchBar() {
    final filters = ['Tous', '5 étoiles', '4 étoiles', '≤ 3 étoiles', 'Recommandés'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search textfield
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Rechercher par client, table, mot-clé...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) {
              final isSelected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : const Color(0xFF37474F),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: widget.primaryColor,
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? widget.primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = f);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review, DateFormat dateFormat) {
    final overall = review.overallRating;
    final color = _ratingColor(overall);

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
          // Header: Client Avatar + Name + Date + Overall Score Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: widget.primaryColor.withValues(alpha: 0.15),
                child: Text(
                  review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : 'C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Color(0xFF263238),
                      ),
                    ),
                    Text(
                      dateFormat.format(review.createdAt),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 17),
                    const SizedBox(width: 4),
                    Text(
                      review.overallRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order Reference Tag if available
          if (review.orderNumber != null || review.tableNumber != null || review.orderType != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_rounded, size: 14, color: Color(0xFF546E7A)),
                  const SizedBox(width: 6),
                  Text(
                    [
                      if (review.orderNumber != null) 'Commande #${review.orderNumber}',
                      if (review.orderType != null) review.orderType,
                      if (review.tableNumber != null && review.tableNumber!.isNotEmpty)
                        'Table : ${review.tableNumber}',
                    ].join(' • '),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF546E7A),
                    ),
                  ),
                ],
              ),
            ),

          // Aspects Grid: Food, Service, Speed, Ambiance, Value
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildAspectPill(
                  icon: Icons.restaurant_rounded,
                  label: 'Nourriture',
                  rating: review.foodRating,
                  accentColor: const Color(0xFFD84315),
                ),
                _buildAspectPill(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Service',
                  rating: review.serviceRating,
                  accentColor: const Color(0xFF1565C0),
                ),
                _buildAspectPill(
                  icon: Icons.bolt_rounded,
                  label: 'Rapidité',
                  rating: review.speedRating,
                  accentColor: const Color(0xFFE65100),
                ),
                _buildAspectPill(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Ambiance',
                  rating: review.ambianceRating,
                  accentColor: const Color(0xFF00897B),
                ),
                _buildAspectPill(
                  icon: Icons.price_check_rounded,
                  label: 'Qualité/Prix',
                  rating: review.valueRating,
                  accentColor: const Color(0xFF6A1B9A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Selected Tags across all aspects
          if (_hasAnyTags(review)) ...[
            const Text(
              'Critères sélectionnés par le client :',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF78909C),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...review.foodTags.map((t) => _buildTagChip(t, const Color(0xFFD84315))),
                ...review.serviceTags.map((t) => _buildTagChip(t, const Color(0xFF1565C0))),
                ...review.speedTags.map((t) => _buildTagChip(t, const Color(0xFFE65100))),
                ...review.ambianceTags.map((t) => _buildTagChip(t, const Color(0xFF00897B))),
                ...review.valueTags.map((t) => _buildTagChip(t, const Color(0xFF6A1B9A))),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Client Note (if any)
          if (review.additionalNote.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFECB3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, size: 18, color: Color(0xFFFFA000)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      review.additionalNote,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Footer: Recommendation + Delete Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    review.wouldRecommend
                        ? Icons.recommend_rounded
                        : Icons.thumb_down_alt_rounded,
                    color: review.wouldRecommend
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE53935),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    review.wouldRecommend
                        ? 'Recommande le restaurant'
                        : 'Ne recommande pas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: review.wouldRecommend
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                tooltip: 'Supprimer cet avis',
                onPressed: () => _confirmDeleteReview(review),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasAnyTags(ReviewModel review) {
    return review.foodTags.isNotEmpty ||
        review.serviceTags.isNotEmpty ||
        review.speedTags.isNotEmpty ||
        review.ambianceTags.isNotEmpty ||
        review.valueTags.isNotEmpty;
  }

  Widget _buildAspectPill({
    required IconData icon,
    required String label,
    required int rating,
    required Color accentColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accentColor, size: 14),
        const SizedBox(width: 4),
        Text(
          '$label : ',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF546E7A)),
        ),
        Text(
          '$rating/5',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.rate_review_outlined, size: 48, color: widget.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun avis pour le moment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Les retours et notes laissés par vos clients apparaîtront ici dès qu\'ils rempliront le formulaire.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF78909C)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteReview(ReviewModel review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet avis ?'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'avis de "${review.clientName}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ReviewService().deleteReview(review.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Avis supprimé.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
