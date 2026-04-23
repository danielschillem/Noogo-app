import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../services/waiter_provider.dart';
import '../services/waiter_notification_service.dart';
import 'waiter_orders_screen.dart';
import 'waiter_new_order_screen.dart';
import 'waiter_profile_screen.dart';

class WaiterHomeScreen extends StatefulWidget {
  const WaiterHomeScreen({super.key});

  @override
  State<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends State<WaiterHomeScreen> {
  int _currentIndex = 0;
  StreamSubscription? _orderSub;
  bool _notifInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final provider = context.read<WaiterProvider>();
    await provider.init();

    if (!mounted) return;

    // Init Pusher notification once restaurantId is known
    if (!_notifInitialized && provider.restaurantId != null) {
      final token = await AuthService.getToken();
      if (token != null) {
        await WaiterNotificationService.instance.init(
          restaurantId: provider.restaurantId!,
          authToken: token,
        );
        _notifInitialized = true;
      }
    }

    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    _orderSub =
        WaiterNotificationService.instance.orderEventStream.listen((event) {
      if (!mounted) return;

      // Rafraîchir la liste
      context.read<WaiterProvider>().loadOrders();

      // Alerte visuelle
      if (event.isNewOrder) {
        _showOrderAlert(
          icon: Icons.notifications_active,
          iconColor: AppColors.primary,
          title: 'Nouvelle commande #${event.orderId}',
          subtitle: event.tableNumber != null
              ? 'Table ${event.tableNumber}'
              : 'À confirmer',
        );
      } else if (event.isReady) {
        _showOrderAlert(
          icon: Icons.check_circle,
          iconColor: AppColors.success,
          title: 'Commande #${event.orderId} prête !',
          subtitle: event.tableNumber != null
              ? 'Table ${event.tableNumber} — à servir'
              : 'À servir maintenant',
        );
      }
    });
  }

  void _showOrderAlert({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(subtitle,
            style:
                const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.list_alt),
            label: const Text('Voir commandes'),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _currentIndex = 0);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaiterProvider>(
      builder: (context, provider, _) {
        final readyCount = provider.readyCount;
        final pendingCount = provider.pendingCount;
        final alertCount = readyCount + pendingCount;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              WaiterOrdersScreen(),
              WaiterNewOrderScreen(),
              WaiterProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: const Color(0xFF1976D2),
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: AppColors.cardBackground,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            items: [
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: alertCount > 0,
                  label: Text('$alertCount'),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: alertCount > 0,
                  label: Text('$alertCount'),
                  child: const Icon(Icons.receipt_long),
                ),
                label: 'Commandes',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Nouvelle',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}
