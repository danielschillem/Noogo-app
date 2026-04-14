import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order.dart';
import '../screens/payment_screen.dart';
import '../services/payment_service.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<CartScreen> {
  @override
  bool get wantKeepAlive => true;
  late AnimationController _animationController;

  // Controllers pour le flux de paiement
  final _tableNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _mobileMoneyNumberController = TextEditingController();

  // Form keys pour validation inline
  final _phoneFormKey = GlobalKey<FormState>();
  final _mobileMoneyFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RestaurantProvider>();
      debugPrint(
          'CartScreen initState: ${provider.cartItems.length} articles dans le panier');
      provider.debugPrintState();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tableNumberController.dispose();
    _phoneNumberController.dispose();
    _mobileMoneyNumberController.dispose();
    super.dispose();
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
        title: 'Panier',
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: provider.cartItems.isEmpty
                ? _buildEmptyCart(key: const ValueKey('empty'))
                : _buildCartContent(provider, key: const ValueKey('content')),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart({Key? key}) {
    return Container(
      key: key,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Votre panier est vide', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des plats depuis le menu pour commencer votre commande',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                final provider = context.read<RestaurantProvider>();
                provider.setNavIndex(1);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              label: const Text('Voir le menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(RestaurantProvider provider, {Key? key}) {
    return Container(
      key: key,
      child: Column(
        children: [
          _buildCartHeader(provider),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await provider.refreshAllData(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: provider.cartItems.length,
                itemBuilder: (context, index) {
                  final item = provider.cartItems[index];
                  return _buildCartItem(item, provider);
                },
              ),
            ),
          ),
          _buildOrderSummary(provider),
        ],
      ),
    );
  }

  Widget _buildCartHeader(RestaurantProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Mon Panier', style: AppTextStyles.heading1),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${provider.cartItemsCount} Plats${provider.cartItemsCount > 1 ? 's' : ''}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) {
              if (value == 'clear') _confirmClearCart(provider);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Vider le panier'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(OrderItem item, RestaurantProvider provider) {
    return Container(
      key: ValueKey('cart_item_${item.dish.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: Key('dismissible_${item.dish.id}_${item.quantity}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 32),
        ),
        confirmDismiss: (direction) => _confirmRemoveItem(item),
        onDismissed: (direction) => _removeItemFromCart(provider, item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDishImage(item),
              const SizedBox(width: 16),
              Expanded(child: _buildDishInfo(item)),
              _buildQuantityControls(item, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDishImage(OrderItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: _buildImage(
          item.dish.imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDishInfo(OrderItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.dish.name,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${item.dish.price.toStringAsFixed(0)} FCFA / plat',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Total: ${(item.dish.price * item.quantity).toStringAsFixed(0)} FCFA',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls(OrderItem item, RestaurantProvider provider) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: () => _decreaseQuantity(provider, item),
                backgroundColor: item.quantity > 1
                    ? AppColors.primary
                    : AppColors.error.withValues(alpha: 0.7),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: () => _increaseQuantity(provider, item),
                backgroundColor: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _confirmRemoveItem(item).then((confirmed) {
            if (confirmed == true) _removeItemFromCart(provider, item);
          }),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(RestaurantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCostSummary(provider.cartTotal, 0.0),
            const SizedBox(height: 20),
            _buildOrderButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummary(double subtotal, double deliveryFee) {
    final total = subtotal + deliveryFee;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Sous-total', style: AppTextStyles.bodyMedium),
            Text(
              '${subtotal.toStringAsFixed(0)} FCFA',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Frais de livraison', style: AppTextStyles.bodyMedium),
            Text(
              'A partir de 1000 f',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: AppTextStyles.heading3),
            Text(
              '${total.toStringAsFixed(0)} FCFA',
              style: AppTextStyles.price.copyWith(fontSize: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderButton(RestaurantProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : () => _placeOrder(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: provider.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Commander • ${provider.cartTotal.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.button.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _increaseQuantity(RestaurantProvider provider, OrderItem item) {
    provider.updateCartItemQuantity(item.dish, item.quantity + 1);
  }

  void _decreaseQuantity(RestaurantProvider provider, OrderItem item) {
    if (item.quantity > 1) {
      provider.updateCartItemQuantity(item.dish, item.quantity - 1);
    }
  }

  void _removeItemFromCart(RestaurantProvider provider, OrderItem item) {
    provider.removeFromCart(item.dish);
    _showSnackBar('${item.dish.name} retiré du panier', isError: true);
  }

  Future<bool?> _confirmRemoveItem(OrderItem item) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer du panier'),
        content:
            Text('Voulez-vous vraiment retirer ${item.dish.name} du panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textLight,
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(RestaurantProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Voulez-vous vraiment vider tout le panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearCart();
              Navigator.pop(context);
              _showSnackBar('Panier vidé', isError: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textLight,
            ),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // NOUVEAU FLUX DE COMMANDE INTÉGRÉ
  // ============================================

  void _placeOrder(RestaurantProvider provider) async {
    if (provider.cartItems.isEmpty) {
      _showSnackBar(
        'Votre panier est vide. Ajoutez des plats avant de commander.',
        isError: true,
      );
      return;
    }

    // Étape 1: Choisir le type de commande (sur place ou à emporter)
    final orderType = await _askOrderType();
    if (orderType == null) return;

    String? tableNumber;

    // Étape 2: Si "sur place", demander le numéro de table
    if (orderType == 'sur place') {
      tableNumber = await _askTableNumber();
      if (tableNumber == null) return;
    }

    // Étape 3: Demander le numéro de téléphone
    final phoneNumber = await _askPhoneNumber();
    if (phoneNumber == null) return;

    // Étape 4: Demander le mode de paiement
    final paymentMethod = await _askPaymentMethod();
    if (paymentMethod == null) return;

    String? mobileMoneyProvider;

    // Étape 5: Si Mobile Money, choisir le fournisseur
    if (paymentMethod == 'mobile_money') {
      mobileMoneyProvider = await _askMobileMoneyProvider();
      if (mobileMoneyProvider == null) return;

      // Étape 5.1: Demander le numéro Mobile Money
      final mobileMoneyNumber =
          await _askMobileMoneyNumber(mobileMoneyProvider);
      if (mobileMoneyNumber == null) return;

      // Étape 5.2: Paiement Mobile Money via PaymentScreen
      final otpConfirmed = await _processOTPPayment(
        mobileMoneyProvider: mobileMoneyProvider,
        phoneNumber: mobileMoneyNumber,
        amount: provider.cartTotal,
        provider: provider,
      );
      if (otpConfirmed != true) return;
    }

    // Étape 6: Confirmation finale
    final confirmed = await _confirmOrder(
      orderType: orderType,
      tableNumber: tableNumber,
      phoneNumber: phoneNumber,
      paymentMethod: paymentMethod,
      mobileMoneyProvider: mobileMoneyProvider,
      total: provider.cartTotal,
    );

    if (confirmed != true) return;

    // Étape 7: Soumettre la commande
    await _submitOrderToServer(
      provider: provider,
      orderType: orderType,
      tableNumber: tableNumber,
      phoneNumber: phoneNumber,
      paymentMethod: paymentMethod,
      mobileMoneyProvider: mobileMoneyProvider,
    );
  }

  // Étape 1: Choisir le type de commande
  Future<String?> _askOrderType() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            SizedBox(width: 8),
            Text('Type de commande'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOrderTypeOption(
              'Sur place',
              Icons.table_restaurant,
              'Manger au restaurant',
              AppColors.primary,
              () => Navigator.pop(context, 'sur place'),
            ),
            const SizedBox(height: 12),
            _buildOrderTypeOption(
              'À emporter',
              Icons.shopping_bag,
              'Emporter votre commande',
              AppColors.secondary,
              () => Navigator.pop(context, 'a emporter'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeOption(
    String title,
    IconData icon,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // Étape 2: Demander le numéro de table (si sur place)
  Future<String?> _askTableNumber() async {
    _tableNumberController.clear();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_restaurant, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Numéro de table'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Veuillez saisir votre numéro de table',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tableNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de table',
                hintText: 'Ex: 12 ou A5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () {
              final tableNumber = _tableNumberController.text.trim();
              final isValid =
                  RegExp(r'^[A-Za-z0-9\-]{1,10}$').hasMatch(tableNumber);
              if (isValid) {
                Navigator.pop(context, tableNumber.toUpperCase());
              } else if (tableNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un numéro de table'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Numéro invalide (ex: 12, A5 — max 10 caractères)'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  // Étape 3: Demander le numéro de téléphone
  Future<String?> _askPhoneNumber() async {
    _phoneNumberController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Numéro de téléphone'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pour vous contacter si nécessaire',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Form(
              key: _phoneFormKey,
              child: TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: 'Ex: 70123456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                autofocus: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Entrez votre numéro de téléphone';
                  }
                  final cleaned = value.replaceAll(RegExp(r'[\s\-\.]'), '');
                  if (!RegExp(r'^(?:\+?226|00226)?[0-9]{8}$')
                      .hasMatch(cleaned)) {
                    return 'Numéro invalide (ex: 70 12 34 56)';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_phoneFormKey.currentState!.validate()) {
                Navigator.pop(context, _phoneNumberController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  // Étape 4: Choisir le mode de paiement
  Future<String?> _askPaymentMethod() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Mode de paiement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentMethodOption(
              'Mobile Money',
              Icons.phone_android,
              Colors.orange,
              () => Navigator.pop(context, 'mobile_money'),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodOption(
              'Espèces',
              Icons.money,
              Colors.green,
              () => Navigator.pop(context, 'cash'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style:
                  AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // Étape 5: Choisir le fournisseur Mobile Money
  Future<String?> _askMobileMoneyProvider() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Choisissez votre opérateur'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMobileMoneyProviderOption(
              'Orange Money',
              Colors.orange,
              () => Navigator.pop(context, 'orange'),
            ),
            const SizedBox(height: 12),
            _buildMobileMoneyProviderOption(
              'Moov Africa',
              Colors.blue,
              () => Navigator.pop(context, 'moov'),
            ),
            /*const SizedBox(height: 12),
            _buildMobileMoneyProviderOption(
              'Telecel Money',
              Colors.red,
                  () => Navigator.pop(context, 'telecel'),
            ),*/
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMoneyProviderOption(
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_android, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // Étape 5.1: Demander le numéro Mobile Money
  Future<String?> _askMobileMoneyNumber(String provider) async {
    _mobileMoneyNumberController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone_android, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Numéro ${provider.toUpperCase()}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez le numéro qui recevra la demande de paiement',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Form(
              key: _mobileMoneyFormKey,
              child: TextFormField(
                controller: _mobileMoneyNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numéro Mobile Money',
                  hintText: 'Ex: 70123456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  helperText: 'Le code OTP sera envoyé à ce numéro',
                ),
                keyboardType: TextInputType.phone,
                autofocus: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Entrez votre numéro Mobile Money';
                  }
                  final cleaned = value.replaceAll(RegExp(r'[\s\-\.]'), '');
                  if (!RegExp(r'^(?:\+?226|00226)?[0-9]{8}$')
                      .hasMatch(cleaned)) {
                    return 'Numéro invalide (ex: 70 12 34 56)';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_mobileMoneyFormKey.currentState!.validate()) {
                Navigator.pop(
                    context, _mobileMoneyNumberController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  // Étape 5.2: Processus de paiement OTP — navigue vers PaymentScreen
  Future<bool?> _processOTPPayment({
    required String mobileMoneyProvider,
    required String phoneNumber,
    required double amount,
    required RestaurantProvider provider,
  }) async {
    final restaurantId = provider.restaurant?.id;
    if (restaurantId == null) {
      _showSnackBar('Restaurant non identifié. Veuillez rescanner le QR code.',
          isError: true);
      return false;
    }

    final result = await Navigator.of(context).push<PaymentRecord?>(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          restaurantId: restaurantId,
          provider: mobileMoneyProvider,
          phone: phoneNumber,
          amount: amount.toInt(),
        ),
      ),
    );

    return result != null && result.status.isCompleted;
  }

  // Étape 6: Confirmation finale
  Future<bool?> _confirmOrder({
    required String orderType,
    String? tableNumber,
    required String phoneNumber,
    required String paymentMethod,
    String? mobileMoneyProvider,
    required double total,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la commande'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmationRow(
                  'Type',
                  orderType == 'sur place'
                      ? 'Sur place'
                      : orderType == 'à emporter'
                          ? 'À emporter'
                          : 'Livraison'),
              if (tableNumber != null)
                _buildConfirmationRow('Table', tableNumber),
              _buildConfirmationRow('Téléphone', phoneNumber),
              _buildConfirmationRow(
                'Paiement',
                paymentMethod == 'cash'
                    ? 'Espèces'
                    : 'Mobile Money${mobileMoneyProvider != null ? ' ($mobileMoneyProvider)' : ''}',
              ),
              const Divider(height: 24),
              _buildConfirmationRow('Total', '${total.toStringAsFixed(0)} FCFA',
                  isTotal: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Modifier'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Étape 7: Soumettre la commande au serveur
  Future<void> _submitOrderToServer({
    required RestaurantProvider provider,
    required String orderType,
    String? tableNumber,
    required String phoneNumber,
    required String paymentMethod,
    String? mobileMoneyProvider,
  }) async {
    // Afficher l'indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Envoi de votre commande...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final orderId = await provider.submitOrder(
        orderType: orderType,
        paymentMethod: paymentMethod,
        phoneNumber: phoneNumber,
        tableNumber: tableNumber,
        mobileMoneyProvider: mobileMoneyProvider,
      );

      if (!mounted) return;

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      if (orderId != null) {
        // Afficher le dialogue de succès
        await _showSuccessDialog(orderType, tableNumber, paymentMethod);

        // NE PAS vider le panier ici - il est déjà vidé dans submitOrder
        // Rediriger vers les commandes
        if (mounted) {
          provider.setNavIndex(3); // Index de OrdersScreen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        // Si orderId est null, c'est qu'il y a eu une erreur
        _showSnackBar(
          'Erreur lors de l\'envoi de la commande. Veuillez réessayer.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Afficher l'erreur avec plus de détails
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(
        'Erreur: $errorMessage',
        isError: true,
      );

      debugPrint('Erreur lors de la soumission de la commande: $e');
    }
  }

  // Dialog de succès
  Future<void> _showSuccessDialog(
    String orderType,
    String? tableNumber,
    String paymentMethod,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Commande confirmée !',
                style:
                    AppTextStyles.heading2.copyWith(color: AppColors.success),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildOrderDetailRow('Type',
                        orderType == 'sur place' ? 'Sur place' : 'À emporter'),
                    if (tableNumber != null) ...[
                      const Divider(height: 16),
                      _buildOrderDetailRow('Table', tableNumber),
                    ],
                    const Divider(height: 16),
                    _buildOrderDetailRow('Paiement',
                        paymentMethod == 'cash' ? 'Espèces' : 'Mobile Money'),
                    const Divider(height: 16),
                    _buildOrderDetailRow('Statut', 'En préparation'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                orderType == 'sur place'
                    ? 'Votre commande sera livrée à votre table dans quelques instants.'
                    : 'Vous serez notifié quand votre commande sera prête.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Voir mes commandes'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Retour à l'accueil
                      final provider = context.read<RestaurantProvider>();
                      provider.setNavIndex(0);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Retour à l\'accueil'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
