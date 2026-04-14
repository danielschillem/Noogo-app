import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/restaurant_header.dart';
import '../widgets/contact_info.dart';
import '../widgets/flash_info_section.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/skeleton.dart';
import '../widgets/section_header.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import '../utils/qr_helper.dart';
import '../models/category.dart';
import '../models/dish.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _tabFade;
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
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );

    _tabFade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
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

    // Mettre à jour le provider SANS écouter (évite la boucle)
    context.read<RestaurantProvider>().setNavIndex(index);

    // Fade out rapide, switch de page, fade in
    _animationController.reverse().then((_) {
      if (!mounted) return;
      _pageController.jumpToPage(index);
      _animationController.forward().then((_) {
        if (mounted) _isNavigating = false;
      });
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

          return FadeTransition(
            opacity: _tabFade,
            // PERF-002 : RepaintBoundary isole le PageView du reste du
            // Scaffold — les animations du bottom nav ne redessinent pas
            // tout le contenu des pages.
            child: RepaintBoundary(
              child: PageView(
                controller: _pageController,
                // onPageChanged uniquement pour les swipes manuels (désactivés)
                onPageChanged: (index) {
                  if (!_isNavigating) {
                    context.read<RestaurantProvider>().setNavIndex(index);
                  }
                },
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _HomePage(),
                  MenuScreen(),
                  CartScreen(),
                  OrdersScreen(),
                  ProfileScreen(),
                ],
              ),
            ),
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

    return RefreshIndicator(
      onRefresh: provider.refreshAllData,
      color: AppColors.primary,
      displacement: 80,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // --- SliverAppBar flottant (style Pro_Grocery) ---
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: AppColors.shadowColor,
            centerTitle: true,
            title: provider.restaurant != null
                ? Text(
                    provider.restaurant!.name,
                    style: AppTextStyles.heading3,
                    overflow: TextOverflow.ellipsis,
                  )
                : Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    errorBuilder: (_, __, ___) => Text(
                      'Noogo',
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                color: AppColors.textPrimary,
                onPressed: () =>
                    context.read<RestaurantProvider>().setNavIndex(2),
                tooltip: 'Panier',
              ),
            ],
          ),

          // --- Bannière erreur réseau ---
          if (provider.hasApiError || provider.isOffline)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.secondary.withValues(alpha: 0.10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.isOffline
                            ? 'Mode hors-ligne — données en cache'
                            : 'Connexion limitée',
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
            ),

          // --- En-tête restaurant ---
          if (provider.restaurant != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: RestaurantHeader(restaurant: provider.restaurant!),
              ),
            ),

          if (provider.restaurant != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ContactInfo(restaurant: provider.restaurant!),
              ),
            ),

          // --- Flash infos ---
          if (provider.flashInfos.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FlashInfoSection(
                  flashInfos: provider.flashInfos,
                  onOrderPressed: () => _showOrderDialog(context),
                ),
              ),
            ),

          // --- Section Catégories ---
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Catégories',
              onActionTap: () =>
                  context.read<RestaurantProvider>().setNavIndex(1),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: provider.isLoading && !provider.hasData
                ? _buildCategorySkeleton()
                : _buildCategoriesRow(
                    provider.categories.cast<Category>(), context, provider),
          ),

          // --- Section Plats populaires ---
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Plats populaires',
              onActionTap: () =>
                  context.read<RestaurantProvider>().setNavIndex(1),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: provider.isLoading && !provider.hasData
                ? _buildDishSkeleton()
                : _buildDishesRow(
                    provider.availableDishes.cast<Dish>(), context, provider),
          ),

          // --- Erreur sans données ---
          if (provider.error != null && !provider.hasData)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 56, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    const Text('Impossible de charger',
                        style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: provider.refreshAllData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // --- Skeleton catégories ---
  static Widget _buildCategorySkeleton() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Column(
            children: [
              CircleSkeleton(size: 64),
              SizedBox(height: 6),
              Skeleton(height: 10, width: 60, radius: 6),
            ],
          ),
        ),
      ),
    );
  }

  // --- Skeleton plats ---
  static Widget _buildDishSkeleton() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(right: 12),
          child: DishCardSkeleton(),
        ),
      ),
    );
  }

  // --- Ligne de catégories ---
  static Widget _buildCategoriesRow(List<Category> categories,
      BuildContext context, RestaurantProvider provider) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final featured = categories.take(6).toList();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: featured.length,
        itemBuilder: (context, index) =>
            _buildCategoryChip(featured[index], provider, context),
      ),
    );
  }

  // A11Y-002 : Semantics + Tooltip pour la navigation par catégorie
  static Widget _buildCategoryChip(
      Category category, RestaurantProvider provider, BuildContext context) {
    return Semantics(
      label: 'Catégorie ${category.name}',
      button: true,
      child: GestureDetector(
        onTap: () {
          provider.filterDishesByCategory(category.id);
          provider.setNavIndex(1);
        },
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: ExcludeSemantics(
                    child: CachedNetworkImage(
                      imageUrl: category.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  category.name,
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Ligne de plats ---
  static Widget _buildDishesRow(
      List<Dish> dishes, BuildContext context, RestaurantProvider provider) {
    if (dishes.isEmpty) return const SizedBox.shrink();
    final popular = dishes.take(8).toList();
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: popular.length,
        itemBuilder: (context, index) =>
            _buildDishCard(popular[index], provider, context),
      ),
    );
  }

  static Widget _buildDishCard(
      Dish dish, RestaurantProvider provider, BuildContext context) {
    // PERF-003 + A11Y-003 : RepaintBoundary + Semantics sur chaque carte
    return RepaintBoundary(
      child: Semantics(
        label: '${dish.name}, ${dish.formattedPrice}',
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: ExcludeSemantics(
                    child: CachedNetworkImage(
                      imageUrl: dish.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: AppColors.surface,
                        child: Center(
                          child: Icon(Icons.fastfood_outlined,
                              size: 36, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Info texte
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dish.formattedPrice,
                            style: AppTextStyles.price.copyWith(fontSize: 14),
                          ),
                          // A11Y-004 : Semantics sur le bouton d'ajout rapide
                          Semantics(
                            label: 'Ajouter ${dish.name} au panier',
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                provider.addToCart(dish);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${dish.name} ajouté'),
                                    backgroundColor: AppColors.success,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 18),
                              ),
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
        ),
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
            child: const Text('Voir le menu'),
          ),
        ],
      ),
    );
  }
}
