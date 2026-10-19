import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/menu_item_model.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import 'pdf_preview_page.dart';

class ResponsableDashboardPage extends StatefulWidget {
  const ResponsableDashboardPage({super.key});

  @override
  State<ResponsableDashboardPage> createState() => _ResponsableDashboardPageState();
}

class _ResponsableDashboardPageState extends State<ResponsableDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _foodSearchController = TextEditingController();
  String _selectedStatusFilter = 'Tous'; // 'Tous', 'Envoyée au responsable', 'En préparation', 'Prête', 'Livrée / Servie'
  String _menuSubTab = 'items'; // 'items' or 'categories'
  String _foodCategoryFilter = 'all';

  final List<String> _statusOptions = [
    'Envoyée au responsable',
    'En préparation',
    'Prête',
    'Livrée / Servie',
    'Annulée',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _foodSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);
    final orderService = OrderService();
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Espace Responsable',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                Text(
                  authService.currentUser?.name ?? 'Gestionnaire du restaurant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Live pulse badge indicating real-time connection
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'En direct',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout, color: Color(0xFF37474F)),
            onPressed: () {
              authService.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: const Color(0xFF78909C),
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            ListenableBuilder(
              listenable: orderService,
              builder: (context, _) {
                final pending = orderService.pendingOrdersCount;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 20),
                      const SizedBox(width: 8),
                      const Text('Commandes'),
                      if (pending > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 20),
                  SizedBox(width: 8),
                  Text('Gestion Menu'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights, size: 20),
                  SizedBox(width: 8),
                  Text('Statistiques'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(context, orderService, primaryColor),
          _buildMenuManagementTab(context, primaryColor),
          _buildStatsTab(context, orderService, primaryColor),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: COMMANDES EN TEMPS RÉEL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOrdersTab(
      BuildContext context, OrderService orderService, Color primaryColor) {
    return ListenableBuilder(
      listenable: orderService,
      builder: (context, _) {
        final allOrders = orderService.orders;

        // Apply filters
        final filteredOrders = allOrders.where((order) {
          final matchesStatus = _selectedStatusFilter == 'Tous' ||
              order.status == _selectedStatusFilter;
          final query = _searchController.text.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              order.id.toLowerCase().contains(query) ||
              order.customerName.toLowerCase().contains(query) ||
              order.customerPhone.toLowerCase().contains(query);
          return matchesStatus && matchesSearch;
        }).toList();

        return Column(
          children: [
            // Search and Status Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par N° commande, client...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, size: 20),
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
                      fillColor: const Color(0xFFF4F6F8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tous', allOrders.length, primaryColor),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Envoyée au responsable',
                          orderService.pendingOrdersCount,
                          Colors.orange.shade800,
                          labelOverride: 'Nouvelles (${orderService.pendingOrdersCount})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'En préparation',
                          orderService.preparingOrdersCount,
                          Colors.blue.shade700,
                          labelOverride: 'En cuisine (${orderService.preparingOrdersCount})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Prête',
                          orderService.readyOrdersCount,
                          Colors.teal.shade700,
                          labelOverride: 'Prêtes (${orderService.readyOrdersCount})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Livrée / Servie',
                          orderService.completedOrdersCount,
                          Colors.green.shade700,
                          labelOverride: 'Terminées (${orderService.completedOrdersCount})',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          Text(
                            'Aucune commande trouvée',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Les nouvelles commandes des clients s\'afficheront ici en direct.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildManagerOrderCard(context, order, orderService, primaryColor);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(
    String filterValue,
    int count,
    Color activeColor, {
    String? labelOverride,
  }) {
    final isSelected = _selectedStatusFilter == filterValue;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = filterValue;
        });
      },
      label: Text(labelOverride ?? '$filterValue ($count)'),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF37474F),
      ),
      selectedColor: activeColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? activeColor : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildManagerOrderCard(
    BuildContext context,
    OrderModel order,
    OrderService orderService,
    Color primaryColor,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(order.createdAt);
    final statusColor = _getStatusColor(order.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getOrderTypeIcon(order.orderType),
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF263238),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${order.totalTtc.toStringAsFixed(2)} €',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Information
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF78909C)),
                    const SizedBox(width: 6),
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.phone, size: 16, color: Color(0xFF78909C)),
                    const SizedBox(width: 6),
                    Text(
                      order.customerPhone,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Order details: Type & Location
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Type: ${order.orderType}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (order.tableNumber != null && order.tableNumber!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Text(
                          '• ${order.tableNumber}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                        ),
                      ],
                      if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '• ${order.deliveryAddress}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Special Notes (Instructions)
                if (order.specialNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_alt_outlined, size: 16, color: Colors.amber.shade900),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Note client : ${order.specialNotes}',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Items list
                const Text(
                  'Articles commandés :',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF78909C),
                  ),
                ),
                const SizedBox(height: 6),
                ...order.items.map((cartItem) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${cartItem.quantity}x',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
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
                                  '+ Suppléments: ${cartItem.supplements.map((s) => s.name).join(', ')}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${cartItem.totalPrice.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF37474F),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Action Row: Change status dropdown + View PDF button
                Row(
                  children: [
                    // Status selector
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusOptions.contains(order.status)
                                ? order.status
                                : _statusOptions.first,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                            items: _statusOptions.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                orderService.updateOrderStatus(order.id, newStatus);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Commande ${order.id} : $newStatus'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: _getStatusColor(newStatus),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Access PDF Button (Page 3 PDF requirement)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Facture PDF', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PdfPreviewPage(order: order),
                            ),
                          );
                        },
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

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: STATISTIQUES DE VENTES & SUIVI (Page 3 du sujet)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatsTab(
      BuildContext context, OrderService orderService, Color primaryColor) {
    return ListenableBuilder(
      listenable: orderService,
      builder: (context, _) {
        final totalRevenue = orderService.totalRevenue;
        final totalOrders = orderService.totalOrdersCount;
        final avgOrder = orderService.averageOrderValue;
        final pending = orderService.pendingOrdersCount;
        final preparing = orderService.preparingOrdersCount;
        final completed = orderService.completedOrdersCount;

        // Calculate breakdown by order type
        final dineInCount = orderService.orders.where((o) => o.orderType == 'Sur place').length;
        final takeawayCount = orderService.orders.where((o) => o.orderType == 'À emporter').length;
        final deliveryCount = orderService.orders.where((o) => o.orderType == 'Livraison').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Indicateurs Clés de Vente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Suivi en temps réel des performances du restaurant',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // KPI Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Chiffre d\'Affaires',
                      value: '${totalRevenue.toStringAsFixed(2)} €',
                      subtitle: 'Total TTC encaissé',
                      icon: Icons.euro,
                      accentColor: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Total Commandes',
                      value: '$totalOrders',
                      subtitle: '$completed terminées',
                      icon: Icons.shopping_cart,
                      accentColor: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Panier Moyen',
                      value: '${avgOrder.toStringAsFixed(2)} €',
                      subtitle: 'Par client',
                      icon: Icons.trending_up,
                      accentColor: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'En Cours',
                      value: '${pending + preparing}',
                      subtitle: '$pending à valider • $preparing en cuisine',
                      icon: Icons.hourglass_top_rounded,
                      accentColor: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Répartition par Mode de Consommation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 12),

              // Order Types Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDistributionRow('Sur place (en salle)', dineInCount, totalOrders, Icons.restaurant, Colors.orange),
                    const Divider(height: 20),
                    _buildDistributionRow('À emporter (comptoir)', takeawayCount, totalOrders, Icons.takeout_dining, Colors.blue),
                    const Divider(height: 20),
                    _buildDistributionRow('Livraison à domicile', deliveryCount, totalOrders, Icons.delivery_dining, Colors.green),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Statut des Commandes en Direct',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 12),

              // Status Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatusCountRow('Nouvelles commandes reçues', pending, Colors.orange.shade800),
                    const Divider(height: 16),
                    _buildStatusCountRow('En préparation en cuisine', preparing, Colors.blue.shade700),
                    const Divider(height: 16),
                    _buildStatusCountRow('Commandes prêtes à servir', orderService.readyOrdersCount, Colors.teal.shade700),
                    const Divider(height: 16),
                    _buildStatusCountRow('Commandes finalisées', completed, Colors.green.shade700),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionRow(
      String title, int count, int total, IconData icon, Color color) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    final progress = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '$count ($percentage%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCountRow(String title, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Color(0xFF37474F)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Envoyée au responsable':
        return Colors.orange.shade800;
      case 'En préparation':
        return Colors.blue.shade700;
      case 'Prête':
        return Colors.teal.shade700;
      case 'Livrée / Servie':
        return Colors.green.shade700;
      case 'Annulée':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getOrderTypeIcon(String orderType) {
    switch (orderType) {
      case 'Sur place':
        return Icons.restaurant;
      case 'À emporter':
        return Icons.takeout_dining;
      case 'Livraison':
        return Icons.delivery_dining;
      default:
        return Icons.receipt;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: GESTION DU MENU & CATÉGORIES (CRUD Responsable)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMenuManagementTab(BuildContext context, Color primaryColor) {
    final menuService = MenuService();

    return ListenableBuilder(
      listenable: menuService,
      builder: (context, _) {
        final categories = menuService.categories;
        final allItems = menuService.items;

        return Column(
          children: [
            // Sub-navigation bar: Plats vs Catégories
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _menuSubTab = 'items'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _menuSubTab == 'items' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _menuSubTab == 'items'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '🍽️ Plats (${allItems.length})',
                                    style: TextStyle(
                                      fontWeight: _menuSubTab == 'items' ? FontWeight.bold : FontWeight.w500,
                                      color: _menuSubTab == 'items' ? primaryColor : Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _menuSubTab = 'categories'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _menuSubTab == 'categories' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _menuSubTab == 'categories'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '📁 Catégories (${categories.length})',
                                    style: TextStyle(
                                      fontWeight: _menuSubTab == 'categories' ? FontWeight.bold : FontWeight.w500,
                                      color: _menuSubTab == 'categories' ? primaryColor : Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Action button to Add (Dish or Category)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      _menuSubTab == 'items' ? 'Nouveau Plat' : 'Nouvelle Catégorie',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      if (_menuSubTab == 'items') {
                        _showFoodItemForm(context, menuService: menuService, primaryColor: primaryColor);
                      } else {
                        _showCategoryForm(context, menuService: menuService, primaryColor: primaryColor);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Content according to subtab
            Expanded(
              child: _menuSubTab == 'items'
                  ? _buildFoodItemsList(context, menuService, primaryColor)
                  : _buildCategoriesList(context, menuService, primaryColor),
            ),
          ],
        );
      },
    );
  }

  // ── Plats & Produits List ──────────────────────────────────────────────────
  Widget _buildFoodItemsList(
      BuildContext context, MenuService menuService, Color primaryColor) {
    final categories = menuService.categories;
    final allItems = menuService.items;

    // Filter items
    final query = _foodSearchController.text.trim().toLowerCase();
    final filteredItems = allItems.where((item) {
      final matchesCategory =
          _foodCategoryFilter == 'all' || item.category.id == _foodCategoryFilter;
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Column(
      children: [
        // Filter bar (Search + Categories chips)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _foodSearchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un plat par son nom ou description...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _foodSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _foodSearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF4F6F8),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      selected: _foodCategoryFilter == 'all',
                      label: Text('✨ Tous (${allItems.length})'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _foodCategoryFilter == 'all' ? FontWeight.bold : FontWeight.normal,
                        color: _foodCategoryFilter == 'all' ? Colors.white : const Color(0xFF37474F),
                      ),
                      selectedColor: primaryColor,
                      backgroundColor: Colors.white,
                      onSelected: (_) => setState(() => _foodCategoryFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) {
                      final isSelected = _foodCategoryFilter == cat.id;
                      final count = menuService.getItemsByCategory(cat).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text('${cat.emoji} ${cat.label} ($count)'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF37474F),
                          ),
                          selectedColor: primaryColor,
                          backgroundColor: Colors.white,
                          onSelected: (_) => setState(() => _foodCategoryFilter = cat.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items list view
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun plat trouvé',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Appuyez sur "Nouveau Plat" pour en ajouter un.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildFoodItemCard(context, item, menuService, primaryColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFoodItemCard(
    BuildContext context,
    MenuItemModel item,
    MenuService menuService,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: primaryColor.withValues(alpha: 0.1),
                  child: Center(
                    child: Text(item.category.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.category.emoji} ${item.category.label}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      if (item.isVegetarian) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🌱 Végé',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${item.price.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '⏱️ ${item.prepTime}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🔥 ${item.calories} kcal',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions: Edit & Delete
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1976D2)),
                  tooltip: 'Modifier ce plat',
                  onPressed: () {
                    _showFoodItemForm(
                      context,
                      menuService: menuService,
                      primaryColor: primaryColor,
                      item: item,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: 'Supprimer ce plat',
                  onPressed: () {
                    _confirmDelete(
                      context,
                      title: 'Supprimer ce plat ?',
                      message: 'Voulez-vous vraiment supprimer "${item.name}" du menu ?',
                      onConfirm: () {
                        menuService.deleteItem(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Plat "${item.name}" supprimé'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Catégories List ────────────────────────────────────────────────────────
  Widget _buildCategoriesList(
      BuildContext context, MenuService menuService, Color primaryColor) {
    final categories = menuService.categories;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final itemCount = menuService.getItemsByCategory(cat).length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Preview
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Image.network(
                      cat.bannerImageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: primaryColor.withValues(alpha: 0.2),
                        child: Center(
                          child: Text(cat.emoji, style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                    ),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 10,
                      child: Row(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 8),
                          Text(
                            cat.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.subtitle,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$itemCount plats associés',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF1976D2)),
                      tooltip: 'Modifier la catégorie',
                      onPressed: () {
                        _showCategoryForm(
                          context,
                          menuService: menuService,
                          primaryColor: primaryColor,
                          category: cat,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Supprimer la catégorie',
                      onPressed: () {
                        _confirmDelete(
                          context,
                          title: 'Supprimer la catégorie ?',
                          message:
                              'Attention : la suppression de "${cat.label}" supprimera également ses $itemCount plats associés.',
                          onConfirm: () {
                            menuService.deleteCategory(cat.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Catégorie "${cat.label}" supprimée'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── MODAL: Ajouter / Modifier un Plat ───────────────────────────────────────
  void _showFoodItemForm(
    BuildContext context, {
    required MenuService menuService,
    required Color primaryColor,
    MenuItemModel? item,
  }) {
    final isEditing = item != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController =
        TextEditingController(text: item != null ? item.price.toStringAsFixed(2) : '');
    final descController = TextEditingController(text: item?.description ?? '');
    final imageController = TextEditingController(text: item?.imageUrl ?? '');
    final prepTimeController = TextEditingController(text: item?.prepTime ?? '15 min');
    final caloriesController =
        TextEditingController(text: item != null ? item.calories.toString() : '450');
    final ingredientsController =
        TextEditingController(text: item != null ? item.ingredients.join(', ') : '');

    CategoryInfo selectedCat = item != null
        ? menuService.getCategoryById(item.category.id) ?? menuService.categories.first
        : menuService.categories.first;

    bool isVegetarian = item?.isVegetarian ?? false;
    bool isPopular = item?.isPopular ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Modifier le Plat' : 'Ajouter un Nouveau Plat',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nom du plat
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom du plat *',
                          hintText: 'ex: Burger Gourmet Truffe',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Veuillez saisir le nom' : null,
                      ),
                      const SizedBox(height: 12),

                      // Catégorie + Prix
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<CategoryInfo>(
                              initialValue: selectedCat,
                              decoration: InputDecoration(
                                labelText: 'Catégorie *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: menuService.categories.map((c) {
                                return DropdownMenuItem<CategoryInfo>(
                                  value: c,
                                  child: Text('${c.emoji} ${c.label}', style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedCat = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Prix (€) *',
                                hintText: '11.50',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Prix requis';
                                final p = double.tryParse(v.replaceAll(',', '.'));
                                if (p == null || p <= 0) return 'Invalide';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Ingrédients nobles, assaisonnement...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Description requise' : null,
                      ),
                      const SizedBox(height: 12),

                      // URL de l'image
                      TextFormField(
                        controller: imageController,
                        decoration: InputDecoration(
                          labelText: 'URL de l\'image (optionnel)',
                          hintText: 'https://images.unsplash.com/...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Temps de prépa + Calories
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: prepTimeController,
                              decoration: InputDecoration(
                                labelText: 'Temps de préparation',
                                hintText: '15 min',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: caloriesController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Calories (kcal)',
                                hintText: '450',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Ingrédients (séparés par virgules)
                      TextFormField(
                        controller: ingredientsController,
                        decoration: InputDecoration(
                          labelText: 'Ingrédients (séparés par des virgules)',
                          hintText: 'Steak de boeuf, Cheddar, Oignons caramélisés',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Checkboxes: Végétarien & Populaire
                      Row(
                        children: [
                          Checkbox(
                            value: isVegetarian,
                            activeColor: Colors.green,
                            onChanged: (val) => setModalState(() => isVegetarian = val ?? false),
                          ),
                          const Text('Plat Végétarien 🌱', style: TextStyle(fontSize: 13)),
                          const Spacer(),
                          Checkbox(
                            value: isPopular,
                            activeColor: primaryColor,
                            onChanged: (val) => setModalState(() => isPopular = val ?? false),
                          ),
                          const Text('Populaire ⭐', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Save Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;

                          final cleanPrice = double.parse(priceController.text.replaceAll(',', '.'));
                          final cleanCal = int.tryParse(caloriesController.text.trim()) ?? 400;
                          final ingredientsList = ingredientsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          if (isEditing) {
                            final updated = item.copyWith(
                              name: nameController.text.trim(),
                              description: descController.text.trim(),
                              price: cleanPrice,
                              category: selectedCat,
                              imageUrl: imageController.text.trim().isNotEmpty
                                  ? imageController.text.trim()
                                  : item.imageUrl,
                              prepTime: prepTimeController.text.trim(),
                              calories: cleanCal,
                              ingredients: ingredientsList,
                              isVegetarian: isVegetarian,
                              isPopular: isPopular,
                            );
                            menuService.updateItem(updated);
                          } else {
                            menuService.addItem(
                              name: nameController.text.trim(),
                              description: descController.text.trim(),
                              price: cleanPrice,
                              category: selectedCat,
                              imageUrl: imageController.text.trim(),
                              prepTime: prepTimeController.text.trim(),
                              calories: cleanCal,
                              ingredients: ingredientsList,
                              isVegetarian: isVegetarian,
                              isPopular: isPopular,
                            );
                          }

                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  isEditing ? 'Plat mis à jour !' : 'Nouveau plat ajouté au menu !'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          isEditing ? 'Enregistrer les modifications' : 'Ajouter le plat au menu',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── MODAL: Ajouter / Modifier une Catégorie ─────────────────────────────────
  void _showCategoryForm(
    BuildContext context, {
    required MenuService menuService,
    required Color primaryColor,
    CategoryModel? category,
  }) {
    final isEditing = category != null;
    final formKey = GlobalKey<FormState>();

    final labelController = TextEditingController(text: category?.label ?? '');
    final emojiController = TextEditingController(text: category?.emoji ?? '🍕');
    final subtitleController = TextEditingController(text: category?.subtitle ?? '');
    final bannerController = TextEditingController(text: category?.bannerImageUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEditing ? 'Modifier la Catégorie' : 'Nouvelle Catégorie',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Emoji
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          controller: emojiController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22),
                          decoration: InputDecoration(
                            labelText: 'Emoji *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Nom
                      Expanded(
                        child: TextFormField(
                          controller: labelController,
                          decoration: InputDecoration(
                            labelText: 'Nom de catégorie *',
                            hintText: 'ex: Pizzas',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sous-titre
                  TextFormField(
                    controller: subtitleController,
                    decoration: InputDecoration(
                      labelText: 'Sous-titre / Description *',
                      hintText: 'ex: Pizzas artisanales au feu de bois',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Sous-titre requis' : null,
                  ),
                  const SizedBox(height: 12),
                  // Banner URL
                  TextFormField(
                    controller: bannerController,
                    decoration: InputDecoration(
                      labelText: 'URL Image de bannière (optionnel)',
                      hintText: 'https://images.unsplash.com/...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                if (isEditing) {
                  menuService.updateCategory(
                    id: category.id,
                    label: labelController.text.trim(),
                    emoji: emojiController.text.trim(),
                    subtitle: subtitleController.text.trim(),
                    bannerImageUrl: bannerController.text.trim(),
                  );
                } else {
                  menuService.addCategory(
                    label: labelController.text.trim(),
                    emoji: emojiController.text.trim(),
                    subtitle: subtitleController.text.trim(),
                    bannerImageUrl: bannerController.text.trim(),
                  );
                }

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        isEditing ? 'Catégorie modifiée !' : 'Nouvelle catégorie créée avec succès !'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(isEditing ? 'Enregistrer' : 'Créer'),
            ),
          ],
        );
      },
    );
  }

  // ── Confirmation de suppression ───────────────────────────────────────────
  void _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(message, style: const TextStyle(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirm();
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}
