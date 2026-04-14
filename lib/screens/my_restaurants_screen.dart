import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_restaurant.dart';
import '../services/restaurant_storage_service.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

/// Écran "Mes restaurants" — liste des établissements scannés.
///
/// - Tap sur un restaurant → le charge et navigue vers HomeScreen
/// - Swipe-to-dismiss → retire le restaurant de la liste locale
/// - Bouton "Scanner un nouveau" → WelcomeScreen
class MyRestaurantsScreen extends StatefulWidget {
  const MyRestaurantsScreen({super.key});

  @override
  State<MyRestaurantsScreen> createState() => _MyRestaurantsScreenState();
}

class _MyRestaurantsScreenState extends State<MyRestaurantsScreen> {
  List<SavedRestaurant> _restaurants = [];
  bool _isLoading = true;
  int? _loadingId; // restaurant en cours de chargement

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final list = await RestaurantStorageService.getSavedRestaurants();
    if (!mounted) return;
    setState(() {
      _restaurants = list;
      _isLoading = false;
    });
  }

  // ─── Sélectionner un restaurant ──────────────────────────────────────────

  Future<void> _selectRestaurant(SavedRestaurant saved) async {
    if (_loadingId != null) return;
    setState(() => _loadingId = saved.id);

    try {
      final provider = context.read<RestaurantProvider>();
      await provider
          .loadAllInitialData(restaurantId: saved.id)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (provider.restaurant == null) throw Exception('Restaurant non chargé');

      // Mettre le dernier restaurant à jour
      await RestaurantStorageService.setLastRestaurantId(saved.id);
      // Actualiser lastScannedAt
      await RestaurantStorageService.addOrUpdateRestaurant(saved);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Impossible de charger ${saved.name} : ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _selectRestaurant(saved),
          ),
        ),
      );
    }
  }

  // ─── Supprimer de la liste ────────────────────────────────────────────────

  Future<void> _removeRestaurant(SavedRestaurant saved) async {
    await RestaurantStorageService.removeRestaurant(saved.id);
    setState(() => _restaurants.removeWhere((r) => r.id == saved.id));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${saved.name} retiré'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () async {
            await RestaurantStorageService.addOrUpdateRestaurant(saved);
            await _loadList();
          },
        ),
      ),
    );
  }

  // ─── Scanner un nouveau QR ────────────────────────────────────────────────

  void _scanNew() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes restaurants'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _restaurants.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanNew,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner un nouveau'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store_outlined,
                  size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Aucun restaurant enregistré',
                style: AppTextStyles.heading2, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Scannez le QR code d\'un restaurant pour le retrouver ici à chaque visite.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _scanNew,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scanner un restaurant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _restaurants.length,
      itemBuilder: (context, i) {
        final rest = _restaurants[i];
        return _buildCard(rest, isLast: i == _restaurants.length - 1);
      },
    );
  }

  Widget _buildCard(SavedRestaurant rest, {bool isLast = false}) {
    final isLoadingThis = _loadingId == rest.id;
    final isLoadingOther = _loadingId != null && _loadingId != rest.id;

    return Dismissible(
      key: ValueKey(rest.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeRestaurant(rest),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Supprimer',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: AnimatedOpacity(
        opacity: isLoadingOther ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: isLoadingThis || isLoadingOther
              ? null
              : () => _selectRestaurant(rest),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isLoadingThis
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Logo restaurant
                  _buildLogo(rest),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rest.name,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (rest.address != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  rest.address!,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              rest.lastSeenLabel,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action
                  if (isLoadingThis)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(SavedRestaurant rest) {
    const size = 56.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: rest.imageUrl != null && rest.imageUrl!.startsWith('http')
          ? Image.network(
              rest.imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _logoPlaceholder(rest.name, size),
            )
          : _logoPlaceholder(rest.name, size),
    );
  }

  Widget _logoPlaceholder(String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
