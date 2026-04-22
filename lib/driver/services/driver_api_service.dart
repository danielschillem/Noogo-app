import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../models/delivery.dart';

class DriverApiService {
  DriverApiService._internal();
  static final DriverApiService instance = DriverApiService._internal();
  factory DriverApiService() => instance;

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET active deliveries for current driver
  Future<List<Delivery>> getActiveDeliveries() async {
    final resp = await http
        .get(Uri.parse('$_baseUrl/deliveries/my-active'),
            headers: await _headers())
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list = data['data'] is List ? data['data'] as List : [];
      return list
          .map((e) => Delivery.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur chargement livraisons: ${resp.statusCode}');
  }

  /// GET delivery history for current driver
  Future<List<Delivery>> getDeliveryHistory() async {
    final resp = await http
        .get(Uri.parse('$_baseUrl/deliveries/my-history'),
            headers: await _headers())
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list = data['data'] is List ? data['data'] as List : [];
      return list
          .map((e) => Delivery.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur chargement historique: ${resp.statusCode}');
  }

  /// GET single delivery details
  Future<Delivery> getDelivery(int deliveryId) async {
    final resp = await http
        .get(Uri.parse('$_baseUrl/deliveries/$deliveryId'),
            headers: await _headers())
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Delivery.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Erreur chargement livraison: ${resp.statusCode}');
  }

  /// PATCH update delivery status
  Future<Delivery> updateDeliveryStatus(int deliveryId, String status) async {
    final resp = await http
        .patch(
          Uri.parse('$_baseUrl/deliveries/$deliveryId/status'),
          headers: await _headers(),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Delivery.fromJson(data['data'] as Map<String, dynamic>);
    }
    final errBody = jsonDecode(resp.body);
    throw Exception(errBody['message'] ?? 'Erreur mise à jour statut');
  }

  /// POST push driver GPS location
  Future<void> sendDriverLocation(
      int deliveryId, double lat, double lng) async {
    await http
        .post(
          Uri.parse('$_baseUrl/deliveries/$deliveryId/driver-location'),
          headers: await _headers(),
          body: jsonEncode({'lat': lat, 'lng': lng}),
        )
        .timeout(const Duration(seconds: 10));
  }

  /// PUT update driver availability
  Future<void> updateDriverStatus(String status) async {
    await http
        .put(
          Uri.parse('$_baseUrl/drivers/me/status'),
          headers: await _headers(),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));
  }

  /// GET driver profile
  Future<Map<String, dynamic>> getDriverProfile() async {
    final resp = await http
        .get(Uri.parse('$_baseUrl/drivers/me'), headers: await _headers())
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception('Erreur profil: ${resp.statusCode}');
  }

  /// POST register FCM token for driver
  Future<void> registerDeviceToken(String token) async {
    await http
        .post(
          Uri.parse('$_baseUrl/auth/device-token'),
          headers: await _headers(),
          body: jsonEncode({'token': token, 'type': 'driver'}),
        )
        .timeout(const Duration(seconds: 10));
  }
}
