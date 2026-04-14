import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:noogo/config/api_config.dart';
import 'package:noogo/services/auth_service.dart';
import '../models/otp_payment_request.dart';

/// Résultat typé d'un paiement OTP, transportant le message d'erreur si besoin.
class PaymentResult {
  final bool success;
  final String? errorMessage;

  const PaymentResult._({required this.success, this.errorMessage});

  factory PaymentResult.ok() => const PaymentResult._(success: true);
  factory PaymentResult.fail(String message) =>
      PaymentResult._(success: false, errorMessage: message);
}

class PaymentService {
  static const _timeout = Duration(seconds: 20);
  static const _maxRetries = 2;

  /// Vérifie l'OTP et soumet le paiement avec retry exponentiel.
  /// Retourne un [PaymentResult] détaillé au lieu d'un simple bool.
  static Future<PaymentResult> verifyOtpAndPay(
      OtpPaymentRequest request) async {
    String? lastError;

    for (int attempt = 1; attempt <= _maxRetries + 1; attempt++) {
      try {
        final token = await AuthService.getToken();

        final response = await http
            .post(
              Uri.parse(ApiConfig.getApiUrl('orders/pay-with-otp')),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode(request.toJson()),
            )
            .timeout(
              _timeout,
              onTimeout: () =>
                  throw const SocketException('Timeout paiement OTP'),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true) return PaymentResult.ok();
          final msg = data['message'] as String? ??
              data['error'] as String? ??
              'Paiement refusé par le serveur';
          return PaymentResult.fail(msg);
        }

        if (response.statusCode == 422) {
          // Erreur de validation — inutile de retenter
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final msg =
              data['message'] as String? ?? 'Données de paiement invalides';
          return PaymentResult.fail(msg);
        }

        if (response.statusCode >= 500) {
          lastError =
              'Erreur serveur (${response.statusCode}), nouvelle tentative…';
          debugPrint('⚠️ PaymentService tentative $attempt: $lastError');
        } else {
          // 4xx non-422 : ne pas retenter
          return PaymentResult.fail('Erreur paiement (${response.statusCode})');
        }
      } on SocketException catch (e) {
        lastError = 'Réseau indisponible : ${e.message}';
        debugPrint('⚠️ PaymentService tentative $attempt (réseau): $lastError');
      } on FormatException {
        return PaymentResult.fail('Réponse serveur invalide');
      } catch (e) {
        lastError = e.toString();
        debugPrint('⚠️ PaymentService tentative $attempt: $lastError');
      }

      if (attempt <= _maxRetries) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return PaymentResult.fail(
        lastError ?? 'Impossible de finaliser le paiement. Réessayez.');
  }
}
