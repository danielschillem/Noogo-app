import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<void> saveRating(
    int orderId,
    int stars,
    String? comment,
  ) async {
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
  }

  static Future<Map<String, dynamic>?> getRating(int orderId) async {
    final ratings = await loadRatings();
    return ratings[orderId];
  }
}
