import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:noogo/config/api_config.dart';
import 'package:noogo/services/auth_service.dart';
import '../models/otp_payment_request.dart';

class PaymentService {
  static Future<bool> verifyOtpAndPay(OtpPaymentRequest request) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.getApiUrl('orders/pay-with-otp')),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
