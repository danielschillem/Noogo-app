import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/restaurant_provider.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';
import 'auth_screen.dart';
import 'my_restaurants_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<ProfileScreen> {
  @override
  bool get wantKeepAlive => true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  User? _currentUser;
  bool _isLoading = true;
  bool _isGuestMode = false;

  // ✅ Flag manuel qu'on passe à false AVANT dispose()
  // mounted reste true dans un PageView même si la page est cachée,
  // ce flag lui est complémentaire pour les cas de démontage partiel.
  bool _isAlive = true;

  // ✅ Wrapper sécurisé : ne fait jamais setState si le widget
  // est en train d'être démonté (_lifecycleState != active)
  void _safeSetState(VoidCallback fn) {
    if (_isAlive && mounted) {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // ✅ Utiliser addPostFrameCallback pour s'assurer que le widget
    // est complètement construit avant de lancer le chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAlive && mounted) _loadUserData();
    });
  }

  @override
  void dispose() {
    // ✅ Désactiver le flag EN PREMIER, avant tout autre dispose
    // Ainsi tous les await en cours s'arrêteront immédiatement
    _isAlive = false;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!_isAlive || !mounted) return;

    _safeSetState(() => _isLoading = true);

    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!_isAlive || !mounted) return;

      final isGuest = await AuthService.isGuestMode();
      if (!_isAlive || !mounted) return;

      User? user;
      if (isLoggedIn) {
        user = await AuthService.getCurrentUser();
        if (!_isAlive || !mounted) return;
      }

      _safeSetState(() {
        _currentUser = user;
        _isGuestMode = isGuest;
        _isLoading = false;
      });

      if (_isAlive && mounted) {
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('❌ ProfileScreen._loadUserData error: $e');
      _safeSetState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Profile'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser != null
              ? _buildAuthenticatedProfile()
              : _buildGuestProfile(),
    );
  }

  // ─── Authenticated ────────────────────────────────────────────────────────────

  Widget _buildAuthenticatedProfile() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 22),
            _buildStatsSection(),
            const SizedBox(height: 22),
            _buildMenuOptions(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.textLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.name ?? 'Utilisateur Noogo',
            style: AppTextStyles.heading2.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser?.phone ?? '+226 54 05 90 90',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textLight.withValues(alpha: 0.9)),
          ),
          if (_currentUser?.email != null) ...[
            const SizedBox(height: 2),
            Text(
              _currentUser!.email!,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textLight.withValues(alpha: 0.8)),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _editProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textLight,
              side: const BorderSide(color: AppColors.textLight),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: const Text('Modifier le profil'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    // ✅ Consumer garantit un context valide pour lire le provider
    return Consumer<RestaurantProvider>(
      builder: (context, provider, child) {
        final userPoints = provider.orders.length * 5;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 6,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mes statistiques', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                        'Commandes',
                        '${provider.orders.length}',
                        Icons.receipt_long,
                        AppColors.primary),
                  ),
                  Expanded(
                    child: _buildStatItem(
                        'Panier',
                        '${provider.cartItems.length}',
                        Icons.shopping_cart,
                        AppColors.secondary),
                  ),
                  Expanded(
                    child: _buildStatItem(
                        'Points', '$userPoints', Icons.star, Colors.amber),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.heading3.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildMenuOptions() {
    final options = [
      {
        'icon': Icons.store,
        'title': 'Mes restaurants enregistrés',
        'color': AppColors.primary,
        'action': _showMyRestaurants,
      },
      {
        'icon': Icons.swap_horiz,
        'title': 'Changer de restaurant',
        'color': AppColors.secondary,
        'action': _changeRestaurant,
      },
      {
        'icon': Icons.person_outline,
        'title': 'Mes informations personnelles',
        'action': _showPersonalInfo
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Changer le mot de passe',
        'action': _showChangePassword
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Adresses de livraison',
        'action': _showDeliveryAddresses
      },
      {
        'icon': Icons.payment_outlined,
        'title': 'Méthodes de paiement',
        'action': _showPaymentMethods
      },
      {
        'icon': Icons.history,
        'title': 'Historique des commandes',
        'action': _showOrderHistory
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'action': _showNotificationSettings
      },
      {
        'icon': Icons.help_outline,
        'title': 'Aide et support',
        'action': _showHelp
      },
      {'icon': Icons.info_outline, 'title': 'À propos', 'action': _showAbout},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Toggle dark mode
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'Mode sombre',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggle(),
                    activeThumbColor: AppColors.primary,
                  ),
                  onTap: () => themeProvider.toggle(),
                ),
              );
            },
          ),
          ...options.map((opt) {
            final iconColor = (opt['color'] as Color?) ?? AppColors.primary;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(opt['icon'] as IconData, color: iconColor),
                ),
                title: Text(
                  opt['title'] as String,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: opt['action'] as VoidCallback,
              ),
            );
          }),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Se déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Guest ────────────────────────────────────────────────────────────────────

  Widget _buildGuestProfile() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.person_outline,
                  size: 50, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            const Text('Créez votre compte NOOGO',
                style: AppTextStyles.heading2, textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(
              'Connectez-vous pour accéder à votre profil, suivre vos commandes et bénéficier d\'avantages exclusifs.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 08),
            _buildBenefitsList(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showAuthScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(08)),
                ),
                child: const Text('Se connecter / S\'inscrire'),
              ),
            ),
            if (!_isGuestMode)
              TextButton(
                onPressed: _enableGuestMode,
                child: const Text('Continuer sans compte'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {
        'icon': Icons.history,
        'title': 'Historique des commandes',
        'subtitle': 'Retrouvez toutes vos commandes'
      },
      {
        'icon': Icons.favorite,
        'title': 'Favoris',
        'subtitle': 'Sauvegardez vos plats préférés'
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'subtitle': 'Recevez des offres exclusives'
      },
    ];

    return Column(
      children: benefits.map((benefit) {
        return Container(
          margin: const EdgeInsets.only(bottom: 08),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(benefit['icon'] as IconData,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(benefit['title'] as String,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(benefit['subtitle'] as String,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _enableGuestMode() async {
    await AuthService.enableGuestMode();
    if (!_isAlive || !mounted) return;
    _safeSetState(() => _isGuestMode = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Mode invité activé'),
          backgroundColor: AppColors.success),
    );
  }

  Future<void> _showAuthScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
    if (!_isAlive || !mounted) return;

    if (result != null && result != 'guest') {
      await _loadUserData();
      if (!_isAlive || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: AppColors.success),
      );
    }
  }

  void _editProfile() {
    if (_currentUser == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(
        user: _currentUser!,
        onSave: (updatedUser) async {
          final result = await AuthService.updateUser(updatedUser);

          if (!dialogContext.mounted) return;
          Navigator.pop(dialogContext);

          if (!_isAlive || !mounted) return;

          if (result['success']) {
            _safeSetState(() => _currentUser = result['user']);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profil mis à jour avec succès'),
                  backgroundColor: AppColors.success),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(result['message']),
                  backgroundColor: AppColors.error),
            );
          }
        },
      ),
    );
  }

  void _showPersonalInfo() {
    if (_currentUser == null) {
      _showAuthScreen();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${_currentUser!.name}'),
            const SizedBox(height: 8),
            Text('Téléphone: ${_currentUser!.phone}'),
            if (_currentUser!.email != null) ...[
              const SizedBox(height: 8),
              Text('Email: ${_currentUser!.email}'),
            ],
            const SizedBox(height: 8),
            Text('Membre depuis: ${_formatDate(_currentUser!.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showChangePassword() {
    if (_currentUser == null) {
      _showAuthScreen();
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => _ChangePasswordDialog(
        onSuccess: () {
          if (_isAlive && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mot de passe modifié avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeliveryAddresses() {
    showDialog(
      context: context,
      builder: (context) => _DeliveryAddressesDialog(),
    );
  }

  void _showPaymentMethods() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Méthodes de paiement'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Méthodes disponibles :'),
            SizedBox(height: 8),
            Text('• Paiement en espèces'),
            SizedBox(height: 8),
            Text('• Orange Money'),
            SizedBox(height: 8),
            Text('• Moov Money (bientôt)'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showOrderHistory() {
    context.read<RestaurantProvider>().setNavIndex(3);
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => _NotificationSettingsDialog(),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide et support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pour toute assistance, contactez-nous :'),
            SizedBox(height: 12),
            Text('📞 +226 54 05 90 90'),
            SizedBox(height: 8),
            Text('📧 support@quickdev-it.com'),
            SizedBox(height: 8),
            Text('🕒 Lun-Dim: 9h00-22h30'),
            SizedBox(height: 12),
            Text(
                'Vous pouvez aussi nous écrire sur WhatsApp pour un support rapide.'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de NOOGO'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NOOGO v1.0.0'),
            SizedBox(height: 8),
            Text('Application de commande de repas'),
            SizedBox(height: 4),
            Text('• Commande avec ou sans compte'),
            SizedBox(height: 4),
            Text('• Suivi en temps réel'),
            SizedBox(height: 4),
            Text('• Paiement sécurisé'),
            SizedBox(height: 12),
            Text('© 2026 Quick dev-it. Tous droits réservés.'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showMyRestaurants() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyRestaurantsScreen()),
    );
  }

  void _changeRestaurant() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyRestaurantsScreen()),
      (route) => false,
    );
  }

  void _logout() {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // ✅ Fermer dialog d'abord
              await AuthService.logout();
              if (!_isAlive || !mounted) return;
              await _loadUserData();
              if (!_isAlive || !mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Déconnexion réussie'),
                    backgroundColor: AppColors.success),
              );
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  // ─── Utils ────────────────────────────────────────────────────────────────────

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── Dialog édition profil ────────────────────────────────────────────────────

class _EditProfileDialog extends StatefulWidget {
  final User user;
  final Function(User) onSave;

  const _EditProfileDialog({required this.user, required this.onSave});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le profil'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  (value?.isEmpty ?? true) ? 'Veuillez entrer votre nom' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => (value?.isEmpty ?? true)
                  ? 'Veuillez entrer votre numéro'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optionnel)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    widget.onSave(User(
      id: widget.user.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.isNotEmpty
          ? _emailController.text.trim()
          : null,
      createdAt: widget.user.createdAt,
    ));
  }
}

// ─── Dialog changement de mot de passe ────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _ChangePasswordDialog({required this.onSuccess});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le mot de passe'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) =>
                  (v?.isEmpty ?? true) ? 'Mot de passe requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) return 'Minimum 6 caractères';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock_clock),
              ),
              validator: (v) {
                if (v != _newController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Modifier'),
        ),
      ],
    );
  }
}

// ─── Dialog adresses de livraison ─────────────────────────────────────────────

class _DeliveryAddressesDialog extends StatefulWidget {
  @override
  State<_DeliveryAddressesDialog> createState() =>
      _DeliveryAddressesDialogState();
}

class _DeliveryAddressesDialogState extends State<_DeliveryAddressesDialog> {
  List<String> _addresses = [];
  final _newAddressController = TextEditingController();

  static const String _prefsKey = 'delivery_addresses';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _newAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    if (mounted) setState(() => _addresses = raw);
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _addresses);
  }

  void _addAddress() {
    final addr = _newAddressController.text.trim();
    if (addr.length < 5) return;
    setState(() => _addresses.add(addr));
    _newAddressController.clear();
    _saveAddresses();
  }

  void _removeAddress(int index) {
    setState(() => _addresses.removeAt(index));
    _saveAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adresses de livraison'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_addresses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Aucune adresse enregistrée',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...List.generate(_addresses.length, (i) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.location_on, color: AppColors.primary),
                  title:
                      Text(_addresses[i], style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    onPressed: () => _removeAddress(i),
                  ),
                );
              }),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newAddressController,
                    decoration: const InputDecoration(
                      hintText: 'Nouvelle adresse...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addAddress,
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

// ─── Dialog paramètres de notifications ───────────────────────────────────────

class _NotificationSettingsDialog extends StatefulWidget {
  @override
  State<_NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<_NotificationSettingsDialog> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _deliveryAlerts = true;

  static const String _prefsKey = 'notification_settings';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _orderUpdates = prefs.getBool('${_prefsKey}_orders') ?? true;
        _promotions = prefs.getBool('${_prefsKey}_promos') ?? true;
        _deliveryAlerts = prefs.getBool('${_prefsKey}_delivery') ?? true;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefsKey}_$key', value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paramètres de notifications'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Mises à jour commandes'),
            subtitle: const Text('Statut de vos commandes en temps réel'),
            value: _orderUpdates,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _orderUpdates = v);
              _saveSetting('orders', v);
            },
          ),
          SwitchListTile(
            title: const Text('Promotions'),
            subtitle: const Text('Offres et réductions'),
            value: _promotions,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _promotions = v);
              _saveSetting('promos', v);
            },
          ),
          SwitchListTile(
            title: const Text('Alertes livraison'),
            subtitle: const Text('Position du livreur et arrivée'),
            value: _deliveryAlerts,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _deliveryAlerts = v);
              _saveSetting('delivery', v);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
