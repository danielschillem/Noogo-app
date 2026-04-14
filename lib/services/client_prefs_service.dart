import 'package:shared_preferences/shared_preferences.dart';

/// Persistance des préférences client côté Flutter (SharedPreferences).
///
/// Stocke :
/// - Numéro de téléphone de contact
/// - Numéro + opérateur Mobile Money (prérempli au panier)
class ClientPrefsService {
  static const String _keyPhone = 'client_phone';
  static const String _keyMmPhone = 'client_mm_phone';
  static const String _keyMmProvider = 'client_mm_provider';

  // ─── Téléphone de contact ─────────────────────────────────────────────────

  static Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  // ─── Mobile Money ─────────────────────────────────────────────────────────

  static Future<void> saveMobileMoneyPrefs({
    required String phone,
    required String provider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMmPhone, phone);
    await prefs.setString(_keyMmProvider, provider);
  }

  static Future<String?> getMobileMoneyPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMmPhone);
  }

  static Future<String?> getMobileMoneyProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMmProvider);
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyMmPhone);
    await prefs.remove(_keyMmProvider);
  }
}
