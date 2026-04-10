import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/restaurant_header.dart';
import '../widgets/contact_info.dart';
import '../widgets/flash_info_section.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import '../utils/qr_helper.dart';
import '../models/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;

  // ✅ Flag pour éviter les navigations concurrentes
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // ✅ Lire l'index initial UNE SEULE FOIS sans déclencher de rebuild
    final initialIndex = context.read<RestaurantProvider>().currentNavIndex;
    _pageController = PageController(initialPage: initialIndex);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _animationController.forward();

      final provider = context.read<RestaurantProvider>();

      // ✅ Charger les données si besoin
      if (provider.restaurant == null && provider.scannedQRCode != null) {
        final restaurantId =
            QRHelper.parseRestaurantId(provider.scannedQRCode!);
        if (restaurantId != null) {
          provider.loadAllInitialData(restaurantId: restaurantId);
        }
      }
    });
  }

  // ✅ Navigation centralisée, sûre et sans boucle
  void _navigateToPage(int index) {
    if (_isNavigating) return;
    if (!mounted) return;
    if (!_pageController.hasClients) return;

    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage == index) return;

    _isNavigating = true;

    // ✅ Mettre à jour le provider SANS écouter (évite la boucle)
    context.read<RestaurantProvider>().setNavIndex(index);

    // ✅ Toujours utiliser jumpToPage pour éviter les animations qui crashent
    // lors de navigations rapides ou depuis des écrans complexes (Profil, etc.)
    _pageController.jumpToPage(index);

    // Libérer le verrou après un court délai
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _isNavigating = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();

    // ✅ Dispose propre du PageController
    try {
      _pageController.dispose();
    } catch (e) {
      debugPrint('⚠️ PageController dispose: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          // ✅ Synchroniser la page affichée si le provider change depuis l'extérieur
          // (ex: navigation depuis un écran enfant via provider.setNavIndex)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (!_pageController.hasClients) return;
            if (_isNavigating) return;

            final providerIndex = provider.currentNavIndex;
            final currentPage = _pageController.page?.round() ?? 0;

            if (currentPage != providerIndex) {
              _isNavigating = true;
              _pageController.jumpToPage(providerIndex);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) _isNavigating = false;
              });
            }
          });

          return PageView(
            controller: _pageController,
            // ✅ onPageChanged uniquement pour les swipes manuels (désactivés ici)
            onPageChanged: (index) {
              if (!_isNavigating) {
                context.read<RestaurantProvider>().setNavIndex(index);
              }
            },
            // ✅ Swipe désactivé : évite les transitions accidentelles
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _HomePage(),
              MenuScreen(),
              CartScreen(),
              OrdersScreen(),
              ProfileScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<RestaurantProvider>(
        builder: (context, provider, _) => CustomBottomNavigation(
          currentIndex: provider.currentNavIndex,
          onTap: _navigateToPage, // ✅ Utiliser la méthode centralisée
        ),
      ),
    );
  }
}

// ---------------------- PAGE D'ACCUEIL ----------------------
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();

    if (provider.isLoading && !provider.hasData) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.error != null && !provider.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: provider.refreshAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refreshAllData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Bannière d'erreur réseau
            if (provider.hasApiError)
              Container(
                width: double.infinity,
                color: AppColors.secondary.withValues(alpha: 0.12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connexion au serveur impossible — affichage des données locales',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: provider.refreshAllData,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            if (provider.restaurant != null)
              RestaurantHeader(restaurant: provider.restaurant!),

            const SizedBox(height: 16),

            if (provider.restaurant != null)
              ContactInfo(restaurant: provider.restaurant!),

            const SizedBox(height: 24),

            if (provider.flashInfos.isNotEmpty)
              FlashInfoSection(
                flashInfos: provider.flashInfos,
                onOrderPressed: () => _showOrderDialog(context),
              ),

            const SizedBox(height: 24),

            _buildFeaturedCategoriesSection(context, provider),

            const SizedBox(height: 20),

            _buildPopularDishesSection(context, provider),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeaturedCategoriesSection(
      BuildContext context, RestaurantProvider provider) {
    final categories = provider.categories.cast<Category>();
    if (categories.isEmpty) return const SizedBox.shrink();

    final featuredCategories = categories.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Catégories', style: AppTextStyles.heading3),
              TextButton(
                onPressed: () =>
                    context.read<RestaurantProvider>().setNavIndex(1),
                child: Text(
                  'Voir tout',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: featuredCategories.length,
            itemBuilder: (context, index) {
              final category = featuredCategories[index];
              return _buildCategoryCard(category, provider, context);
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildCategoryCard(
      Category category, RestaurantProvider provider, BuildContext context) {
    return GestureDetector(
      onTap: () {
        provider.filterDishesByCategory(category.id);
        provider.setNavIndex(1);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 5,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  category.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(Icons.fastfood,
                          size: 40, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPopularDishesSection(
      BuildContext context, RestaurantProvider provider) {
    final availableDishes = provider.availableDishes;
    if (availableDishes.isEmpty) return const SizedBox.shrink();

    final firstRow = availableDishes.take(3).toList();
    final secondRow = availableDishes.skip(3).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Plats populaires', style: AppTextStyles.heading3),
              TextButton(
                onPressed: () =>
                    context.read<RestaurantProvider>().setNavIndex(1),
                child: Text(
                  'Voir tout',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDishRow(firstRow, provider, context),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDishRow(secondRow, provider, context),
        ],
      ],
    );
  }

  static Widget _buildDishRow(
      List<dynamic> dishes, RestaurantProvider provider, BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dishes.length,
        itemBuilder: (context, index) {
          final dish = dishes[index];
          return _buildDishCard(dish, provider, context);
        },
      ),
    );
  }

  static Widget _buildDishCard(
      dish, RestaurantProvider provider, BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                dish.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.fastfood_outlined, size: 40),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dish.formattedPrice,
                          style: AppTextStyles.price.copyWith(fontSize: 14)),
                      GestureDetector(
                        onTap: () {
                          provider.addToCart(dish);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${dish.name} ajouté au panier'),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commande rapide'),
        content: const Text(
            'Voulez-vous passer une commande rapide pour ce plat du jour ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RestaurantProvider>().setNavIndex(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Voir le menu'),
          ),
        ],
      ),
    );
  }
}
