import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noogo/models/user.dart';
import 'package:noogo/config/api_config.dart';

class AuthService {
  /// URL de base pour l'authentification - depuis ApiConfig (.env)
  static String get baseUrl => ApiConfig.authBaseUrl;
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _guestModeKey = 'guest_mode';

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  // Vérifier si en mode invité
  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }

  // Activer le mode invité
  static Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, true);
  }

  // ✅ Connexion
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'telephone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Login response status: ${response.statusCode}');

      if (response.statusCode == 200 && data['data'] != null) {
        final user = User.fromJson(data['data']['user']);
        final token = data['data']['token'];

        await _saveUserData(user, token);
        await _disableGuestMode();

        return {'success': true, 'user': user};
      } else {
        final err = _parseErrorMessage(data);
        return {'success': false, 'message': err ?? 'Erreur de connexion'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  // ✅ Inscription avec correction du format
  static Future<Map<String, dynamic>> register(
    String name,
    String phone,
    String password, {
    String? email,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'telephone': phone,
          'password': password,
          'password_confirmation': confirmPassword,
          if (email != null) 'email': email,
        }),
      );

      debugPrint('Register status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      // Accept any 2xx as success if we can find a user/token in common places
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Try to extract user & token from several possible shapes
        Map<String, dynamic>? payload;
        if (data is Map && data['data'] is Map) {
          payload = Map<String, dynamic>.from(data['data']);
        } else if (data is Map &&
            (data['user'] != null || data['token'] != null)) {
          payload = Map<String, dynamic>.from(data);
        }

        if (payload != null) {
          try {
            final userJson = payload['user'];
            final token = payload['token'] ??
                (payload['data'] is Map ? payload['data']['token'] : null);
            final user = userJson != null
                ? User.fromJson(userJson as Map<String, dynamic>)
                : null;

            if (user != null && token != null) {
              await _saveUserData(user, token.toString());
              await _disableGuestMode();
              return {'success': true, 'user': user, 'data': data};
            }
          } catch (_) {
            // La réponse 2xx existe mais le format est inattendu → erreur explicite
            return {
              'success': false,
              'message': 'Erreur lors de la création du compte'
            };
          }
        }

        // If 2xx but no payload, still consider success if body is non-empty
        return {'success': true, 'data': data};
      } else {
        final err = _parseErrorMessage(data);
        return {'success': false, 'message': err ?? 'Erreur d\'inscription'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur d\'inscription: $e'};
    }
  }

  // Obtenir l'utilisateur actuel
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);

    if (userString != null) {
      final userJson = jsonDecode(userString);
      return User.fromJson(userJson);
    }
    return null;
  }

  // Mettre à jour les informations utilisateur
  static Future<Map<String, dynamic>> updateUser(User user) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final updatedUser = User.fromJson(data['user']);
        await _saveUserData(updatedUser, token);

        return {'success': true, 'user': updatedUser};
      } else {
        final err = _parseErrorMessage(data);
        return {'success': false, 'message': err ?? 'Erreur de mise à jour'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de mise à jour: $e'};
    }
  }

  // Extract a readable error message from common API error shapes.
  static String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;
    try {
      if (data is String) return data;
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();

        // Laravel-style validation errors: { errors: { field: ['msg', ...] } }
        if (data['errors'] != null) {
          final errs = data['errors'];
          if (errs is Map && errs.isNotEmpty) {
            final first = errs.values.first;
            if (first is List && first.isNotEmpty) {
              return first.first.toString();
            }
            if (first is String) return first;
          }
          if (errs is List && errs.isNotEmpty) return errs.first.toString();
        }

        // Some APIs put messages under data->message
        if (data['data'] != null &&
            data['data'] is Map &&
            data['data']['message'] != null) {
          return data['data']['message'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_guestModeKey);
  }

  static Future<void> _saveUserData(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestModeKey);
  }

  // ✅ Demande de réinitialisation du mot de passe
  // Accepte un numéro de téléphone BF (champ "telephone")
  static Future<Map<String, dynamic>> forgotPassword(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'telephone': phone.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['data']?['reset_token'];
        return {
          'success': true,
          'message': data['message'] ?? 'Code généré',
          if (token != null) 'reset_token': token,
        };
      } else {
        return {
          'success': false,
          'message': _parseErrorMessage(data) ?? 'Erreur de réinitialisation',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // ✅ Réinitialisation du mot de passe avec token
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': token.trim(),
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe réinitialisé',
        };
      } else {
        return {
          'success': false,
          'message': _parseErrorMessage(data) ?? 'Token invalide ou expiré',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // ✅ Changer le mot de passe (utilisateur connecté)
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe modifié',
        };
      } else {
        return {
          'success': false,
          'message': _parseErrorMessage(data) ?? 'Erreur de modification',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }
}
