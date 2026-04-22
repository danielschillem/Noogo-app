import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';
import '../models/delivery.dart';
import '../services/driver_provider.dart';
import '../services/driver_location_service.dart';

class DriverDeliveryScreen extends StatefulWidget {
  const DriverDeliveryScreen({super.key});

  @override
  State<DriverDeliveryScreen> createState() => _DriverDeliveryScreenState();
}

class _DriverDeliveryScreenState extends State<DriverDeliveryScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverPosition;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _loadDriverPosition();
  }

  Future<void> _loadDriverPosition() async {
    final pos = await DriverLocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _driverPosition = LatLng(pos.latitude, pos.longitude));
    }
  }

  Future<void> _advanceStatus(DriverProvider provider) async {
    final delivery = provider.currentDelivery;
    if (delivery == null || delivery.nextStatusLabel == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Passer à "${delivery.nextStatusLabel}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isAdvancing = true);
    final ok = await provider.advanceStatus();
    if (mounted) setState(() => _isAdvancing = false);

    if (ok && mounted) {
      if (provider.currentDelivery == null) {
        // Delivery completed — go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livraison terminée !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _markFailed(DriverProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler un échec'),
        content: const Text(
            'Êtes-vous sûr de vouloir signaler cette livraison comme échouée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmer l\'échec'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await provider.markFailed();
      if (ok && mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openNavigation(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, _) {
        final delivery = provider.currentDelivery;
        if (delivery == null) {
          return const Scaffold(
            body: Center(child: Text('Aucune livraison sélectionnée')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Livraison #${delivery.orderId}'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Map section
              SizedBox(
                height: 250,
                child: _buildMap(delivery),
              ),

              // Delivery info
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status progress
                      _StatusProgress(status: delivery.status),
                      const SizedBox(height: 20),

                      // Restaurant info
                      _InfoCard(
                        icon: Icons.restaurant,
                        iconColor: AppColors.secondary,
                        title: delivery.restaurantName ?? 'Restaurant',
                        subtitle: delivery.pickupAddress,
                        phone: delivery.restaurantPhone,
                        lat: delivery.pickupLat,
                        lng: delivery.pickupLng,
                        onCall: _callPhone,
                        onNavigate: _openNavigation,
                      ),
                      const SizedBox(height: 12),

                      // Client info
                      _InfoCard(
                        icon: Icons.person,
                        iconColor: AppColors.primary,
                        title: delivery.customerName ?? 'Client',
                        subtitle: delivery.deliveryAddress,
                        phone: delivery.customerPhone,
                        lat: delivery.deliveryLat,
                        lng: delivery.deliveryLng,
                        onCall: _callPhone,
                        onNavigate: _openNavigation,
                      ),
                      const SizedBox(height: 12),

                      // Order items
                      if (delivery.items.isNotEmpty) ...[
                        const Text(
                          'Articles',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...delivery.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x ${item.name}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '${(item.unitPrice * item.quantity).toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 20),
                      ],

                      // Total + fee
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (delivery.totalAmount != null)
                            Text(
                              'Total: ${delivery.totalAmount!.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (delivery.fee != null)
                            Text(
                              'Votre gain: ${delivery.fee!.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 80), // space for bottom buttons
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom action buttons
          bottomNavigationBar: delivery.nextStatus != null
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Fail button
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => _markFailed(provider),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.close),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Advance button
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isAdvancing
                                  ? null
                                  : () => _advanceStatus(provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isAdvancing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward,
                                      color: Colors.white),
                              label: Text(
                                delivery.nextStatusLabel ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildMap(Delivery delivery) {
    final markers = <Marker>[];
    LatLng center =
        _driverPosition ?? const LatLng(12.3714, -1.5197); // Ouagadougou

    // Driver marker
    if (_driverPosition != null) {
      markers.add(Marker(
        point: _driverPosition!,
        width: 40,
        height: 40,
        child: const Icon(Icons.delivery_dining,
            color: AppColors.primary, size: 36),
      ));
      center = _driverPosition!;
    }

    // Pickup marker
    if (delivery.pickupLatLng != null) {
      markers.add(Marker(
        point: delivery.pickupLatLng!,
        width: 36,
        height: 36,
        child: const Icon(Icons.store, color: AppColors.secondary, size: 32),
      ));
    }

    // Delivery marker
    if (delivery.deliveryLatLng != null) {
      markers.add(Marker(
        point: delivery.deliveryLatLng!,
        width: 36,
        height: 36,
        child: const Icon(Icons.location_on, color: AppColors.error, size: 32),
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.quickdevit.noogo.driver',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

class _StatusProgress extends StatelessWidget {
  final String status;
  const _StatusProgress({required this.status});

  static const _steps = ['assigned', 'picked_up', 'on_way', 'delivered'];
  static const _labels = ['Assignée', 'Récupérée', 'En route', 'Livrée'];
  static const _icons = [
    Icons.assignment,
    Icons.restaurant,
    Icons.local_shipping,
    Icons.check_circle,
  ];

  int get _currentIndex => _steps.indexOf(status).clamp(0, 3);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final isActive = i <= _currentIndex;
        final isCurrent = i == _currentIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.dividerColor,
                      ),
                    ),
                  CircleAvatar(
                    radius: isCurrent ? 18 : 14,
                    backgroundColor:
                        isActive ? AppColors.primary : AppColors.dividerColor,
                    child: Icon(
                      _icons[i],
                      size: isCurrent ? 20 : 16,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < _currentIndex
                            ? AppColors.primary
                            : AppColors.dividerColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? phone;
  final double? lat;
  final double? lng;
  final Function(String) onCall;
  final Function(double, double) onNavigate;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.phone,
    this.lat,
    this.lng,
    required this.onCall,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (phone != null)
              IconButton(
                onPressed: () => onCall(phone!),
                icon: const Icon(Icons.phone, color: AppColors.primary),
                tooltip: 'Appeler',
              ),
            if (lat != null && lng != null)
              IconButton(
                onPressed: () => onNavigate(lat!, lng!),
                icon: const Icon(Icons.navigation, color: AppColors.secondary),
                tooltip: 'Naviguer',
              ),
          ],
        ),
      ),
    );
  }
}
