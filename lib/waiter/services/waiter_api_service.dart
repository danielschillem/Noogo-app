import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../models/waiter_order.dart';

class WaiterApiService {
  WaiterApiService._internal();
  static final WaiterApiService instance = WaiterApiService._internal();
  factory WaiterApiService() => instance;

  static String get _base => ApiConfig.baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Restaurant ────────────────────────────────────────────────────────────

  /// GET restaurant assigned to current staff + role info
  Future<Map<String, dynamic>> getMyRestaurant() async {
    final resp = await http
        .get(Uri.parse('$_base/auth/my-restaurants'), headers: await _headers())
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list = data['data'] as List? ?? [];
      if (list.isEmpty) throw Exception('Aucun restaurant assigné');
      // Return first active restaurant
      final active = list.firstWhere(
        (r) => r['is_active'] == true,
        orElse: () => list.first,
      );
      return active as Map<String, dynamic>;
    }
    throw Exception('Erreur chargement restaurant: ${resp.statusCode}');
  }

  // ─── Orders ────────────────────────────────────────────────────────────────

  /// GET orders for restaurant, optionally filtered by status
  Future<List<WaiterOrder>> getOrders(
    int restaurantId, {
    String? status,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_base/restaurants/$restaurantId/orders').replace(
      queryParameters: {
        if (status != null) 'status': status,
        'page': page.toString(),
        'per_page': '50',
        'sort': 'desc',
      },
    );
    final resp = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      final list = body['data'] is List
          ? body['data'] as List
          : (body['data']?['data'] as List? ?? []);
      return list
          .map((e) => WaiterOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur chargement commandes: ${resp.statusCode}');
  }

  /// GET single order detail
  Future<WaiterOrder> getOrder(int restaurantId, int orderId) async {
    final resp = await http
        .get(
          Uri.parse('$_base/restaurants/$restaurantId/orders/$orderId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      return WaiterOrder.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception('Erreur chargement commande: ${resp.statusCode}');
  }

  /// PATCH update order status
  Future<WaiterOrder> updateOrderStatus(
      int restaurantId, int orderId, String status) async {
    final resp = await http
        .patch(
          Uri.parse('$_base/restaurants/$restaurantId/orders/$orderId/status'),
          headers: await _headers(),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      return WaiterOrder.fromJson(body['data'] as Map<String, dynamic>);
    }
    final err = jsonDecode(resp.body);
    throw Exception(err['message'] ?? 'Erreur mise à jour statut');
  }

  /// POST cancel order
  Future<void> cancelOrder(int restaurantId, int orderId) async {
    final resp = await http
        .post(
          Uri.parse('$_base/restaurants/$restaurantId/orders/$orderId/cancel'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      final err = jsonDecode(resp.body);
      throw Exception(err['message'] ?? 'Erreur annulation');
    }
  }

  // ─── Menu (for new order creation) ────────────────────────────────────────

  /// GET full menu of restaurant
  Future<List<Map<String, dynamic>>> getMenu(int restaurantId) async {
    final resp = await http
        .get(
          Uri.parse('$_base/restaurant/$restaurantId/menu'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      final cats = body['data']?['menu_par_categories'] as List? ?? [];
      return cats.map((c) => c as Map<String, dynamic>).toList();
    }
    throw Exception('Erreur chargement menu: ${resp.statusCode}');
  }

  /// POST create new order (sur place — from waiter)
  Future<WaiterOrder> createOrder({
    required int restaurantId,
    required List<Map<String, dynamic>> items,
    required String orderType,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    final resp = await http
        .post(
          Uri.parse('$_base/restaurants/$restaurantId/orders'),
          headers: await _headers(),
          body: jsonEncode({
            'order_type': orderType,
            'table_number': tableNumber,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'notes': notes,
            'payment_method': 'cash',
            'items': items,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode == 201) {
      final body = jsonDecode(resp.body);
      return WaiterOrder.fromJson(body['data'] as Map<String, dynamic>);
    }
    final err = jsonDecode(resp.body);
    throw Exception(err['message'] ?? 'Erreur création commande');
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  /// GET pending orders count
  Future<int> getPendingCount(int restaurantId) async {
    final resp = await http
        .get(
          Uri.parse('$_base/restaurants/$restaurantId/orders-pending-count'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      return body['data']?['count'] as int? ?? 0;
    }
    return 0;
  }
}
