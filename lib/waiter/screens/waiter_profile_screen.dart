import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../services/waiter_provider.dart';
import '../services/waiter_notification_service.dart';

class WaiterProfileScreen extends StatelessWidget {
  const WaiterProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await WaiterNotificationService.instance.dispose();
    await AuthService.logout();
    context.read<WaiterProvider>().stopPolling();

    if (context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/waiter-login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaiterProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Profil'),
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _loadUserInfo(),
            builder: (context, snap) {
              final name = snap.data?['name'] ?? '—';
              final email = snap.data?['email'] ?? '—';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 24),

                    // Role + Restaurant card
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _infoTile(
                              icon: Icons.restaurant,
                              label: 'Restaurant',
                              value: provider.restaurantName ?? '—',
                            ),
                            const Divider(height: 20),
                            _infoTile(
                              icon: Icons.badge_outlined,
                              label: 'Rôle',
                              value: _roleLabel(provider.staffRole),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats card
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Commandes actives',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    label: 'En attente',
                                    value: '${provider.pendingCount}',
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _statCard(
                                    label: 'Prêtes',
                                    value: '${provider.readyCount}',
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _statCard(
                                    label: 'Actives',
                                    value: '${provider.activeOrders.length}',
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _logout(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Se déconnecter',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Noogo Serveur · v1.0',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoTile(
      {required IconData icon,
      required String label,
      required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      {required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'waiter':
        return 'Serveur';
      case 'cashier':
        return 'Caissier';
      case 'manager':
        return 'Gérant';
      case 'owner':
        return 'Propriétaire';
      default:
        return role ?? 'Staff';
    }
  }

  Future<Map<String, dynamic>> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? '',
      'email': prefs.getString('user_email') ?? '',
    };
  }
}
