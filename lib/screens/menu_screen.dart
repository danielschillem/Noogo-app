import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/category.dart';
import '../models/dish.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<MenuScreen> {
  @override
  bool get wantKeepAlive => true;

  int _selectedCategoryId = 0; // 0 = toutes les catégories, -1 = favoris
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Map pour stocker les quantités temporaires de chaque plat
  final Map<String, int> _tempQuantities = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Obtenir la quantité d'un plat (temporaire + panier)
  int _getDishQuantity(String dishId, RestaurantProvider provider) {
    final tempQty = _tempQuantities[dishId] ?? 0;
    final cartQty = provider.cartItems
        .where((item) => item.dish.id.toString() == dishId)
        .fold(0, (sum, item) => sum + item.quantity);
    return tempQty + cartQty;
  }

  // Incrémenter la quantité temporaire
  void _incrementQuantity(String dishId) {
    setState(() {
      _tempQuantities[dishId] = (_tempQuantities[dishId] ?? 0) + 1;
    });
  }

  // Décrémenter la quantité temporaire
  void _decrementQuantity(String dishId) {
    setState(() {
      if ((_tempQuantities[dishId] ?? 0) > 0) {
        _tempQuantities[dishId] = _tempQuantities[dishId]! - 1;
        if (_tempQuantities[dishId] == 0) {
          _tempQuantities.remove(dishId);
        }
      }
    });
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
      appBar: const CustomAppBar(
        title: 'Menu',
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.error != null && !provider.hasData) {
            return _buildErrorWidget(provider);
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: provider.refreshAllData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.hasApiError || provider.isOffline)
                      Container(
                        width: double.infinity,
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.isOffline
                                    ? 'Mode hors-ligne — menu mis en cache'
                                    : '',
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
                    // Titre de la page
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '',
                        style: AppTextStyles.heading1,
                      ),
                    ),

                    // Catégories circulaires
                    _buildCategoriesSection(
                        provider.categories.cast<Category>(), provider),

                    const SizedBox(height: 12),

                    // Barre de recherche
                    _buildSearchBar(),

                    const SizedBox(height: 24),

                    // Liste des plats
                    _buildDishesSection(provider),

                    const SizedBox(height: 50), // Espace pour la navigation
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Rechercher un plat...',
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(RestaurantProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: AppTextStyles.heading3,
          ),
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
            onPressed: () => provider.refreshAllData(),
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

  Widget _buildCategoriesSection(
      List<Category> categories, RestaurantProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Catégories'),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 2, // +1 "Toutes" +1 "Favoris"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryItem(
                  id: 0,
                  name: 'Toutes',
                  imageUrl:
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=1780&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                  isSelected: _selectedCategoryId == 0,
                );
              }
              if (index == 1) {
                final favCount = provider.favoriteDishes.length;
                return _buildFavoriteCategoryItem(favCount);
              }
              final category = categories[index - 2];
              return _buildCategoryItem(
                id: category.id,
                name: category.name,
                imageUrl: category.imageUrl,
                isSelected: _selectedCategoryId == category.id,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCategoryItem(int favCount) {
    final isSelected = _selectedCategoryId == -1;
    // A11Y-005 : Semantics sur l'élément de catégorie favoris
    return Semantics(
      label: 'Catégorie Favoris${isSelected ? ", sélectionnée" : ""}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = -1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: isSelected ? AppColors.primary : Colors.grey,
                      size: 28,
                    ),
                    if (favCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$favCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 70,
                child: Text(
                  'Favoris',
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required int id,
    required String name,
    required String imageUrl,
    required bool isSelected,
  }) {
    // A11Y-006 : Semantics sur chaque puce de catégorie
    return Semantics(
      label: '$name${isSelected ? ", sélectionnée" : ""}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => _onCategorySelected(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: ExcludeSemantics(
                    child: _buildImage(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 70,
                child: Text(
                  name,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDishesSection(RestaurantProvider provider) {
    List<Dish> filteredDishes;
    if (_selectedCategoryId == -1) {
      // Mode "Favoris"
      filteredDishes = provider.favoriteDishes;
    } else if (_selectedCategoryId == 0) {
      filteredDishes = provider.dishes;
    } else {
      filteredDishes = provider.dishes
          .where((dish) => dish.categoryId == _selectedCategoryId)
          .toList();
    }

    // Filtre recherche texte
    if (_searchQuery.isNotEmpty) {
      filteredDishes = filteredDishes.where((dish) {
        return dish.name.toLowerCase().contains(_searchQuery) ||
            dish.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (filteredDishes.isEmpty) {
      final isSearching = _searchQuery.isNotEmpty;
      final isFiltered = _selectedCategoryId != 0;
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                isSearching ? Icons.search_off : Icons.restaurant_menu,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                isSearching
                    ? 'Aucun plat pour "$_searchQuery"'
                    : isFiltered
                        ? 'Aucun plat dans cette catégorie'
                        : _selectedCategoryId == -1
                            ? 'Aucun plat en favori. Appuyez sur \u2665 pour en ajouter.'
                            : 'Le menu est vide pour le moment',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              if (isSearching) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Text('Effacer la recherche'),
                ),
              ] else if (isFiltered) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _selectedCategoryId = 0),
                  child: const Text('Voir tous les plats'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _searchQuery.isNotEmpty
              ? 'Résultats (${filteredDishes.length})'
              : _selectedCategoryId == -1
                  ? 'Mes favoris (${filteredDishes.length})'
                  : 'Plats disponibles (${filteredDishes.length})',
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredDishes.length,
          itemBuilder: (context, index) {
            final dish = filteredDishes[index];
            // PERF-004 + A11Y-007 : RepaintBoundary + Semantics sur chaque carte de plat
            return RepaintBoundary(
              child: Semantics(
                label:
                    '${dish.name}, ${dish.formattedPrice}${!dish.isAvailable ? ", non disponible" : ""}',
                child: _buildDishCard(dish, provider),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDishCard(Dish dish, RestaurantProvider provider) {
    final currentQuantity = _getDishQuantity(dish.id.toString(), provider);
    final tempQuantity = _tempQuantities[dish.id.toString()] ?? 0;
    final isFav = provider.isFavoriteDish(dish.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
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
          // --- Image en haut (large, arrondie en haut) ---
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _buildImage(
                      dish.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Badge plat du jour
                if (dish.isDishOfTheDay)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Plat du jour',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Bouton favori (FEAT-004) — A11Y-008 : Tooltip lecteur d'écran
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Tooltip(
                    message:
                        isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                    child: GestureDetector(
                      onTap: () => provider.toggleFavoriteDish(dish.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // Badge quantité si > 0
                if (currentQuantity > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        currentQuantity.toString(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Overlay si non disponible
                if (!dish.isAvailable)
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: Text(
                        'Non disponible',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- Infos plat ---
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + Prix
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        dish.name,
                        style: AppTextStyles.heading3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dish.formattedPrice,
                      style: AppTextStyles.price.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dish.description,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dish.preparationTime} min',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dish.category,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Contrôles de quantité et bouton panier
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Contrôles de quantité
                    Row(
                      children: [
                        // Bouton -
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            tooltip: 'Diminuer la quantité',
                            onPressed: dish.isAvailable && tempQuantity > 0
                                ? () => _decrementQuantity(dish.id.toString())
                                : null,
                            icon: const Icon(Icons.remove),
                            color: AppColors.primary,
                            constraints: const BoxConstraints(
                              minWidth: 10,
                              minHeight: 10,
                            ),
                          ),
                        ),

                        // Affichage quantité
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tempQuantity.toString(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Bouton +
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: IconButton(
                            tooltip: 'Augmenter la quantité',
                            onPressed: dish.isAvailable
                                ? () => _incrementQuantity(dish.id.toString())
                                : null,
                            icon: const Icon(Icons.add),
                            color: AppColors.primary,
                            constraints: const BoxConstraints(
                              minWidth: 10,
                              minHeight: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bouton Ajouter au panier
                    ElevatedButton.icon(
                      onPressed: dish.isAvailable && tempQuantity > 0
                          ? () => _addToCart(dish, provider)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                      ),
                      icon: const Icon(Icons.shopping_cart, size: 15),
                      label: Text(
                        tempQuantity > 0
                            ? 'Ajouter (${(dish.price * tempQuantity).toStringAsFixed(0)} FCFA)'
                            : 'Panier',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onCategorySelected(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });

    if (categoryId == -1) return; // Mode favoris — filtrage local

    final provider = context.read<RestaurantProvider>();
    if (categoryId == 0) {
      provider.loadDishes(); // Charger tous les plats
    } else {
      provider.filterDishesByCategory(categoryId); // Filtrer par catégorie
    }
  }

  void _addToCart(Dish dish, RestaurantProvider provider) {
    final quantity = _tempQuantities[dish.id.toString()] ?? 0;
    if (quantity > 0) {
      provider.addToCart(dish, quantity: quantity);

      // Réinitialiser la quantité temporaire
      setState(() {
        _tempQuantities.remove(dish.id.toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${dish.name} x$quantity ajouté au panier'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Voir panier',
            textColor: AppColors.textLight,
            onPressed: () {
              provider.setNavIndex(2); // Naviguer vers le panier
            },
          ),
        ),
      );
    }
  }
}
