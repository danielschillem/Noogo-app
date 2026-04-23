import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../models/waiter_order.dart';
import '../services/waiter_provider.dart';

class WaiterOrderDetailScreen extends StatefulWidget {
  final WaiterOrder order;
  const WaiterOrderDetailScreen({super.key, required this.order});

  @override
  State<WaiterOrderDetailScreen> createState() =>
      _WaiterOrderDetailScreenState();
}

class _WaiterOrderDetailScreenState extends State<WaiterOrderDetailScreen> {
  late WaiterOrder _order;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _isLoading = true);
    final provider = context.read<WaiterProvider>();
    final ok = await provider.updateStatus(_order, newStatus);
    if (ok) {
      setState(() {
        _order = _order.copyWith(status: newStatus);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erreur mise à jour'),
            backgroundColor: AppColors.error,
          ),
        );
        provider.clearError();
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: Text('Confirmer l\'annulation de la commande #${_order.id} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Annuler la commande'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final provider = context.read<WaiterProvider>();
    final ok = await provider.cancelOrder(_order);
    if (ok && mounted) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Commande #${_order.id}'),
        actions: [
          if (!_order.isClosed)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Annuler',
              color: AppColors.error,
              onPressed: _isLoading ? null : _cancelOrder,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + info card
            _buildInfoCard(),
            const SizedBox(height: 16),

            // Items list
            _buildItemsCard(),
            const SizedBox(height: 16),

            // Notes
            if (_order.notes != null && _order.notes!.isNotEmpty) ...[
              _buildNotesCard(),
              const SizedBox(height: 16),
            ],

            // Timeline
            _buildTimeline(),
            const SizedBox(height: 24),

            // Action buttons
            if (!_order.isClosed) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _statusBorderColor(_order.status),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _order.tableDisplay,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(_order.status),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.category_outlined, _order.orderTypeLabel),
            if (_order.customerName != null)
              _infoRow(Icons.person_outline, _order.customerName!),
            if (_order.customerPhone != null)
              _infoRow(Icons.phone_outlined, _order.customerPhone!),
            _infoRow(
              Icons.access_time,
              _formatDateTime(_order.createdAt),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${_order.totalAmount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Articles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (_order.items.isEmpty)
              const Text('Détail non disponible',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ..._order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.nom,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(item.notes!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        Text(
                          '${item.subtotal.toStringAsFixed(0)} F',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notes_outlined,
                    size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('Notes',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_order.notes!,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      ('En attente', 'pending', Icons.hourglass_empty),
      ('Confirmée', 'confirmed', Icons.check_circle_outline),
      ('En préparation', 'preparing', Icons.restaurant),
      ('Prête', 'ready', Icons.done_all),
      ('Servie', 'delivered', Icons.room_service),
    ];

    final statusOrder = [
      'pending',
      'confirmed',
      'preparing',
      'ready',
      'delivered',
      'completed'
    ];
    final currentIdx = statusOrder.indexOf(_order.status);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progression',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...steps.map((step) {
              final (label, status, icon) = step;
              final stepIdx = statusOrder.indexOf(status);
              final isDone = currentIdx >= stepIdx;
              final isCurrent = _order.status == status;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : icon,
                      size: 20,
                      color: isDone
                          ? AppColors.success
                          : AppColors.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isDone
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withOpacity(0.5),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Actuel',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final next = _order.nextStatus;
    final nextLabel = _order.nextStatusLabel;

    return Column(
      children: [
        if (next != null)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _changeStatus(next),
              style: ElevatedButton.styleFrom(
                backgroundColor: next == 'delivered'
                    ? AppColors.success
                    : const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(_nextIcon(next)),
              label: Text(nextLabel ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

        // Secondary actions (confirmed → skip to kitchen or back)
        if (_order.status == 'confirmed') ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _changeStatus('preparing'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.restaurant, size: 18),
              label: const Text('Envoyer en cuisine',
                  style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }

  IconData _nextIcon(String next) {
    switch (next) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'delivered':
        return Icons.room_service;
      default:
        return Icons.arrow_forward;
    }
  }

  Widget _buildStatusChip(String status) {
    final (bg, fg, label) = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  (Color, Color, String) _statusConfig(String s) {
    switch (s) {
      case 'pending':
        return (
          AppColors.warning.withOpacity(0.15),
          AppColors.warning,
          'En attente'
        );
      case 'confirmed':
        return (
          const Color(0xFF1976D2).withOpacity(0.12),
          const Color(0xFF1976D2),
          'Confirmée'
        );
      case 'preparing':
        return (Colors.orange.withOpacity(0.12), Colors.orange, 'Cuisine');
      case 'ready':
        return (
          AppColors.success.withOpacity(0.12),
          AppColors.success,
          '✓ Prête'
        );
      case 'delivered':
        return (Colors.teal.withOpacity(0.12), Colors.teal, 'Servie');
      case 'completed':
        return (AppColors.dividerColor, AppColors.textSecondary, 'Terminée');
      case 'cancelled':
        return (AppColors.error.withOpacity(0.12), AppColors.error, 'Annulée');
      default:
        return (AppColors.dividerColor, AppColors.textSecondary, s);
    }
  }

  Color _statusBorderColor(String s) {
    switch (s) {
      case 'ready':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.dividerColor;
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
