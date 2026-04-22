import 'package:latlong2/latlong.dart';

class Delivery {
  final int id;
  final int orderId;
  final int? driverId;
  final String status;
  final String? pickupAddress;
  final String? deliveryAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final double? fee;
  final String? customerPhone;
  final String? customerName;
  final String? restaurantName;
  final String? restaurantPhone;
  final double? totalAmount;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final List<DeliveryItem> items;

  Delivery({
    required this.id,
    required this.orderId,
    this.driverId,
    required this.status,
    this.pickupAddress,
    this.deliveryAddress,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
    this.fee,
    this.customerPhone,
    this.customerName,
    this.restaurantName,
    this.restaurantPhone,
    this.totalAmount,
    this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.createdAt,
    this.items = const [],
  });

  LatLng? get pickupLatLng => pickupLat != null && pickupLng != null
      ? LatLng(pickupLat!, pickupLng!)
      : null;

  LatLng? get deliveryLatLng => deliveryLat != null && deliveryLng != null
      ? LatLng(deliveryLat!, deliveryLng!)
      : null;

  bool get isActive => ['assigned', 'picked_up', 'on_way'].contains(status);
  bool get isCompleted => status == 'delivered';
  bool get isFailed => status == 'failed';
  bool get needsAcceptance => status == 'assigned' && acceptedAt == null;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'assigned':
        return 'Assignée';
      case 'picked_up':
        return 'Récupérée';
      case 'on_way':
        return 'En route';
      case 'delivered':
        return 'Livrée';
      case 'failed':
        return 'Échouée';
      default:
        return status;
    }
  }

  String? get nextStatus {
    switch (status) {
      case 'assigned':
        return 'picked_up';
      case 'picked_up':
        return 'on_way';
      case 'on_way':
        return 'delivered';
      default:
        return null;
    }
  }

  String? get nextStatusLabel {
    switch (nextStatus) {
      case 'picked_up':
        return 'Commande récupérée';
      case 'on_way':
        return 'En route vers le client';
      case 'delivered':
        return 'Livrée au client';
      default:
        return null;
    }
  }

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      orderId: json['order_id'] is int
          ? json['order_id']
          : int.tryParse('${json['order_id']}') ?? 0,
      driverId: json['driver_id'] is int
          ? json['driver_id']
          : int.tryParse('${json['driver_id']}'),
      status: json['status']?.toString() ?? 'pending',
      pickupAddress: json['pickup_address']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      pickupLat: _toDouble(json['pickup_lat']),
      pickupLng: _toDouble(json['pickup_lng']),
      deliveryLat: _toDouble(json['delivery_lat']),
      deliveryLng: _toDouble(json['delivery_lng']),
      fee: _toDouble(json['fee']),
      customerPhone: json['customer_phone']?.toString(),
      customerName: json['customer_name']?.toString(),
      restaurantName: json['restaurant_name']?.toString() ??
          json['restaurant']?['nom']?.toString(),
      restaurantPhone: json['restaurant_phone']?.toString() ??
          json['restaurant']?['telephone']?.toString(),
      totalAmount:
          _toDouble(json['total_amount'] ?? json['order']?['total_amount']),
      assignedAt: _toDate(json['assigned_at']),
      acceptedAt: _toDate(json['accepted_at']),
      pickedUpAt: _toDate(json['picked_up_at']),
      deliveredAt: _toDate(json['delivered_at']),
      createdAt: _toDate(json['created_at']) ?? DateTime.now(),
      items: (json['order']?['items'] as List<dynamic>?)
              ?.map((e) => DeliveryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse('$v');
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse('$v');
  }
}

class DeliveryItem {
  final String name;
  final int quantity;
  final double unitPrice;

  DeliveryItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      name: json['dish']?['nom']?.toString() ?? json['name']?.toString() ?? '',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse('${json['quantity']}') ?? 1,
      unitPrice:
          Delivery._toDouble(json['unit_price'] ?? json['prix_unitaire']) ?? 0,
    );
  }
}
