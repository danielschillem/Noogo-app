import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/category.dart';
import '../models/dish.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  int _selectedCategoryId = 0; // 0 = toutes les catégories
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
        placeholder: (context, url) => Container(
          color: AppColors.surface,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
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
        errorBuilder: (context, error, stackTrace) => Container(
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
                    if (provider.hasApiError)
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
                                '',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: provider.refreshAllData,
                              child: const Text(''),
                            ),
                          ],
                        ),
                      ),
                    // Titre de la page
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '',
                        style: AppTextStyles.heading1,
                      ),
                    ),

                    // Catégories circulaires
                    _buildCategoriesSection(
                        provider.categories.cast<Category>()),

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

  Widget _buildErrorWidget(RestaurantProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
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

  Widget _buildCategoriesSection(List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Catégories',
            style: AppTextStyles.heading3,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1, // +1 pour "Toutes"
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
              final category = categories[index - 1];
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

  Widget _buildCategoryItem({
    required int id,
    required String name,
    required String imageUrl,
    required bool isSelected,
  }) {
    // ✅ DEBUG : Afficher l'URL de chaque catégorie
    debugPrint('📸 Category "$name" - URL: "$imageUrl"');

    return GestureDetector(
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildImage(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                name,
                style: AppTextStyles.caption.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishesSection(RestaurantProvider provider) {
    final filteredDishes = _selectedCategoryId == 0
        ? provider.dishes
        : provider.dishes
            .where((dish) => dish.categoryId == _selectedCategoryId)
            .toList();

    if (filteredDishes.isEmpty) {
      final isFiltered = _selectedCategoryId != 0;
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                isFiltered
                    ? 'Aucun plat dans cette catégorie'
                    : 'Le menu est vide pour le moment',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              if (isFiltered) ...[
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Plats disponibles (${filteredDishes.length})',
            style: AppTextStyles.heading3,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredDishes.length,
          itemBuilder: (context, index) {
            final dish = filteredDishes[index];
            return _buildDishCard(dish, provider);
          },
        ),
      ],
    );
  }

  Widget _buildDishCard(Dish dish, RestaurantProvider provider) {
    final currentQuantity = _getDishQuantity(dish.id.toString(), provider);
    final tempQuantity = _tempQuantities[dish.id.toString()] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du plat
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: _buildImage(
                    dish.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
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

                // Badge quantité si > 0
                if (currentQuantity > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
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
                    height: 200,
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Center(
                      child: Text(
                        'Non disponible',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Informations du plat
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dish.name,
                        style: AppTextStyles.heading3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dish.formattedPrice,
                      style: AppTextStyles.price.copyWith(fontSize: 18),
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
                    Icon(
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
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
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
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: IconButton(
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
