import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_restaurant.dart';
import '../services/restaurant_provider.dart';
import '../services/restaurant_storage_service.dart';
import 'my_restaurants_screen.dart';
import 'qr_scanner_screen.dart';
import 'home_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isValidating = false;
  bool _isPressed = false;
  bool _hasSavedRestaurants = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final TextEditingController _testController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
    _checkSavedRestaurants();
  }

  Future<void> _checkSavedRestaurants() async {
    final list = await RestaurantStorageService.getSavedRestaurants();
    if (mounted) setState(() => _hasSavedRestaurants = list.isNotEmpty);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _testController.dispose();
    super.dispose();
  }

  Future<void> _scanAndValidateQRCode() async {
    if (_isValidating) {
      debugPrint('⚠️ Validation déjà en cours, ignoré');
      return;
    }

    try {
      debugPrint('📱 Ouverture du scanner QR...');

      if (!mounted) return;

      final String? qrCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );

      if (!mounted) return;

      if (qrCode == null) {
        debugPrint('⚠️ Scan annulé par l\'utilisateur');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan annulé'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }

      if (qrCode.isEmpty) {
        debugPrint('⚠️ QR code vide reçu');
        _showErrorDialog(
            'QR code vide', 'Le QR code scanné ne contient aucune donnée.');
        return;
      }

      debugPrint('✅ QR Code reçu du scanner: "$qrCode"');

      if (!mounted) return;

      setState(() {
        _isValidating = true;
      });

      if (!mounted) return;

      final provider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      debugPrint('🔄 Validation du QR code en cours...');

      // 🔥 FIX : Valider ET charger les données en une seule opération
      await provider.validateRestaurantQRCode(qrCode).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'Timeout: Le serveur met trop de temps à répondre. Vérifiez votre connexion internet.');
        },
      );

      if (!mounted) return;

      // ✅ Vérifier que les données sont bien chargées
      if (provider.restaurant == null) {
        throw Exception(
            'Les données du restaurant n\'ont pas pu être chargées');
      }

      // ✅ Sauvegarder les données du restaurant
      final int restaurantId = provider.restaurant!.id;
      final restaurantData = {
        'id': provider.restaurant!.id,
        'name': provider.restaurant!.name,
        'address': provider.restaurant!.address,
        'phone': provider.restaurant!.phone,
        'imageUrl': provider.restaurant!.imageUrl,
        'description': provider.restaurant!.description,
        'scannedAt': DateTime.now().toIso8601String(),
      };

      await RestaurantStorageService.saveRestaurantData(
        restaurantId: restaurantId.toString(),
        restaurantData: restaurantData,
      );

      // Sauvegarder dans la liste multi-restaurants
      await RestaurantStorageService.addOrUpdateRestaurant(
        SavedRestaurant(
          id: restaurantId,
          name: provider.restaurant!.name,
          imageUrl: provider.restaurant!.imageUrl,
          address: provider.restaurant!.address,
          phone: provider.restaurant!.phone,
          lastScannedAt: DateTime.now(),
        ),
      );
      setState(() => _hasSavedRestaurants = true);

      debugPrint(
          '✅ Validation réussie! Restaurant: ${provider.restaurant?.name}');
      debugPrint('   - Plats: ${provider.dishes.length}');
      debugPrint('   - Catégories: ${provider.categories.length}');

      if (!mounted) return;

      // 🔥 FIX : Attendre un instant pour que le provider notifie tous ses listeners
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bienvenue dans ${provider.restaurant?.name ?? "notre restaurant"} !',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 🔥 FIX : Attendre que le snackbar se ferme avant de naviguer
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 🔥 FIX PRINCIPAL : Utiliser pushAndRemoveUntil pour nettoyer toute la pile de navigation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false, // Supprime toutes les routes précédentes
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de la validation: $e');

      if (!mounted) return;

      String errorMessage = e.toString().replaceAll('Exception: ', '');
      String errorTitle = 'Erreur de validation';

      if (errorMessage.contains('Timeout') ||
          errorMessage.contains('timeout')) {
        errorTitle = 'Délai d\'attente dépassé';
        errorMessage =
            'Le serveur met trop de temps à répondre. Vérifiez votre connexion internet et réessayez.';
      } else if (errorMessage.contains('Format de QR code invalide') ||
          errorMessage.contains('n\'est pas valide')) {
        errorTitle = 'QR code invalide';
        errorMessage =
            'Ce QR code n\'est pas valide pour notre application. Veuillez scanner le QR code du restaurant.';
      } else if (errorMessage.contains('connexion') ||
          errorMessage.contains('Connection') ||
          errorMessage.contains('SocketException')) {
        errorTitle = 'Problème de connexion';
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (errorMessage.contains('restaurant invalide') ||
          errorMessage.contains('non trouvé') ||
          errorMessage.contains('introuvable')) {
        errorTitle = 'Restaurant introuvable';
        errorMessage =
            'Ce restaurant n\'existe pas ou n\'est plus disponible dans notre système.';
      } else if (errorMessage.contains('404')) {
        errorTitle = 'Restaurant introuvable';
        errorMessage =
            'Le restaurant avec cet ID n\'existe pas dans notre système.';
      } else if (errorMessage.contains('500')) {
        errorTitle = 'Erreur serveur';
        errorMessage =
            'Le serveur rencontre un problème. Veuillez réessayer dans quelques instants.';
      }

      _showErrorDialog(errorTitle, errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: AppTextStyles.heading3)),
          ],
        ),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 300), () {
                _scanAndValidateQRCode();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 60, 138, 82),
              Color.fromARGB(255, 60, 138, 82),
              Color.fromARGB(255, 254, 254, 254),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: _isValidating ? _buildLoadingView() : _buildWelcomeView(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
        const SizedBox(height: 24),
        const Text(
          'Validation en cours...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Veuillez patienter',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            if (mounted) {
              setState(() {
                _isValidating = false;
              });
            }
          },
          child: const Text(
            'Annuler',
            style: TextStyle(
              color: Colors.white70,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // LOGO ANIMÉ ET CLIQUABLE
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _scanAndValidateQRCode();
                },
                onTapCancel: () => setState(() => _isPressed = false),
                child: AnimatedScale(
                  scale: _isPressed ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          ),
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 3,
                              ),
                            ),
                          ),
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(
                                      alpha: _isPressed ? 0.6 : 0.4),
                                  blurRadius: _isPressed ? 40 : 30,
                                  spreadRadius: _isPressed ? 8 : 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/03.png',
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.restaurant,
                                    size: 70,
                                    color: AppColors.primary,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          const Text(
            'Touchez l\'icône pour scanner',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 60),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAnimatedStep(
                  icon: Icons.qr_code_scanner, label: 'Scanner', delay: 0),
              _buildAnimatedStep(
                  icon: Icons.restaurant_menu, label: 'Commander', delay: 200),
              _buildAnimatedStep(
                  icon: Icons.payment, label: 'Payer', delay: 400),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Simple. Rapide. Sécurisé.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 70),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isValidating ? null : _scanAndValidateQRCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B975B),
                disabledBackgroundColor: Colors.white70,
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text(
                'Scanner le QR Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Bouton "Mes restaurants" si des restaurants sont déjà sauvegardés
          if (_hasSavedRestaurants) ...[
            const SizedBox(height: 12),
            _buildMyRestaurantsButton()
          ],

          // Bouton Mode Démo (debug uniquement)
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isValidating
                    ? null
                    : () {
                        final provider = Provider.of<RestaurantProvider>(
                          context,
                          listen: false,
                        );
                        provider.loadDemoData();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.science_outlined, size: 20),
                label: const Text(
                  'Mode Démo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMyRestaurantsButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyRestaurantsScreen()),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.store_outlined, size: 22),
        label: const Text(
          'Mes restaurants enregistrés',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildAnimatedStep({
    required IconData icon,
    required String label,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, -20 * (1 - clampedValue)),
          child: Opacity(
            opacity: clampedValue,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
