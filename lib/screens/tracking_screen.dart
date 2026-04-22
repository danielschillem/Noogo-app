import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import '../services/delivery_tracking_service.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';

/// Étapes de la progression de livraison (DEL-T06)
const List<_TrackingStep> _kSteps = [
  _TrackingStep('confirmed', 'Confirmée', Icons.check_circle_outline),
  _TrackingStep('preparing', 'En préparation', Icons.restaurant),
  _TrackingStep('picked_up', 'Récupérée', Icons.directions_bike),
  _TrackingStep('on_way', 'En route', Icons.delivery_dining),
  _TrackingStep('delivered', 'Livrée', Icons.home),
];

class _TrackingStep {
  final String status;
  final String label;
  final IconData icon;
  const _TrackingStep(this.status, this.label, this.icon);
}

/// Écran de tracking de livraison en temps réel (DEL-T01→T09)
///
/// Navigation : `Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(order: order)))`
class TrackingScreen extends StatefulWidget {
  final Order order;

  const TrackingScreen({super.key, required this.order});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();

  // Positions
  LatLng? _driverPosition;
  LatLng? _clientPosition;
  String _deliveryStatus;

  // Sharing
  bool _sharingLocation = false;
  Timer? _locationShareTimer;

  // Animation du marker livreur
  late AnimationController _markerAnimCtrl;
  late Animation<double> _markerAnim;

  // ETA
  int? _etaMinutes;

  // Subscriptions
  StreamSubscription<DriverLocation>? _locationSub;
  StreamSubscription<DeliveryStatusEvent>? _statusSub;
  Timer? _statusPollTimer;

  // Map controller
  final MapController _mapController = MapController();

  _TrackingScreenState()
      : _deliveryStatus =
            OrderStatus.values.last.toString().split('.').last; // fallback

  @override
  void initState() {
    super.initState();
    _deliveryStatus = widget.order.status.toString().split('.').last;

    // Animation pulse du marker livreur
    _markerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _markerAnim =
        Tween<double>(begin: 0.85, end: 1.15).animate(_markerAnimCtrl);

    _initTracking();
    _initClientPosition();
    _startStatusPolling();
  }

  /// Polling fallback: recharge l'état commande toutes les 15s
  void _startStatusPolling() {
    _statusPollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      final provider = Provider.of<RestaurantProvider>(context, listen: false);
      await provider.loadOrders();
      final updated =
          provider.orders.where((o) => o.id == widget.order.id).firstOrNull;
      if (updated != null && mounted) {
        final newStatus = updated.status.toString().split('.').last;
        if (newStatus != _deliveryStatus) {
          setState(() => _deliveryStatus = newStatus);
        }
      }
    });
  }

  Future<void> _initTracking() async {
    final orderId = widget.order.id;
    await _trackingService.startTracking(orderId);

    _locationSub = _trackingService.driverLocationStream.listen((loc) {
      if (!mounted) return;
      setState(() {
        _driverPosition = loc.toLatLng();
        _updateEta();
      });
      // Centrer la carte sur le livreur si pas de position client
      if (_clientPosition == null) {
        _mapController.move(_driverPosition!, 15.0);
      }
    });

    _statusSub = _trackingService.deliveryStatusStream.listen((event) {
      if (!mounted) return;
      setState(() => _deliveryStatus = event.status);
    });
  }

  Future<void> _initClientPosition() async {
    final granted = await DeliveryTrackingService.requestLocationPermission();
    if (!granted || !mounted) return;
    final pos = await DeliveryTrackingService.getCurrentPosition();
    if (pos == null || !mounted) return;
    setState(() {
      _clientPosition = pos;
      _updateEta();
    });
    // Centrer carte sur client si pas encore de livreur
    if (_driverPosition == null) {
      _mapController.move(pos, 14.0);
    }
  }

  void _updateEta() {
    if (_driverPosition != null && _clientPosition != null) {
      _etaMinutes = DeliveryTrackingService.etaMinutes(
          _driverPosition!, _clientPosition!);
    }
  }

  // DEL-T05 : Partage localisation client toutes les 15s
  void _toggleLocationSharing() {
    setState(() => _sharingLocation = !_sharingLocation);
    if (_sharingLocation) {
      _locationShareTimer =
          Timer.periodic(const Duration(seconds: 15), (_) async {
        if (_clientPosition == null) return;
        await _trackingService.sendClientLocation(
            widget.order.id, _clientPosition!);
      });
    } else {
      _locationShareTimer?.cancel();
    }
  }

  // DEL-T07 : Ouvrir Google Maps vers le client
  Future<void> _openMapsNavigation() async {
    if (_clientPosition == null) return;
    final lat = _clientPosition!.latitude;
    final lng = _clientPosition!.longitude;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    _locationShareTimer?.cancel();
    _statusPollTimer?.cancel();
    _trackingService.stopTracking();
    _markerAnimCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───

  int get _currentStepIndex {
    final idx = _kSteps.indexWhere((s) => s.status == _deliveryStatus);
    return idx < 0 ? 0 : idx;
  }

  bool _isDelivered() => _deliveryStatus == 'delivered';

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStatusBar(),
            Expanded(child: _buildMap()),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back, color: Colors.grey[700], size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livraison — Commande #${widget.order.id}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _isDelivered()
                      ? '✅ Commande livrée !'
                      : 'Suivi en temps réel',
                  style: TextStyle(
                    color: _isDelivered()
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_etaMinutes != null && !_isDelivered())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      color: Colors.orangeAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '~$_etaMinutes min',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Barre de progression (DEL-T06) ──
  Widget _buildStatusBar() {
    final step = _currentStepIndex;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Row(
        children: List.generate(_kSteps.length, (i) {
          final isActive = i <= step;
          final isCurrent = i == step;
          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 34 : 28,
                      height: isCurrent ? 34 : 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? (isCurrent
                                ? AppColors.secondary
                                : AppColors.success)
                            : Colors.grey[300],
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        _kSteps[i].icon,
                        color: isActive ? Colors.white : Colors.grey[500],
                        size: isCurrent ? 16 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _kSteps[i].label,
                      style: TextStyle(
                        color:
                            isActive ? AppColors.textPrimary : Colors.grey[400],
                        fontSize: 9,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (i < _kSteps.length - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: i < step ? AppColors.success : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Carte (DEL-T03) ──
  Widget _buildMap() {
    // Position par défaut : Ouagadougou, Burkina Faso
    const defaultCenter = LatLng(12.3645, -1.5338);
    final center = _driverPosition ?? _clientPosition ?? defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _driverPosition != null ? 15.0 : 12.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // OSM tiles — pas de clé API
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.noogo.app',
          maxZoom: 19,
        ),
        // Polyline driver → client
        if (_driverPosition != null && _clientPosition != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_driverPosition!, _clientPosition!],
                color: AppColors.secondary.withValues(alpha: 0.8),
                strokeWidth: 3,
                isDotted: true,
              ),
            ],
          ),
        // Markers
        MarkerLayer(
          markers: [
            // Marker livreur animé (DEL-T04)
            if (_driverPosition != null)
              Marker(
                point: _driverPosition!,
                width: 56,
                height: 56,
                child: AnimatedBuilder(
                  animation: _markerAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _markerAnim.value,
                    child: child,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            // Marker client
            if (_clientPosition != null)
              Marker(
                point: _clientPosition!,
                width: 44,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Panneau bas ──
  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: const SizedBox(width: 40, height: 4),
          ),

          if (_isDelivered()) ...[
            // ─ Livraison terminée ─
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: AppColors.success, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Livraison effectuée !',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Merci d\'avoir choisi Noogo 🎉',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fermer'),
              ),
            ),
          ] else ...[
            // ─ Infos de livraison ─
            Row(
              children: [
                // Distance / ETA
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Temps estimé',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          _etaMinutes != null ? '~$_etaMinutes min' : '— min',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Statut
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Statut',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          _kSteps
                              .firstWhere(
                                (s) => s.status == _deliveryStatus,
                                orElse: () => _kSteps.first,
                              )
                              .label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Boutons action
            Row(
              children: [
                // Partager ma position (DEL-T05)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleLocationSharing,
                    icon: Icon(
                      _sharingLocation ? Icons.location_on : Icons.location_off,
                      size: 16,
                    ),
                    label: Text(
                      _sharingLocation ? 'Position ON' : 'Partager pos.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sharingLocation
                          ? AppColors.success
                          : Colors.grey[200],
                      foregroundColor: _sharingLocation
                          ? Colors.white
                          : AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Ouvrir dans Maps
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _clientPosition != null ? _openMapsNavigation : null,
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Google Maps',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget léger à afficher dans OrdersScreen sur les commandes `on_way` (DEL-T09)
class TrackingMiniCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const TrackingMiniCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withValues(alpha: 0.15),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.delivery_dining, color: AppColors.secondary, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Livreur en route',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Appuyer pour suivre en temps réel',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
