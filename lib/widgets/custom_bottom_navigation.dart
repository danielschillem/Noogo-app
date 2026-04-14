import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/restaurant_provider.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // PERF-001 : Selector ne déclenche un rebuild que si le nombre
    // d'articles dans le panier change (vs Consumer qui réagit à tout).
    return Selector<RestaurantProvider, int>(
      selector: (_, p) => p.cartItems.length,
      builder: (context, cartCount, _) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.cardBackground,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu_outlined),
                activeIcon: Icon(Icons.restaurant_menu),
                label: 'Menu',
              ),
              // A11Y-001 : Label dynamique pour les lecteurs d'écran
              BottomNavigationBarItem(
                icon: Semantics(
                  label: cartCount > 0
                      ? 'Panier, $cartCount article${cartCount > 1 ? "s" : ""}'
                      : 'Panier',
                  excludeSemantics: true,
                  child: Stack(
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      if (cartCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              cartCount > 9 ? '9+' : '$cartCount',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                activeIcon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cartCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartCount > 9 ? '9+' : '$cartCount',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Panier',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Commandes',
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
