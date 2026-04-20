import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order.dart';
import '../services/fcm_service.dart';
import '../services/rating_service.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/rating_dialog.dart';
import 'tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<OrdersScreen> {
  @override
  bool get wantKeepAlive => true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _pollingTimer;
  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;

  Set<int> _ratedOrderIds = {};

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Animation de pulsation pour l'indicateur
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ✅ Charger les commandes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RestaurantProvider>().forceRefreshOrders();
        _loadRatedOrders();
        _startPolling();
        _listenToFcmEvents();
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        context.read<RestaurantProvider>().forceRefreshOrders();
      }
    });
  }

  void _listenToFcmEvents() {
    _fcmSubscription = FCMService.orderEvents.listen((data) {
      if (!mounted) return;
      // Rafraîchissement immédiat quand une notif de commande arrive
      context.read<RestaurantProvider>().forceRefreshOrders();
    });
  }

  Future<void> _loadRatedOrders() async {
    final ids = await RatingService.loadRatedOrderIds();
    if (mounted) setState(() => _ratedOrderIds = ids);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _fcmSubscription?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildImage(String imageUrl,
      {double? width, double? height, BoxFit? fit}) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => const ColoredBox(
          color: AppColors.surface,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => const ColoredBox(
          color: AppColors.surface,
          child: Icon(
            Icons.restaurant_menu,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: AppColors.surface,
          child: Icon(
            Icons.restaurant_menu,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Vos commandes'),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.orders.isEmpty) {
            return _buildEmptyOrders();
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () =>
                  provider.forceRefreshOrders(), // ✅ Refresh manuel
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec indicateur de connexion
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('Mes Commandes',
                            style: AppTextStyles.heading1),
                        const Spacer(),

                        // Indicateur auto-refresh
                        _buildAutoRefreshIndicator(),

                        const SizedBox(width: 12),

                        // Compteur de commandes
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${provider.orders.length} commande${provider.orders.length > 1 ? 's' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.orders.length,
                      itemBuilder: (context, index) {
                        final order = provider.orders[index];
                        return _buildOrderCard(order, provider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoRefreshIndicator() {
    return Tooltip(
      message: 'Mises à jour automatiques toutes les 15s',
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune commande',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous n\'avez pas encore passé de commande',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<RestaurantProvider>();
              provider.setNavIndex(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Découvrir le menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, RestaurantProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order.id}',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(order.orderDate),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
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
                Text(
                  'Plats (${order.items.length})',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...order.items.map((item) => _buildOrderItem(item)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Paiement', style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              order.paymentMethod == 'Mobile Money'
                                  ? Icons.phone_android
                                  : Icons.money,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.paymentMethod,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (order.transactionId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${order.transactionId}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total', style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} FCFA',
                          style: AppTextStyles.price.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
                if (order.status == OrderStatus.pending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelOrder(order, provider),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _trackOrder(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textLight,
                          ),
                          child: const Text('Suivre'),
                        ),
                      ),
                    ],
                  ),
                ] else if (order.status == OrderStatus.confirmed ||
                    order.status == OrderStatus.preparing) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _trackOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                      ),
                      child: const Text('Suivre la commande'),
                    ),
                  ),
                  // DEL-T09 : mini-carte tracking pour livraisons en route
                  if (order.orderType == OrderType.livraison)
                    TrackingMiniCard(
                      order: order,
                      onTap: () => _trackOrder(order),
                    ),
                ] else if (order.status == OrderStatus.delivered ||
                    order.status == OrderStatus.completed) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reorderItems(order, provider),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          child: const Text('Recommander'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ratedOrderIds.contains(order.id)
                            ? Container(
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Noté',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _showRatingDialog(order),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.star_outline, size: 16),
                                label: const Text('Évaluer'),
                              ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 50,
              height: 50,
              child: _buildImage(
                item.dish.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dish.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.dish.formattedPrice} x ${item.quantity}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '${item.totalPrice.toStringAsFixed(0)} FCFA',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.preparing:
        return AppColors.secondary;
      case OrderStatus.ready:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.completed:
        return AppColors.success;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
      case OrderStatus.completed:
        return 'Terminée';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _cancelOrder(Order order, RestaurantProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content:
            Text('Voulez-vous vraiment annuler la commande #${order.id} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Commande annulée avec succès !'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _trackOrder(Order order) {
    // DEL-T09 : livraison en cours → ouvrir TrackingScreen
    if (order.orderType == OrderType.livraison) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(order: order),
        ),
      );
      return;
    }

    // Autres types : dialog simple
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Commande #${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statut: ${_getStatusText(order.status)}'),
            const SizedBox(height: 8),
            Text('Passée le: ${_formatDate(order.orderDate)}'),
            const SizedBox(height: 8),
            Text('Total: ${order.totalAmount.toStringAsFixed(0)} FCFA'),
            if (order.status == OrderStatus.preparing) ...[
              const SizedBox(height: 16),
              const Text(
                'Votre commande est en cours de préparation. Temps estimé: 25-30 minutes.',
              ),
            ] else if (order.status == OrderStatus.ready) ...[
              const SizedBox(height: 16),
              const Text('Votre commande est prête !'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        order: order,
        onRated: () {
          setState(() => _ratedOrderIds.add(order.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Merci pour votre évaluation !'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _reorderItems(Order order, RestaurantProvider provider) {
    for (final item in order.items) {
      provider.addToCart(item.dish, quantity: item.quantity);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plats ajoutés au panier'),
        backgroundColor: AppColors.success,
      ),
    );

    provider.setNavIndex(2);
  }
}
