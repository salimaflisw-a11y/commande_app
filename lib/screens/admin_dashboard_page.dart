import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/menu_item_model.dart';
import '../models/category_model.dart';
import '../models/supplement_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/menu_service.dart';
import '../services/review_service.dart';
import '../widgets/admin_reviews_view.dart';
import 'login_page.dart';
import 'pdf_preview_page.dart';
import '../widgets/qr_payment_dialogs.dart';
import 'table_qr_codes_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentTabIndex = 0;

  // Orders filter
  String _selectedOrderFilter = 'Toutes';
  final TextEditingController _orderSearchController = TextEditingController();

  // Menu filter
  String _selectedMenuCategory = 'Toutes';

  @override
  void dispose() {
    _orderSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmLogout(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: const Color(0xFF263238),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tableau de bord Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF263238),
                  ),
                ),
                Text(
                  'Gestion restaurant & commandes en direct',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF78909C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Déconnexion',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildStatsView(primaryColor),
          _buildOrdersView(primaryColor),
          _buildMenuView(primaryColor),
          _buildCategoriesView(primaryColor),
          _buildSupplementsView(primaryColor),
          AdminReviewsView(primaryColor: primaryColor),
          const TableQrCodesPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        backgroundColor: Colors.white,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: primaryColor),
            label: 'Statistiques',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: primaryColor),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded, color: primaryColor),
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded, color: primaryColor),
            label: 'Catégories',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded, color: primaryColor),
            label: 'Suppléments',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review_rounded, color: primaryColor),
            label: 'Avis clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_outlined),
            selectedIcon: Icon(Icons.qr_code_rounded, color: primaryColor),
            label: 'QR Tables',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showAddOrEditMenuItemDialog(context),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvel Article', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : _currentTabIndex == 3
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddOrEditCategoryDialog(context),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nouvelle Catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : _currentTabIndex == 4
                  ? FloatingActionButton.extended(
                      onPressed: () => _showAddOrEditSupplementDialog(context),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nouveau Supplément', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  : null,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 1. STATS / VUE D'ENSEMBLE
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildStatsView(Color primaryColor) {
    return ListenableBuilder(
      listenable: OrderService(),
      builder: (context, _) {
        final orders = OrderService().orders;

        final now = DateTime.now();
        final todayOrders = orders.where((o) =>
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day).toList();

        final totalRevenue = orders
            .where((o) => o.status != 'Rejetée')
            .fold(0.0, (acc, o) => acc + o.totalTtc);

        final todayRevenue = todayOrders
            .where((o) => o.status != 'Rejetée')
            .fold(0.0, (acc, o) => acc + o.totalTtc);

        final pendingCount = orders.where((o) => o.status == 'En attente').length;
        final deliveredCount = orders.where((o) => o.status == 'Livrée').length;
        final rejectedCount = orders.where((o) => o.status == 'Rejetée').length;

        final unpaidDelivered = orders
            .where((o) => o.paymentStatus == 'unpaid' && o.status != 'Rejetée')
            .toList();
        final unpaidAmount = unpaidDelivered.fold(0.0, (acc, o) => acc + o.totalTtc);

        // Active tables
        final activeTables = orders
            .where((o) => o.paymentStatus == 'unpaid' && o.tableNumber != null && o.tableNumber!.isNotEmpty)
            .map((o) => o.tableNumber!)
            .toSet()
            .toList();

        // Top 5 dishes
        final Map<String, int> productCounts = {};
        for (var o in orders.where((o) => o.status != 'Rejetée')) {
          for (var item in o.items) {
            productCounts[item.item.name] = (productCounts[item.item.name] ?? 0) + item.quantity;
          }
        }
        final topDishes = productCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Welcome card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '• DIRECT RESTAURANT',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bonjour, ${AuthService().displayName} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${todayOrders.length} commande(s) enregistrée(s) aujourd\'hui.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // KPI Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Chiffre d\'Affaires Global',
                    value: '${totalRevenue.toStringAsFixed(2)} €',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF2E7D32),
                    subtext: '${orders.length} commandes au total',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'CA Aujourd\'hui',
                    value: '${todayRevenue.toStringAsFixed(2)} €',
                    icon: Icons.today_rounded,
                    color: const Color(0xFF1565C0),
                    subtext: '${todayOrders.length} comm. du jour',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'En attente',
                    value: '$pendingCount',
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFE65100),
                    subtext: 'Nécessitent validation',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'À Encaisser',
                    value: '${unpaidAmount.toStringAsFixed(2)} €',
                    icon: Icons.price_check_rounded,
                    color: const Color(0xFFC2185B),
                    subtext: '${unpaidDelivered.length} table(s) non réglée(s)',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Customer Satisfaction Card
            ListenableBuilder(
              listenable: ReviewService(),
              builder: (context, _) {
                final reviewService = ReviewService();
                final totalReviews = reviewService.totalCount;
                final avgScore = reviewService.averageOverall;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              totalReviews > 0
                                  ? 'Satisfaction Client : ${avgScore.toStringAsFixed(1)} / 5 ⭐'
                                  : 'Avis & Retours Clients',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: Color(0xFF263238),
                              ),
                            ),
                            Text(
                              totalReviews > 0
                                  ? '$totalReviews évaluation(s) • ${reviewService.recommendationRatePercentage}% recommandent'
                                  : 'Consultez les notes des clients par aspect',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _currentTabIndex = 5),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Voir avis', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Order Status Breakdown
            _buildCardContainer(
              title: 'Répartition des Commandes',
              icon: Icons.pie_chart_outline_rounded,
              child: Column(
                children: [
                  _buildStatusProgressBar('En attente', pendingCount, orders.length, const Color(0xFFE65100)),
                  const SizedBox(height: 10),
                  _buildStatusProgressBar('Livrées', deliveredCount, orders.length, const Color(0xFF2E7D32)),
                  const SizedBox(height: 10),
                  _buildStatusProgressBar('Rejetées', rejectedCount, orders.length, Colors.redAccent),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Active Tables Overview
            _buildCardContainer(
              title: 'Occupation des Tables (${activeTables.length} active(s))',
              icon: Icons.table_restaurant_rounded,
              child: activeTables.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Toutes les tables sont actuellement réglées ou libérées.',
                        style: TextStyle(color: Color(0xFF78909C), fontSize: 13),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activeTables.map((table) {
                        return Chip(
                          avatar: const Icon(Icons.table_restaurant_outlined, size: 16, color: Color(0xFFE65100)),
                          label: Text(table, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: const Color(0xFFFFF3E0),
                          side: const BorderSide(color: Color(0xFFFFCC80)),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 20),

            // Top Dishes
            _buildCardContainer(
              title: 'Top Plats les Plus Commandés',
              icon: Icons.leaderboard_rounded,
              child: topDishes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aucune commande enregistrée pour établir le classement.',
                        style: TextStyle(color: Color(0xFF78909C), fontSize: 13),
                      ),
                    )
                  : Column(
                      children: topDishes.take(5).map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${topDishes.indexOf(entry) + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.value} vendus',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 20),

            // Quick live orders button
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentTabIndex = 1),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Accéder aux Commandes & Reçus en direct'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF546E7A)),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFE65100)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusProgressBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF455A64))),
            Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 2. COMMANDES & REÇUS ("HE IS THE ONE THE REÇU GETS SENT TO")
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildOrdersView(Color primaryColor) {
    return ListenableBuilder(
      listenable: OrderService(),
      builder: (context, _) {
        final orderService = OrderService();
        final allOrders = orderService.orders;

        // Filter list
        final filtered = allOrders.where((o) {
          if (_selectedOrderFilter == 'En attente' && o.status != 'En attente') return false;
          if (_selectedOrderFilter == 'Livrées' && o.status != 'Livrée') return false;
          if (_selectedOrderFilter == 'Rejetées' && o.status != 'Rejetée') return false;
          if (_selectedOrderFilter == 'Impayées' && (o.paymentStatus != 'unpaid' || o.status == 'Rejetée')) {
            return false;
          }

          final query = _orderSearchController.text.trim().toLowerCase();
          if (query.isNotEmpty) {
            final matchId = o.id.toLowerCase().contains(query);
            final matchName = o.customerName.toLowerCase().contains(query);
            final matchTable = o.tableNumber?.toLowerCase().contains(query) ?? false;
            return matchId || matchName || matchTable;
          }
          return true;
        }).toList();

        final pendingCount = allOrders.where((o) => o.status == 'En attente').length;
        final unpaidCount = allOrders.where((o) => o.paymentStatus == 'unpaid' && o.status != 'Rejetée').length;

        return Column(
          children: [
            // Filter chips header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _orderSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par Table, Nom ou N° Commande...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _orderSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _orderSearchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Toutes', allOrders.length),
                        _buildFilterChip('En attente', pendingCount, badgeColor: const Color(0xFFE65100)),
                        _buildFilterChip('Livrées', allOrders.where((o) => o.status == 'Livrée').length),
                        _buildFilterChip('Rejetées', allOrders.where((o) => o.status == 'Rejetée').length),
                        _buildFilterChip('Impayées', unpaidCount, badgeColor: const Color(0xFFC2185B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Orders list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune commande trouvée ($_selectedOrderFilter)',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        return _buildAdminOrderCard(order, orderService, primaryColor);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int count, {Color? badgeColor}) {
    final isSelected = _selectedOrderFilter == label;
    final primaryColor = const Color(0xFFE65100);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white24
                    : (badgeColor?.withValues(alpha: 0.15) ?? Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (badgeColor ?? const Color(0xFF546E7A)),
                ),
              ),
            ),
          ],
        ),
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF37474F),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12.5,
        ),
        onSelected: (_) => setState(() => _selectedOrderFilter = label),
      ),
    );
  }

  Widget _buildAdminOrderCard(OrderModel order, OrderService orderService, Color primaryColor) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    Color statusColor;
    if (order.status == 'Livrée') {
      statusColor = const Color(0xFF2E7D32);
    } else if (order.status == 'Rejetée') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = const Color(0xFFE65100);
    }

    final isPaid = order.paymentStatus == 'paid';

    return Container(
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
        border: Border.all(
          color: order.status == 'En attente'
              ? const Color(0xFFFFB74D)
              : (order.clientLeftWithoutPaying ? Colors.redAccent : Colors.grey.shade200),
          width: order.status == 'En attente' || order.clientLeftWithoutPaying ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                // Table badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.table_restaurant_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        order.tableNumber ?? 'Comptoir',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF78909C)),
                      ),
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Items summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            item.item.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${item.totalPrice.toStringAsFixed(2)} €',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),

                if (order.specialNotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFECB3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFFE65100)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Remarque cuisine: ${order.specialNotes}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFE65100), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Totals and Payment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Payment Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                        : (order.clientLeftWithoutPaying
                            ? Colors.redAccent.withValues(alpha: 0.1)
                            : Colors.amber.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : (order.clientLeftWithoutPaying ? Icons.warning : Icons.payment),
                        size: 13,
                        color: isPaid
                            ? const Color(0xFF2E7D32)
                            : (order.clientLeftWithoutPaying ? Colors.redAccent : const Color(0xFFE65100)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? 'Payée' : (order.clientLeftWithoutPaying ? 'Parti sans payer' : 'À régler au comptoir'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? const Color(0xFF2E7D32)
                              : (order.clientLeftWithoutPaying ? Colors.redAccent : const Color(0xFFE65100)),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Total TTC : ${order.totalTtc.toStringAsFixed(2)} €',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                ),
              ],
            ),
          ),

          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                // PDF Invoice / Receipt
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PdfPreviewPage(order: order)),
                    );
                  },
                  icon: const Icon(Icons.receipt_rounded, size: 16),
                  label: const Text('Reçu PDF', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF37474F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),

                // If unpaid, show Settle Bill button
                if (!isPaid && order.status != 'Rejetée') ...[
                  ElevatedButton.icon(
                    onPressed: () => CashierQrPaymentDialog.show(context, order),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                    label: const Text('QR Caisse', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => orderService.updatePaymentStatus(order.id, 'paid'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Encaisser', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  if (!order.clientLeftWithoutPaying)
                    TextButton.icon(
                      onPressed: () => orderService.markClientLeftWithoutPaying(order.id),
                      icon: const Icon(Icons.gavel_rounded, size: 16, color: Colors.redAccent),
                      label: const Text('Impayé', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ),
                ],

                // If pending, show deliver and reject buttons
                if (order.status == 'En attente') ...[
                  ElevatedButton.icon(
                    onPressed: () => orderService.updateOrderStatus(order.id, 'Livrée'),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Livrer', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => orderService.updateOrderStatus(order.id, 'Rejetée'),
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('Rejeter', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 3. GESTION DU MENU & CATÉGORIES (RESPONSIBLE FOR CREATING THE MENU)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildMenuView(Color primaryColor) {
    return ListenableBuilder(
      listenable: MenuService(),
      builder: (context, _) {
        final menuService = MenuService();
        final categories = menuService.categories;
        final allItems = menuService.items;

        // Fall back to 'Toutes' if the selected category was deleted
        final selectedCategory = categories.any((c) => c.label == _selectedMenuCategory)
            ? _selectedMenuCategory
            : 'Toutes';

        final filteredItems = selectedCategory == 'Toutes'
            ? allItems
            : menuService.getItemsForCategory(selectedCategory);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // ── Section 1: Category filter (managed in the 'Catégories' tab) ──
            const Text(
              'Filtrer par catégorie',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('✨ Toutes (${allItems.length})'),
                      selected: selectedCategory == 'Toutes',
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: selectedCategory == 'Toutes' ? Colors.white : const Color(0xFF37474F),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _selectedMenuCategory = 'Toutes'),
                    ),
                  ),
                  ...categories.map((cat) {
                    final isSelected = selectedCategory == cat.label;
                    final count = menuService.getItemsForCategory(cat.label).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Text(cat.emoji),
                        label: Text('${cat.label} ($count)'),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF37474F),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => _selectedMenuCategory = cat.label),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section 2: Products List ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Articles (${filteredItems.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                ),
                Text(
                  'Filtré: $selectedCategory',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (filteredItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun plat dans cette catégorie.',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddOrEditMenuItemDialog(context, initialCategory: selectedCategory),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer le premier plat'),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              )
            else
              ...filteredItems.map((item) {
                return _buildAdminMenuItemCard(item, menuService, primaryColor);
              }),
          ],
        );
      },
    );
  }

  Widget _buildAdminMenuItemCard(MenuItemModel item, MenuService menuService, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 75,
              height: 75,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 75,
                height: 75,
                color: Colors.grey.shade200,
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      '${item.price.toStringAsFixed(2)} €',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.categoryLabel,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF546E7A)),
                      ),
                    ),
                    if (item.isVegetarian)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('🌱 Végétarien',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ),
                    if (item.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('⭐ Populaire',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons: Edit & Delete
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1976D2)),
                tooltip: 'Modifier l\'article',
                onPressed: () => _showAddOrEditMenuItemDialog(context, existingItem: item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                tooltip: 'Supprimer l\'article',
                onPressed: () => _confirmDeleteItem(context, item, menuService),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // 4. GESTION DES CATÉGORIES
  // ═════════════════════════════════════════════════════════════════

  Widget _buildCategoriesView(Color primaryColor) {
    return ListenableBuilder(
      listenable: MenuService(),
      builder: (context, _) {
        final menuService = MenuService();
        final categories = menuService.categories;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Text(
              'Catégories (${categories.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 12),

            if (categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune catégorie pour le moment.',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddOrEditCategoryDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer la première catégorie'),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              )
            else
              ...categories.map((cat) => _buildAdminCategoryCard(cat, menuService, primaryColor)),
          ],
        );
      },
    );
  }

  Widget _buildAdminCategoryCard(CategoryModel cat, MenuService menuService, Color primaryColor) {
    final itemCount = menuService.getItemsForCategory(cat.label).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              cat.bannerImageUrl,
              width: 75,
              height: 75,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 75,
                height: 75,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: Text(cat.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cat.emoji} ${cat.label}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  cat.subtitle.isNotEmpty ? cat.subtitle : 'Aucune description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$itemCount article${itemCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons: Edit & Delete
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1976D2)),
                tooltip: 'Modifier la catégorie',
                onPressed: () => _showAddOrEditCategoryDialog(context, existingCat: cat),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                tooltip: 'Supprimer la catégorie',
                onPressed: () => _confirmDeleteCategory(context, cat, menuService),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryModel cat, MenuService menuService) {
    final itemCount = menuService.getItemsForCategory(cat.label).length;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text(
          itemCount > 0
              ? 'Voulez-vous vraiment supprimer "${cat.label}" ?\n\n'
                  'Attention : $itemCount article${itemCount > 1 ? 's' : ''} de cette catégorie '
                  '${itemCount > 1 ? 'seront également supprimés' : 'sera également supprimé'}.'
              : 'Voulez-vous vraiment supprimer "${cat.label}" ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await menuService.deleteCategory(cat);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Catégorie "${cat.label}" supprimée.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // SUPPLÉMENTS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildSupplementsView(Color primaryColor) {
    return ListenableBuilder(
      listenable: MenuService(),
      builder: (context, _) {
        final menuService = MenuService();
        final supplements = menuService.supplements;
        final groups = menuService.supplementGroups();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Text(
              'Suppléments (${supplements.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 12),

            if (supplements.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun supplément pour le moment.',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddOrEditSupplementDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer le premier supplément'),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              )
            else
              for (final group in [...groups, if (supplements.any((s) => s.category.trim().isEmpty)) '']) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: Text(
                    group.isEmpty ? 'Sans groupe' : group,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                ),
                ...supplements
                    .where((s) => s.category.trim() == group)
                    .map((s) => _buildAdminSupplementCard(s, menuService, primaryColor)),
              ],
          ],
        );
      },
    );
  }

  Widget _buildAdminSupplementCard(SupplementModel supp, MenuService menuService, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(supp.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supp.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '+${supp.price.toStringAsFixed(2)} €',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    if (!supp.isAvailable) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Indisponible',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1976D2)),
            tooltip: 'Modifier le supplément',
            onPressed: () => _showAddOrEditSupplementDialog(context, existing: supp),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
            tooltip: 'Supprimer le supplément',
            onPressed: () => _confirmDeleteSupplement(context, supp, menuService),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplement(BuildContext context, SupplementModel supp, MenuService menuService) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer le supplément ?'),
        content: Text('Voulez-vous vraiment supprimer "${supp.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await menuService.deleteSupplement(supp.id);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Supplément "${supp.name}" supprimé.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditSupplementDialog(BuildContext context, {SupplementModel? existing}) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final groupCtrl = TextEditingController(text: existing?.category ?? '');
    final iconCtrl = TextEditingController(text: existing?.icon ?? '➕');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(2) : '');
    bool isAvailable = existing?.isAvailable ?? true;
    final existingGroups = MenuService().supplementGroups();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setSuppState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_rounded, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Modifier le Supplément' : 'Nouveau Supplément',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom du supplément *', hintText: 'Ex: Sauce Algérienne'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: groupCtrl,
                    onChanged: (_) => setSuppState(() {}),
                    decoration: const InputDecoration(labelText: 'Groupe *', hintText: 'Ex: Sauces, Boissons, Extras'),
                  ),
                  if (existingGroups.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: existingGroups.map((g) {
                        final selected = groupCtrl.text.trim() == g;
                        return ChoiceChip(
                          label: Text(g, style: const TextStyle(fontSize: 11)),
                          selected: selected,
                          onSelected: (_) {
                            groupCtrl.text = g;
                            setSuppState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: iconCtrl,
                          decoration: const InputDecoration(labelText: 'Emoji', hintText: 'Ex: 🥫, 🍟, 🥤'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Prix (€) *', hintText: 'Ex: 0.50'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible', style: TextStyle(fontSize: 14)),
                    value: isAvailable,
                    activeThumbColor: const Color(0xFFE65100),
                    onChanged: (v) => setSuppState(() => isAvailable = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final group = groupCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
                final messenger = ScaffoldMessenger.of(context);
                if (name.isEmpty || group.isEmpty || price == null || price < 0) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez renseigner un nom, un groupe et un prix valide.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                final supp = SupplementModel(
                  id: existing?.id ?? '',
                  name: name,
                  category: group,
                  icon: iconCtrl.text.trim().isEmpty ? '➕' : iconCtrl.text.trim(),
                  price: price,
                  isAvailable: isAvailable,
                );
                await MenuService().saveSupplement(supp);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Supplément "$name" mis à jour dans Firestore !'
                        : 'Supplément "$name" enregistré dans Firestore !'),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              },
              child: Text(isEditing ? 'Enregistrer' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // DIALOGS: ADD CATEGORY & ADD/EDIT MENU ITEM
  // ══════════════════════════════════════════════════════════════════════════════

  void _showAddOrEditCategoryDialog(BuildContext context, {CategoryModel? existingCat}) {
    final isEditing = existingCat != null;
    final nameCtrl = TextEditingController(text: existingCat?.label ?? '');
    final emojiCtrl = TextEditingController(text: existingCat?.emoji ?? '🍽️');
    final subtitleCtrl = TextEditingController(text: existingCat?.subtitle ?? '');
    final imageCtrl = TextEditingController(
      text: existingCat?.bannerImageUrl ??
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setCatState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.category_rounded, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Modifier la Catégorie' : 'Nouvelle Catégorie',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom de la catégorie *', hintText: 'Ex: Pizzas, Salades...'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emojiCtrl,
                    decoration: const InputDecoration(labelText: 'Emoji *', hintText: 'Ex: 🍕, 🥗, 🍣'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subtitleCtrl,
                    decoration: const InputDecoration(labelText: 'Description / Sous-titre', hintText: 'Ex: Pizzas cuites au feu de bois'),
                  ),
                  const SizedBox(height: 12),

                  // URL de l'image de bannière avec aperçu en direct
                  TextField(
                    controller: imageCtrl,
                    onChanged: (_) => setCatState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Bannière de catégorie (URL Internet) *',
                      hintText: 'https://site.com/image-banniere.jpg',
                      prefixIcon: const Icon(Icons.link_rounded),
                      suffixIcon: imageCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                imageCtrl.clear();
                                setCatState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildLiveImagePreview(imageCtrl.text.trim()),

                  const SizedBox(height: 8),

                  _buildQuickImagePresets((presetUrl) {
                    imageCtrl.text = presetUrl;
                    setCatState(() {});
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                if (isEditing) {
                  final updated = existingCat.copyWith(
                    label: nameCtrl.text.trim(),
                    emoji: emojiCtrl.text.trim().isEmpty ? '🍽️' : emojiCtrl.text.trim(),
                    subtitle: subtitleCtrl.text.trim(),
                    bannerImageUrl: imageCtrl.text.trim(),
                  );
                  await MenuService().updateCategory(updated, previousLabel: existingCat.label);
                  if (_selectedMenuCategory == existingCat.label) {
                    setState(() => _selectedMenuCategory = updated.label);
                  }
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Catégorie "${updated.label}" mise à jour dans Firestore !'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                } else {
                  await MenuService().addCategory(
                    label: nameCtrl.text.trim(),
                    emoji: emojiCtrl.text.trim(),
                    subtitle: subtitleCtrl.text.trim(),
                    bannerImageUrl: imageCtrl.text.trim(),
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Catégorie "${nameCtrl.text}" enregistrée dans Firestore !'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Enregistrer' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditMenuItemDialog(BuildContext context, {MenuItemModel? existingItem, String? initialCategory}) {
    final isEditing = existingItem != null;
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final descCtrl = TextEditingController(text: existingItem?.description ?? '');
    final priceCtrl = TextEditingController(text: existingItem != null ? existingItem.price.toString() : '');
    final imageCtrl = TextEditingController(text: existingItem?.imageUrl ?? '');
    final prepCtrl = TextEditingController(text: existingItem?.prepTime ?? '15 min');
    final calCtrl = TextEditingController(text: existingItem != null ? existingItem.calories.toString() : '450');
    final ingCtrl = TextEditingController(text: existingItem?.ingredients.join(', ') ?? '');

    final categories = MenuService().categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Créez d\'abord une catégorie dans l\'onglet "Catégories".')),
      );
      return;
    }
    String selectedCat = existingItem?.categoryLabel ??
        (initialCategory != null && initialCategory != 'Toutes' ? initialCategory : categories.first.label);

    bool isVeg = existingItem?.isVegetarian ?? false;
    bool isPop = existingItem?.isPopular ?? false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEditing ? 'Modifier l\'Article' : 'Ajouter un Article au Menu',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom du plat *', hintText: 'Ex: Burger Gourmet'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Prix (€) *', hintText: '11.50'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: categories.any((c) => c.label == selectedCat) ? selectedCat : categories.first.label,
                          decoration: const InputDecoration(labelText: 'Catégorie *'),
                          items: categories.map((c) {
                            return DropdownMenuItem(value: c.label, child: Text('${c.emoji} ${c.label}'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCat = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', hintText: 'Ingrédients principaux, recette...'),
                  ),
                  const SizedBox(height: 12),
                  // ── Image URL input from the internet ──
                  TextField(
                    controller: imageCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Image du plat (URL Internet) *',
                      hintText: 'https://site.com/mon-image.jpg',
                      prefixIcon: const Icon(Icons.link_rounded),
                      suffixIcon: imageCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                imageCtrl.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Live Preview Box from the internet
                  _buildLiveImagePreview(imageCtrl.text.trim()),

                  const SizedBox(height: 8),

                  // Quick presets from internet
                  _buildQuickImagePresets((presetUrl) {
                    imageCtrl.text = presetUrl;
                    setDialogState(() {});
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: prepCtrl,
                          decoration: const InputDecoration(labelText: 'Temps prép.', hintText: '10-15 min'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: calCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Calories (kcal)', hintText: '500'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ingCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ingrédients (séparés par virgules)',
                      hintText: 'Bœuf, Fromage, Oignons...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Option Végétarienne 🌱'),
                    value: isVeg,
                    onChanged: (val) => setDialogState(() => isVeg = val),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Mettre en Vedette ⭐'),
                    value: isPop,
                    onChanged: (val) => setDialogState(() => isPop = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez spécifier un nom et un prix valide.')),
                  );
                  return;
                }

                final ingredients = ingCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final newItem = MenuItemModel(
                  id: existingItem?.id ?? '',
                  name: name,
                  description: descCtrl.text.trim(),
                  price: price,
                  category: selectedCat,
                  imageUrl: imageCtrl.text.trim().isNotEmpty
                      ? imageCtrl.text.trim()
                      : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
                  prepTime: prepCtrl.text.trim().isNotEmpty ? prepCtrl.text.trim() : '15 min',
                  calories: int.tryParse(calCtrl.text.trim()) ?? 450,
                  ingredients: ingredients,
                  isVegetarian: isVeg,
                  isPopular: isPop,
                );

                final messenger = ScaffoldMessenger.of(context);
                await MenuService().saveMenuItem(newItem);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isEditing ? 'Plat "$name" mis à jour !' : 'Plat "$name" ajouté au menu !'),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              },
              child: Text(isEditing ? 'Enregistrer' : 'Ajouter au Menu'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteItem(BuildContext context, MenuItemModel item, MenuService menuService) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer l\'article ?'),
        content: Text('Voulez-vous vraiment retirer "${item.name}" du menu ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await menuService.deleteMenuItem(item.id);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              messenger.showSnackBar(
                SnackBar(content: Text('Article "${item.name}" supprimé.')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Déconnexion Admin'),
        content: const Text('Souhaitez-vous fermer votre session administrateur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogCtx);
              AuthService().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveImagePreview(String url) {
    if (url.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 28, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              'Collez une URL d\'image depuis internet pour voir l\'aperçu ici',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 125,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.5)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.red.shade50,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_rounded, color: Colors.redAccent, size: 26),
                    const SizedBox(height: 4),
                    Text(
                      'Image inaccessible via cette URL internet.\nVérifiez le lien.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 11),
                  SizedBox(width: 4),
                  Text('Aperçu web direct', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickImagePresets(Function(String) onSelect) {
    final presets = [
      {'name': 'Burger 🍔', 'url': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80'},
      {'name': 'Pizza 🍕', 'url': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80'},
      {'name': 'Tacos 🌮', 'url': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=800&q=80'},
      {'name': 'Pâtes 🍝', 'url': 'https://images.unsplash.com/photo-1621996346565-e3d5d6281729?auto=format&fit=crop&w=800&q=80'},
      {'name': 'Salade 🥗', 'url': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80'},
      {'name': 'Boisson 🥤', 'url': 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80'},
      {'name': 'Café ☕', 'url': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80'},
      {'name': 'Dessert 🍰', 'url': 'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=800&q=80'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ou choisir un exemple d\'image web en 1 clic :',
          style: TextStyle(fontSize: 10.5, color: Color(0xFF78909C), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(p['name']!, style: const TextStyle(fontSize: 11)),
                  onPressed: () => onSelect(p['url']!),
                  backgroundColor: const Color(0xFFF0F4F8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
