import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../models/oral_order_note.dart';
import '../services/waiter_api_service.dart';
import '../services/waiter_provider.dart';

/// Bloc note des commandes prises à l’oral (catégories + coches + validation + envoi cuisine).
class WaiterOralNotesScreen extends StatefulWidget {
  const WaiterOralNotesScreen({super.key});

  @override
  State<WaiterOralNotesScreen> createState() => _WaiterOralNotesScreenState();
}

class _WaiterOralNotesScreenState extends State<WaiterOralNotesScreen> {
  String _listFilter = 'draft'; // draft | validated | all
  List<OralOrderNote> _notes = [];
  bool _loadingList = false;
  String? _listError;

  OralOrderNote? _editing;
  final _titleCtrl = TextEditingController();
  final _staffCtrl = TextEditingController();
  Map<int, int> _picks = {};
  List<Map<String, dynamic>> _menuCategories = [];
  int _menuCatIndex = 0;
  bool _loadingMenu = false;
  bool _busy = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _staffCtrl.dispose();
    super.dispose();
  }

  int? get _rid => context.read<WaiterProvider>().restaurantId;

  Future<void> _loadList() async {
    final rid = _rid;
    if (rid == null) return;
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    try {
      final status = _listFilter == 'all' ? null : _listFilter;
      _notes = await WaiterApiService.instance.listOralOrderNotes(rid, status: status);
    } catch (e) {
      _listError = e.toString();
    }
    setState(() => _loadingList = false);
  }

  Future<void> _loadMenu() async {
    final rid = _rid;
    if (rid == null) return;
    setState(() => _loadingMenu = true);
    try {
      _menuCategories = await WaiterApiService.instance.getMenu(rid);
      if (_menuCatIndex >= _menuCategories.length) {
        _menuCatIndex = 0;
      }
    } catch (_) {
      _menuCategories = [];
    }
    setState(() => _loadingMenu = false);
  }

  Future<void> _openEditor(OralOrderNote? seed) async {
    final rid = _rid;
    if (rid == null) return;
    setState(() => _busy = true);
    try {
      OralOrderNote note;
      if (seed == null) {
        note = await WaiterApiService.instance.createOralOrderNote(rid);
        await _loadList();
      } else {
        note = await WaiterApiService.instance.getOralOrderNote(rid, seed.id);
      }
      _applyNoteToForm(note);
      setState(() => _editing = note);
      if (note.isDraft) await _loadMenu();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _busy = false);
  }

  void _applyNoteToForm(OralOrderNote note) {
    _titleCtrl.text = note.title ?? '';
    _staffCtrl.text = note.staffComment ?? '';
    final m = <int, int>{};
    for (final it in note.items) {
      if (it.dishId != null) m[it.dishId!] = it.quantity;
    }
    _picks = m;
  }

  void _closeEditor() {
    setState(() {
      _editing = null;
      _picks = {};
      _titleCtrl.clear();
      _staffCtrl.clear();
    });
    _loadList();
  }

  List<Map<String, dynamic>> get _currentDishes {
    if (_menuCategories.isEmpty) return [];
    final cat = _menuCategories[_menuCatIndex.clamp(0, _menuCategories.length - 1)];
    final plats = cat['plats'] as List? ?? [];
    return plats.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> _persistDraft() async {
    final rid = _rid;
    final note = _editing;
    if (rid == null || note == null || !note.isDraft) return;
    if (_picks.isEmpty) {
      throw Exception('empty');
    }
    final items = _picks.entries
        .map((e) => {'dish_id': e.key, 'quantity': e.value})
        .toList();
    final updated = await WaiterApiService.instance.updateOralOrderNote(
      rid,
      note.id,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      staffComment:
          _staffCtrl.text.trim().isEmpty ? null : _staffCtrl.text.trim(),
      items: items,
    );
    setState(() => _editing = updated);
  }

  Future<void> _saveDraft() async {
    final rid = _rid;
    final note = _editing;
    if (rid == null || note == null || !note.isDraft) return;
    if (_picks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cochez au moins un plat')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _persistDraft();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note enregistrée')),
        );
      }
    } catch (e) {
      if (mounted && e.toString() != 'Exception: empty') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _busy = false);
  }

  Future<void> _validate() async {
    final rid = _rid;
    final note = _editing;
    if (rid == null || note == null || !note.isDraft) return;
    if (_picks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cochez au moins un plat avant de valider')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      try {
        await _persistDraft();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
          );
        }
        setState(() => _busy = false);
        return;
      }
      final n = _editing;
      if (n == null || !n.isDraft) {
        setState(() => _busy = false);
        return;
      }
      final validated =
          await WaiterApiService.instance.validateOralOrderNote(rid, n.id);
      setState(() => _editing = validated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note validée — vous pouvez l’envoyer en cuisine'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _busy = false);
  }

  Future<void> _confirmDelete() async {
    final rid = _rid;
    final note = _editing;
    if (rid == null || note == null || !note.isDraft) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce brouillon ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await WaiterApiService.instance.deleteOralOrderNote(rid, note.id);
      _closeEditor();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _busy = false);
  }

  Future<void> _showConvertDialog() async {
    final rid = _rid;
    final note = _editing;
    if (rid == null || note == null || !note.isValidated || note.isConverted) {
      return;
    }

    final form = await showDialog<_ConvertFormValues>(
      context: context,
      builder: (ctx) => const _ConvertToOrderDialog(),
    );

    if (form == null || !mounted) return;

    final waiter = context.read<WaiterProvider>();
    setState(() => _busy = true);
    try {
      final result = await WaiterApiService.instance.convertOralOrderNoteToOrder(
        rid,
        note.id,
        orderType: form.orderType,
        paymentMethod: form.paymentMethod.trim().isEmpty ? 'cash' : form.paymentMethod.trim(),
        tableNumber: _trimOrNull(form.tableNumber),
        customerName: _trimOrNull(form.customerName),
        customerPhone: _trimOrNull(form.customerPhone),
        notes: _trimOrNull(form.notes),
      );
      setState(() => _editing = result.note);
      await waiter.loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande n°${result.orderId} créée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _busy = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadList());
  }

  @override
  Widget build(BuildContext context) {
    if (_editing != null) {
      return _buildEditorScaffold();
    }
    return _buildListScaffold();
  }

  Widget _buildListScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Commandes orales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadingList ? null : _loadList,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Brouillons',
                  selected: _listFilter == 'draft',
                  onTap: () {
                    setState(() => _listFilter = 'draft');
                    _loadList();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Validées',
                  selected: _listFilter == 'validated',
                  onTap: () {
                    setState(() => _listFilter = 'validated');
                    _loadList();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tout',
                  selected: _listFilter == 'all',
                  onTap: () {
                    setState(() => _listFilter = 'all');
                    _loadList();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingList
                ? const Center(child: CircularProgressIndicator())
                : _listError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_listError!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _loadList,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _notes.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune note — utilisez le bouton +',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _notes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final n = _notes[i];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: ListTile(
                                  title: Text(
                                    '#${n.id} ${n.title != null && n.title!.isNotEmpty ? '· ${n.title}' : ''}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${n.status == 'draft' ? 'Brouillon' : 'Validée'}'
                                    '${n.convertedOrderId != null ? ' · Cmd #${n.convertedOrderId}' : ''}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _busy ? null : () => _openEditor(n),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _openEditor(null),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle prise'),
      ),
    );
  }

  Widget _buildEditorScaffold() {
    final note = _editing!;
    final isDraft = note.isDraft;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : _closeEditor,
        ),
        title: Text('Note #${note.id}'),
        actions: [
          if (isDraft)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _confirmDelete,
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!isDraft && note.isConverted)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    'Déjà convertie en commande n°${note.convertedOrderId}.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                  ),
                ),
              TextField(
                controller: _titleCtrl,
                enabled: isDraft && !_busy,
                decoration: const InputDecoration(
                  labelText: 'Titre (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _staffCtrl,
                enabled: isDraft && !_busy,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Commentaire cuisine',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (!isDraft) ...[
                const Text(
                  'Articles validés (snapshots)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...note.items.map(
                  (it) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${it.dishNomSnapshot} × ${it.quantity}')),
                        Text('${it.unitPriceSnapshot} F/u'),
                      ],
                    ),
                  ),
                ),
                if (note.isValidated && !note.isConverted) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _showConvertDialog,
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Envoyer en cuisine'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                const Text(
                  'Carte',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_loadingMenu)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_menuCategories.isEmpty)
                  const Text('Menu indisponible', style: TextStyle(color: AppColors.textSecondary))
                else ...[
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _menuCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = _menuCategories[i];
                        final name = cat['categorie_nom']?.toString() ?? '—';
                        final sel = i == _menuCatIndex;
                        return ChoiceChip(
                          label: Text(name, overflow: TextOverflow.ellipsis),
                          selected: sel,
                          onSelected: (_) => setState(() => _menuCatIndex = i),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._currentDishes.map((dish) {
                    final id = dish['id'] as int;
                    final nom = dish['nom']?.toString() ?? '';
                    final prix = dish['prix']?.toString() ?? '';
                    final dispo = dish['disponibilite'] != false;
                    final q = _picks[id] ?? 0;
                    return CheckboxListTile(
                      value: q > 0,
                      onChanged: dispo && !_busy
                          ? (v) {
                              setState(() {
                                if (v == true) {
                                  _picks[id] = 1;
                                } else {
                                  _picks.remove(id);
                                }
                              });
                            }
                          : null,
                      title: Text(nom, style: TextStyle(color: dispo ? null : Colors.grey)),
                      subtitle: Text(
                        dispo ? '$prix FCFA' : 'Indisponible',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: q > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: !_busy
                                      ? () => setState(() {
                                            if (q <= 1) {
                                              _picks.remove(id);
                                            } else {
                                              _picks[id] = q - 1;
                                            }
                                          })
                                      : null,
                                ),
                                Text('$q', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: !_busy
                                      ? () => setState(() => _picks[id] = (q + 1).clamp(1, 999))
                                      : null,
                                ),
                              ],
                            )
                          : null,
                    );
                  }),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _saveDraft,
                        child: const Text('Enregistrer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _validate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Valider'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Colors.black12,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

String? _trimOrNull(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

class _ConvertFormValues {
  _ConvertFormValues({
    required this.orderType,
    required this.paymentMethod,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.notes,
  });

  final String orderType;
  final String paymentMethod;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
}

class _ConvertToOrderDialog extends StatefulWidget {
  const _ConvertToOrderDialog();

  @override
  State<_ConvertToOrderDialog> createState() => _ConvertToOrderDialogState();
}

class _ConvertToOrderDialogState extends State<_ConvertToOrderDialog> {
  String _orderType = 'sur_place';
  final _payment = TextEditingController(text: 'cash');
  final _table = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _payment.dispose();
    _table.dispose();
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Envoyer en cuisine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crée une commande en attente avec les plats de cette note.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sur_place', label: Text('Sur place')),
                ButtonSegment(value: 'a_emporter', label: Text('À emporter')),
                ButtonSegment(value: 'livraison', label: Text('Livraison')),
              ],
              selected: {_orderType},
              onSelectionChanged: (Set<String> sel) {
                if (sel.isEmpty) return;
                setState(() => _orderType = sel.first);
              },
            ),
            TextField(
              controller: _payment,
              decoration: const InputDecoration(labelText: 'Paiement'),
            ),
            TextField(
              controller: _table,
              decoration: const InputDecoration(labelText: 'Table (optionnel)'),
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Client (optionnel)'),
            ),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
            ),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes commande (optionnel)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _ConvertFormValues(
                orderType: _orderType,
                paymentMethod: _payment.text,
                tableNumber: _table.text,
                customerName: _name.text,
                customerPhone: _phone.text,
                notes: _notes.text,
              ),
            );
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1976D2) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
