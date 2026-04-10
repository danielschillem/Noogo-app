import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant.dart';
import '../services/restaurant_provider.dart';
import '../screens/qr_scanner_screen.dart';
import '../utils/app_colors.dart';

class ContactInfo extends StatefulWidget {
  final Restaurant restaurant;

  const ContactInfo({
    super.key,
    required this.restaurant,
  });

  @override
  State<ContactInfo> createState() => _ContactInfoState();
}

class _ContactInfoState extends State<ContactInfo> {
  bool _isValidating = false;

  Future<void> _makePhoneCall(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Numéro de téléphone invalide")),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("Impossible de lancer l'appel.")),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Erreur lors de l'appel : $e")),
      );
    }
  }

  Future<void> _proceedToScanner(BuildContext context) async {
    if (_isValidating) return;

    final provider = context.read<RestaurantProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (provider.hasCartItems) {
      provider.clearCart();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Panier vidé'),
          backgroundColor: AppColors.info,
        ),
      );
    }

    try {
      if (!mounted) return;

      final String? qrCode = await navigator.push<String>(
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );

      if (!mounted) return;

      if (qrCode == null || qrCode.trim().isEmpty) {
        _showErrorDialog(
          'QR code invalide',
          'Le QR code scanné est vide ou incorrect.',
        );
        return;
      }

      setState(() => _isValidating = true);

      // Loader dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Validation en cours...'),
            ],
          ),
        ),
      );

      // Validation QR
      await provider.validateRestaurantQRCode(qrCode).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout validation QR');
        },
      );

      // Charger restaurant
      final newRestaurant = provider.restaurant;
      if (newRestaurant == null) {
        throw Exception('Restaurant invalide');
      }

      await provider
          .loadAllInitialData(
        restaurantId: newRestaurant.id,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout chargement restaurant');
        },
      );

      if (!mounted) return;

      // Fermer loader
      if (navigator.canPop()) {
        navigator.pop();
      }

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Restaurant changé : ${newRestaurant.name}',
          ),
        ),
      );

      provider.setNavIndex(0);
    } catch (e) {
      if (!mounted) return;

      if (navigator.canPop()) {
        navigator.pop();
      }

      _showErrorDialog(
        'Erreur',
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (!mounted) return;
                _openQRScanner(this.context);
              });
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _openQRScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scanner un nouveau QR code'),
        content: const Text(
          'Votre panier sera vidé après ce scan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToScanner(context);
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.restaurant.isOpen ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOpen
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOpen ? 'Ouvert' : 'Fermé',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _isValidating ? null : () => _openQRScanner(context),
                  child: AnimatedOpacity(
                    opacity: _isValidating ? 0.5 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 26,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.restaurant.phone)),
                GestureDetector(
                  onTap: () => _makePhoneCall(context, widget.restaurant.phone),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Appeler',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
