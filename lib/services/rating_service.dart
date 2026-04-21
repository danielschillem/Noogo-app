import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class RatingService {
  static const String _key = 'order_ratings';

  static Future<Map<int, Map<String, dynamic>>> loadRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map(
        (k, v) => MapEntry(int.parse(k), Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<Set<int>> loadRatedOrderIds() async {
    final ratings = await loadRatings();
    return ratings.keys.toSet();
  }

  static Future<bool> hasRated(int orderId) async {
    final ratings = await loadRatings();
    return ratings.containsKey(orderId);
  }

  /// Sauvegarde la note localement ET l'envoie au backend.
  /// Si l'envoi API échoue, la note reste sauvegardée localement.
  static Future<void> saveRating(
    int orderId,
    int stars,
    String? comment, {
    int? restaurantId,
  }) async {
    // 1. Sauvegarde locale (toujours)
    final prefs = await SharedPreferences.getInstance();
    final ratings = await loadRatings();
    ratings[orderId] = {
      'stars': stars,
      'comment': comment ?? '',
      'date': DateTime.now().toIso8601String(),
    };
    await prefs.setString(
      _key,
      jsonEncode(ratings.map((k, v) => MapEntry(k.toString(), v))),
    );

    // 2. Envoi au backend (best-effort)
    if (restaurantId != null) {
      await _postRatingToApi(orderId, stars, comment, restaurantId);
    }
  }

  /// POST /restaurants/{restaurantId}/orders/{orderId}/rate
  static Future<bool> _postRatingToApi(
    int orderId,
    int stars,
    String? comment,
    int restaurantId,
  ) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/restaurants/$restaurantId/orders/$orderId/rate',
      );
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'stars': stars,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        }),
      );
      if (response.statusCode == 201) {
        if (kDebugMode) debugPrint('✅ Rating envoyé au serveur');
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Rating API ${response.statusCode}: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Rating API error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getRating(int orderId) async {
    final ratings = await loadRatings();
    return ratings[orderId];
  }
}
