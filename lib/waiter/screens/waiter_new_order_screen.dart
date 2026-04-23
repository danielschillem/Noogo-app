import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../services/waiter_api_service.dart';
import '../services/waiter_provider.dart';

class WaiterNewOrderScreen extends StatefulWidget {
  const WaiterNewOrderScreen({super.key});

  @override
  State<WaiterNewOrderScreen> createState() => _WaiterNewOrderScreenState();
}

class _WaiterNewOrderScreenState extends State<WaiterNewOrderScreen> {
  final _tableCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _orderType = 'sur_place';
  bool _isLoadingMenu = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _categories = [];
  String? _menuError;

  // Cart: dishId → {nom, prix, quantity}
  final Map<int, Map<String, dynamic>> _cart = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMenu());
  }

  @override
  void dispose() {
    _tableCtrl.dispose();
    _customerCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    final restaurantId = context.read<WaiterProvider>().restaurantId;
    if (restaurantId == null) return;
    setState(() {
      _isLoadingMenu = true;
      _menuError = null;
    });
    try {
      final cats = await WaiterApiService.instance.getMenu(restaurantId);
      setState(() => _categories = cats);
    } catch (e) {
      setState(() => _menuError = 'Impossible de charger le menu');
    } finally {
      setState(() => _isLoadingMenu = false);
    }
  }

  void _increment(Map<String, dynamic> dish) {
    final id = dish['id'] as int;
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id]!['quantity']++;
      } else {
        _cart[id] = {
          'id': id,
          'nom': dish['nom'],
          'prix': double.tryParse(dish['prix']?.toString() ?? '0') ?? 0.0,
          'quantity': 1,
        };
      }
    });
  }

  void _decrement(int dishId) {
    setState(() {
      if (_cart.containsKey(dishId)) {
        if (_cart[dishId]!['quantity'] > 1) {
          _cart[dishId]!['quantity']--;
        } else {
          _cart.remove(dishId);
        }
      }
    });
  }

  int _qty(int dishId) => _cart[dishId]?['quantity'] as int? ?? 0;

  double get _total {
    double t = 0;
    for (final item in _cart.values) {
      t += (item['prix'] as double) * (item['quantity'] as int);
    }
    return t;
  }

  int get _itemCount {
    int c = 0;
    for (final item in _cart.values) {
      c += item['quantity'] as int;
    }
    return c;
  }

  Future<void> _submit() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un article')),
      );
      return;
    }

    // Validate table number for sur_place
    if (_orderType == 'sur_place' && _tableCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Numéro de table requis pour une commande sur place')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la commande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_orderType == 'sur_place' && _tableCtrl.text.isNotEmpty)
              Text('Table: ${_tableCtrl.text}'),
            Text('Articles: $_itemCount'),
            Text(
              'Total: ${_total.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);

    final items = _cart.values
        .map((e) => {
              'plat_id': e['id'],
              'quantite': e['quantity'],
            })
        .toList();

    final provider = context.read<WaiterProvider>();
    final created = await provider.createOrder(
      items: items,
      orderType: _orderType,
      tableNumber:
          _tableCtrl.text.trim().isEmpty ? null : _tableCtrl.text.trim(),
      customerName:
          _customerCtrl.text.trim().isEmpty ? null : _customerCtrl.text.trim(),
      customerPhone:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (created != null && mounted) {
      _cart.clear();
      _tableCtrl.clear();
      _customerCtrl.clear();
      _phoneCtrl.clear();
      _notesCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande #${created.id} créée !'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle commande'),
        actions: [
          if (_itemCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Badge(
                label: Text('$_itemCount'),
                child: IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: _showCartSummary,
                  tooltip: 'Panier',
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingMenu
          ? const Center(child: CircularProgressIndicator())
          : _menuError != null
              ? _ErrorView(message: _menuError!, onRetry: _loadMenu)
              : Column(
                  children: [
                    // Order config header
                    _buildOrderConfig(),
                    const Divider(height: 1),
                    // Menu
                    Expanded(child: _buildMenu()),
                    // Cart bar
                    if (_itemCount > 0) _buildCartBar(),
                  ],
                ),
    );
  }

  Widget _buildOrderConfig() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order type
          Row(
            children: [
              _TypeChip(
                label: 'Sur place',
                icon: Icons.table_restaurant,
                selected: _orderType == 'sur_place',
                onTap: () => setState(() => _orderType = 'sur_place'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'À emporter',
                icon: Icons.takeout_dining,
                selected: _orderType == 'a_emporter',
                onTap: () => setState(() => _orderType = 'a_emporter'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Table number (sur_place only)
          if (_orderType == 'sur_place')
            TextField(
              controller: _tableCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Numéro de table *',
                prefixIcon: const Icon(Icons.table_restaurant),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          if (_orderType == 'a_emporter') ...[
            TextField(
              controller: _customerCtrl,
              decoration: InputDecoration(
                labelText: 'Nom du client (optionnel)',
                prefixIcon: const Icon(Icons.person_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Téléphone (optionnel)',
                prefixIcon: const Icon(Icons.phone_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: 'Notes (optionnel)',
              prefixIcon: const Icon(Icons.notes_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    if (_categories.isEmpty) {
      return const Center(
        child:
            Text('Menu vide', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, ci) {
        final cat = _categories[ci];
        final catName = cat['categorie_nom']?.toString() ?? 'Catégorie';
        final dishes = cat['plats'] as List? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                catName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textSecondary),
              ),
            ),
            ...dishes.map((dish) => _DishRow(
                  dish: dish as Map<String, dynamic>,
                  qty: _qty(dish['id'] as int),
                  onIncrement: () => _increment(dish),
                  onDecrement: () => _decrement(dish['id'] as int),
                )),
          ],
        );
      },
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_itemCount art.',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Color(0xFF1976D2), strokeWidth: 2))
                  : const Text('Commander',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSummary() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Récapitulatif',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ..._cart.values.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${item['quantity']}×',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item['nom'])),
                      Text(
                          '${((item['prix'] as double) * (item['quantity'] as int)).toStringAsFixed(0)} F'),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_total.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dish Row ──────────────────────────────────────────────────────────────────

class _DishRow extends StatelessWidget {
  final Map<String, dynamic> dish;
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _DishRow({
    required this.dish,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = dish['is_available'] != false;
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(dish['nom']?.toString() ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${dish['prix']} FCFA',
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500),
        ),
        trailing: isAvailable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (qty > 0) ...[
                    _CircleBtn(
                      icon: Icons.remove,
                      color: AppColors.textSecondary,
                      onTap: onDecrement,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('$qty',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primary)),
                    ),
                  ],
                  _CircleBtn(
                    icon: Icons.add,
                    color: const Color(0xFF1976D2),
                    onTap: onIncrement,
                  ),
                ],
              )
            : const Text('Indisponible',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─── Type Chip ────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1976D2)
              : AppColors.dividerColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
