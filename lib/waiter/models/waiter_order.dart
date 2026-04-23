class WaiterOrderItem {
  final int id;
  final String nom;
  final int quantity;
  final double price;
  final String? notes;

  const WaiterOrderItem({
    required this.id,
    required this.nom,
    required this.quantity,
    required this.price,
    this.notes,
  });

  factory WaiterOrderItem.fromJson(Map<String, dynamic> json) {
    return WaiterOrderItem(
      id: json['id'] as int,
      nom: json['nom']?.toString() ?? json['plat_nom']?.toString() ?? '',
      quantity: json['quantite'] as int? ?? json['quantity'] as int? ?? 1,
      price: double.tryParse(json['prix']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString(),
    );
  }

  double get subtotal => price * quantity;
}

class WaiterOrder {
  final int id;
  final String status;
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<WaiterOrderItem> items;

  const WaiterOrder({
    required this.id,
    required this.status,
    required this.orderType,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory WaiterOrder.fromJson(Map<String, dynamic> json) {
    final itemsList =
        json['items'] as List? ?? json['commande_items'] as List? ?? [];
    return WaiterOrder(
      id: json['id'] as int,
      status: json['status']?.toString() ?? 'pending',
      orderType: json['order_type']?.toString() ?? 'sur_place',
      tableNumber: json['table_number']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      items: itemsList
          .map((e) => WaiterOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ─── Status helpers ────────────────────────────────────────────────────────

  static const Map<String, String> statusLabels = {
    'pending': 'En attente',
    'confirmed': 'Confirmée',
    'preparing': 'En préparation',
    'ready': 'Prête',
    'delivered': 'Servie',
    'completed': 'Terminée',
    'cancelled': 'Annulée',
  };

  static const Map<String, String> orderTypeLabels = {
    'sur_place': 'Sur place',
    'a_emporter': 'À emporter',
    'livraison': 'Livraison',
  };

  String get statusLabel => statusLabels[status] ?? status;
  String get orderTypeLabel => orderTypeLabels[orderType] ?? orderType;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isActive =>
      ['pending', 'confirmed', 'preparing', 'ready'].contains(status);
  bool get isClosed => ['delivered', 'completed', 'cancelled'].contains(status);

  /// Next actionable status for the waiter
  String? get nextStatus {
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'preparing';
      case 'ready':
        return 'delivered';
      default:
        return null;
    }
  }

  String? get nextStatusLabel {
    switch (nextStatus) {
      case 'confirmed':
        return 'Confirmer';
      case 'preparing':
        return 'Envoyer en cuisine';
      case 'delivered':
        return 'Marquer servie';
      default:
        return null;
    }
  }

  String get tableDisplay =>
      tableNumber != null ? 'Table $tableNumber' : orderTypeLabel;

  WaiterOrder copyWith({String? status}) {
    return WaiterOrder(
      id: id,
      status: status ?? this.status,
      orderType: orderType,
      tableNumber: tableNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      totalAmount: totalAmount,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items,
    );
  }
}
