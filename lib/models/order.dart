import 'dish.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled,
  completed,
}

enum OrderType {
  surPlace,
  aEmporter,
  livraison,
}

class OrderItem {
  final Dish dish;
  int quantity;

  OrderItem({
    required this.dish,
    required this.quantity,
  });

  double get totalPrice => dish.price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dish: Dish.fromJson(json['dish']),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dish': dish.toJson(),
      'quantity': quantity,
    };
  }
}

class Order {
  final int id;
  final List<OrderItem> items;
  OrderStatus status;
  final DateTime orderDate;
  final String paymentMethod;
  final String? transactionId;

  final OrderType orderType;

  final String? table;
  final String? mobileMoneyProvider;
  final String? phoneNumber;
  final String? userId;
  final int? restaurantId;

  Order({
    required this.id,
    required this.items,
    required this.status,
    required this.orderDate,
    required this.paymentMethod,
    required this.orderType,
    this.table,
    this.transactionId,
    this.mobileMoneyProvider,
    this.phoneNumber,
    this.userId,
    this.restaurantId,
  });

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isMobileMoneyPayment => paymentMethod == 'Mobile Money';

  String get orderTypeText {
    switch (orderType) {
      case OrderType.surPlace:
        return 'Sur place';
      case OrderType.aEmporter:
        return 'À emporter';
      case OrderType.livraison:
        return 'Livraison';
    }
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
      case OrderStatus.completed:
        return 'Terminée'; // ✅ Corrigé
    }
  }

  static OrderType parseOrderType(String? type) {
    switch (type?.toLowerCase().trim()) {
      case 'sur_place':
      case 'sur place':
      case 'surplace':
        return OrderType.surPlace;
      case 'a_emporter':
      case 'à emporter':
      case 'a emporter':
      case 'aemporter':
        return OrderType.aEmporter;
      case 'livraison':
      case 'delivery':
        return OrderType.livraison;
      default:
        return OrderType.surPlace;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List;
    final List<OrderItem> orderItems =
        itemsList.map((i) => OrderItem.fromJson(i)).toList();

    OrderType parseOrderType(String? type) {
      switch (type?.toLowerCase()) {
        case 'sur_place': // backend
        case 'sur place':
        case 'surplace':
          return OrderType.surPlace;
        case 'a_emporter': // backend
        case 'à emporter':
        case 'a emporter':
        case 'aemporter':
        case 'takeaway':
          return OrderType.aEmporter;
        case 'livraison':
        case 'delivery':
          return OrderType.livraison;
        default:
          return OrderType.surPlace;
      }
    }

    return Order(
      id: json['id'] ?? 0,
      items: orderItems,
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      orderDate: DateTime.parse(
          json['order_date'] ?? DateTime.now().toIso8601String()),
      paymentMethod: json['payment_method'] ?? 'cash',
      orderType: parseOrderType(json['order_type']),
      table: json['table_number'] ?? json['table'],
      transactionId: json['transaction_id'],
      mobileMoneyProvider: json['mobile_money_provider'],
      phoneNumber: json['phone_number'],
      userId: json['user_id']?.toString(),
      restaurantId: (json['restaurant_id'] as num?)?.toInt(),
    );
  }

  /// Alias pour compatibilité — utiliser [totalAmount]
  double get totalPrice => totalAmount;

  Map<String, dynamic> toJson() {
    String orderTypeToString() {
      switch (orderType) {
        case OrderType.surPlace:
          return 'sur_place'; // format attendu par le backend
        case OrderType.aEmporter:
          return 'a_emporter'; // format attendu par le backend
        case OrderType.livraison:
          return 'livraison';
      }
    }

    return {
      'id': id,
      'items': items.map((i) => i.toJson()).toList(),
      'status': status.toString().split('.').last,
      'order_date': orderDate.toIso8601String(),
      'payment_method': paymentMethod,
      'order_type': orderTypeToString(),
      'table_number': table, // clé correcte pour le backend
      'transaction_id': transactionId,
      'mobile_money_provider': mobileMoneyProvider,
      'phone_number': phoneNumber,
      'user_id': userId,
      'restaurant_id': restaurantId,
    };
  }

  Order copyWith({
    int? id,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? orderDate,
    String? paymentMethod,
    OrderType? orderType,
    String? table, // ✅ Corrigé : int? → String?
    String? transactionId,
    String? mobileMoneyProvider,
    String? phoneNumber,
    String? userId,
    int? restaurantId,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderType: orderType ?? this.orderType,
      table: table ?? this.table,
      transactionId: transactionId ?? this.transactionId,
      mobileMoneyProvider: mobileMoneyProvider ?? this.mobileMoneyProvider,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }
}
