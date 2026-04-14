import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// ─── Statuts ─────────────────────────────────────────────────────────────────

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  expired,
  cancelled,
}

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus fromString(String s) => switch (s) {
        'pending' => PaymentStatus.pending,
        'processing' => PaymentStatus.processing,
        'completed' => PaymentStatus.completed,
        'failed' => PaymentStatus.failed,
        'expired' => PaymentStatus.expired,
        'cancelled' => PaymentStatus.cancelled,
        _ => PaymentStatus.pending,
      };

  bool get isActive =>
      this == PaymentStatus.pending || this == PaymentStatus.processing;
  bool get isCompleted => this == PaymentStatus.completed;
  bool get isFailed =>
      this == PaymentStatus.failed ||
      this == PaymentStatus.expired ||
      this == PaymentStatus.cancelled;
}

// ─── Modèles ─────────────────────────────────────────────────────────────────

class PaymentRecord {
  final int id;
  final String reference;
  final PaymentStatus status;
  final String provider;
  final String phone;
  final int amount;
  final String? operatorTransactionId;
  final DateTime? confirmedAt;
  final DateTime? expiresAt;

  PaymentRecord({
    required this.id,
    required this.reference,
    required this.status,
    required this.provider,
    required this.phone,
    required this.amount,
    this.operatorTransactionId,
    this.confirmedAt,
    this.expiresAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: (json['id'] as num).toInt(),
      reference: json['reference'] ?? '',
      status: PaymentStatusX.fromString(json['status'] ?? 'pending'),
      provider: json['provider'] ?? '',
      phone: json['phone'] ?? '',
      amount: (json['amount'] as num).toInt(),
      operatorTransactionId: json['operator_transaction_id'],
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
    );
  }
}

class PaymentInitResult {
  final bool success;
  final String message;
  final PaymentRecord? payment;
  final String mode; // 'simulation' | 'cinetpay'

  PaymentInitResult({
    required this.success,
    required this.message,
    this.payment,
    this.mode = 'simulation',
  });
}

// ─── Ancien alias (rétro-compatibilité cart_screen.dart) ─────────────────────

class PaymentResult {
  final bool success;
  final String? errorMessage;

  const PaymentResult._({required this.success, this.errorMessage});

  factory PaymentResult.ok() => const PaymentResult._(success: true);
  factory PaymentResult.fail(String message) =>
      PaymentResult._(success: false, errorMessage: message);
}

// ─── Service ─────────────────────────────────────────────────────────────────

/// Service de paiement Mobile Money Noogo.
///
/// Flow :
///   1. [initiate]   → crée le paiement en backend + notifie l'opérateur
///   2. Client reçoit USSD push → valide avec PIN → reçoit OTP
///   3. [confirmOtp] → envoyer l'OTP au backend
///   4. [pollUntilDone] / [checkStatus] → attendre le statut final
class PaymentService {
  static String get _base => ApiConfig.baseUrl;

  static Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─── Initiation ────────────────────────────────────────────────────────────

  static Future<PaymentInitResult> initiate({
    required int restaurantId,
    required String provider,
    required String phone,
    required int amount,
    int? orderId,
  }) async {
    try {
      final body = <String, dynamic>{
        'restaurant_id': restaurantId,
        'provider': provider,
        'phone': phone,
        'amount': amount,
        if (orderId != null) 'order_id': orderId,
      };

      final response = await http
          .post(
            Uri.parse('$_base/payments/initiate'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final pd = data['data'] as Map<String, dynamic>?;
        return PaymentInitResult(
          success: true,
          message: data['message'] ?? 'Demande envoyée',
          payment: pd != null ? PaymentRecord.fromJson(pd) : null,
          mode: data['mode'] ?? 'simulation',
        );
      }

      return PaymentInitResult(
        success: false,
        message: data['message'] ?? 'Erreur lors de l\'initiation du paiement',
      );
    } catch (e) {
      debugPrint('⚠️ PaymentService.initiate: $e');
      return PaymentInitResult(
        success: false,
        message: 'Impossible de contacter le serveur de paiement',
      );
    }
  }

  // ─── Confirmation OTP ──────────────────────────────────────────────────────

  static Future<({bool success, String message, PaymentRecord? payment})>
      confirmOtp({
    required int paymentId,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/payments/$paymentId/confirm-otp'),
            headers: _headers,
            body: jsonEncode({'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pd = data['data'] as Map<String, dynamic>?;

      return (
        success: data['success'] == true,
        message: (data['message'] as String?) ?? '',
        payment: pd != null ? PaymentRecord.fromJson(pd) : null,
      );
    } catch (e) {
      debugPrint('⚠️ PaymentService.confirmOtp: $e');
      return (success: false, message: 'Erreur de connexion', payment: null);
    }
  }

  // ─── Polling statut ────────────────────────────────────────────────────────

  static Future<PaymentRecord?> checkStatus(int paymentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_base/payments/$paymentId/status'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pd = data['data'] as Map<String, dynamic>?;
        return pd != null ? PaymentRecord.fromJson(pd) : null;
      }
    } catch (e) {
      debugPrint('⚠️ PaymentService.checkStatus: $e');
    }
    return null;
  }

  /// Poll toutes les [interval] jusqu'à un état terminal ou [timeout].
  static Future<PaymentRecord?> pollUntilDone({
    required int paymentId,
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 10),
    void Function(PaymentStatus status)? onStatus,
  }) async {
    final deadline = DateTime.now().add(timeout);
    PaymentStatus? lastStatus;

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(interval);

      final payment = await checkStatus(paymentId);
      if (payment == null) continue;

      if (payment.status != lastStatus) {
        lastStatus = payment.status;
        onStatus?.call(payment.status);
      }

      if (!payment.status.isActive) return payment;
    }

    return null;
  }

  // ─── Annulation ────────────────────────────────────────────────────────────

  static Future<bool> cancel(int paymentId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_base/payments/$paymentId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ PaymentService.cancel: $e');
      return false;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String providerLabel(String provider) => switch (provider) {
        'orange' => 'Orange Money',
        'moov' => 'Moov Africa',
        'wave' => 'Wave',
        'telecel' => 'Telecel Money',
        'cash' => 'Espèces',
        _ => provider,
      };

  static int providerColorValue(String provider) => switch (provider) {
        'orange' => 0xFFFF7900,
        'moov' => 0xFF003DA5,
        'wave' => 0xFF1DBFAF,
        'telecel' => 0xFFE30613,
        'cash' => 0xFF4CAF50,
        _ => 0xFF9E9E9E,
      };
}
