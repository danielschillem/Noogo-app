import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../models/delivery.dart';
import '../services/driver_provider.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        centerTitle: true,
      ),
      body: Consumer<DriverProvider>(
        builder: (context, provider, _) {
          if (provider.history.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadHistory(),
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Icon(Icons.history,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune livraison effectuée',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // Stats summary
          final completed = provider.history.where((d) => d.isCompleted).length;
          final failed = provider.history.where((d) => d.isFailed).length;
          final totalEarnings = provider.history
              .where((d) => d.isCompleted && d.fee != null)
              .fold<double>(0, (sum, d) => sum + d.fee!);

          return RefreshIndicator(
            onRefresh: () => provider.loadHistory(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats row
                Row(
                  children: [
                    _StatCard(
                      label: 'Livrées',
                      value: completed.toString(),
                      icon: Icons.check_circle,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Échouées',
                      value: '$failed',
                      icon: Icons.cancel,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Gains',
                      value: totalEarnings.toStringAsFixed(0),
                      icon: Icons.monetization_on,
                      color: AppColors.primary,
                      suffix: 'FCFA',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // History list
                ...provider.history.map(
                  (delivery) => _HistoryItem(delivery: delivery),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (suffix != null)
                Text(suffix!, style: TextStyle(fontSize: 10, color: color)),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Delivery delivery;
  const _HistoryItem({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final isSuccess = delivery.isCompleted;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isSuccess ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.1),
          child: Icon(
            isSuccess ? Icons.check : Icons.close,
            color: isSuccess ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(
          'Commande #${delivery.orderId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          delivery.restaurantName ?? delivery.deliveryAddress ?? '',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (delivery.fee != null)
              Text(
                '${delivery.fee!.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isSuccess ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            Text(
              _formatDate(delivery.deliveredAt ?? delivery.createdAt),
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
