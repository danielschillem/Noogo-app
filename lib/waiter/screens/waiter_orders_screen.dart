import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../models/waiter_order.dart';
import '../services/waiter_provider.dart';
import 'waiter_order_detail_screen.dart';

class WaiterOrdersScreen extends StatefulWidget {
  const WaiterOrdersScreen({super.key});

  @override
  State<WaiterOrdersScreen> createState() => _WaiterOrdersScreenState();
}

class _WaiterOrdersScreenState extends State<WaiterOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    ('Toutes', null),
    ('En attente', 'pending'),
    ('Cuisine', 'preparing'),
    ('Prêtes', 'ready'),
    ('Fermées', 'closed'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<WaiterOrder> _filtered(List<WaiterOrder> orders, String? status) {
    if (status == null) return orders;
    if (status == 'closed') return orders.where((o) => o.isClosed).toList();
    if (status == 'preparing') {
      return orders
          .where((o) => o.status == 'preparing' || o.status == 'confirmed')
          .toList();
    }
    return orders.where((o) => o.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaiterProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Commandes',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (provider.restaurantName != null)
                  Text(
                    provider.restaurantName!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed:
                    provider.isLoading ? null : () => provider.loadOrders(),
                tooltip: 'Actualiser',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF1976D2),
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: const Color(0xFF1976D2),
              tabs: _tabs.map((t) {
                final (label, status) = t;
                final count = _filtered(provider.orders, status).length;
                return Tab(
                  child: Row(
                    children: [
                      Text(label),
                      if (count > 0 &&
                          status != null &&
                          status != 'closed') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'ready'
                                ? AppColors.success
                                : status == 'pending'
                                    ? AppColors.warning
                                    : const Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          body: provider.isLoading && provider.orders.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((t) {
                    final (_, status) = t;
                    final list = _filtered(provider.orders, status);
                    if (list.isEmpty) {
                      return _EmptyState(status: status);
                    }
                    return RefreshIndicator(
                      onRefresh: provider.loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _OrderCard(order: list[i]),
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final WaiterOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WaiterProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _borderColor(order.status),
          width: order.status == 'ready' ? 2 : 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => WaiterOrderDetailScreen(order: order)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _StatusBadge(status: order.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '#${order.id} · ${order.tableDisplay}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Text(
                    _formatTime(order.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              if (order.customerName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(order.customerName!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],

              // Items summary
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  order.items.map((i) => '${i.quantity}× ${i.nom}').join(', '),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),
              // Bottom row
              Row(
                children: [
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary),
                  ),
                  const Spacer(),
                  if (order.nextStatus != null)
                    _QuickActionButton(order: order, provider: provider),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _borderColor(String status) {
    switch (status) {
      case 'ready':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.dividerColor;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────

class _QuickActionButton extends StatefulWidget {
  final WaiterOrder order;
  final WaiterProvider provider;
  const _QuickActionButton({required this.order, required this.provider});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _loading = false;

  Future<void> _action() async {
    final next = widget.order.nextStatus;
    if (next == null) return;
    setState(() => _loading = true);
    await widget.provider.updateStatus(widget.order, next);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.order.nextStatusLabel ?? '';
    final isReady = widget.order.status == 'ready';
    final color = isReady ? AppColors.success : const Color(0xFF1976D2);

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: _loading ? null : _action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  (Color, String) _config(String s) {
    switch (s) {
      case 'pending':
        return (AppColors.warning, 'En attente');
      case 'confirmed':
        return (const Color(0xFF1976D2), 'Confirmée');
      case 'preparing':
        return (Colors.orange, 'Cuisine');
      case 'ready':
        return (AppColors.success, '✓ Prête');
      case 'delivered':
        return (Colors.teal, 'Servie');
      case 'completed':
        return (AppColors.textSecondary, 'Terminée');
      case 'cancelled':
        return (AppColors.error, 'Annulée');
      default:
        return (AppColors.textSecondary, s);
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? status;
  const _EmptyState({this.status});

  @override
  Widget build(BuildContext context) {
    final msg = status == 'ready'
        ? 'Aucune commande prête'
        : status == 'pending'
            ? 'Aucune commande en attente'
            : 'Aucune commande';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
