class OtpPaymentRequest {
  final String orderType;
  final String? tableNumber;
  final String phone;
  final String provider;
  final int amount;
  final String otp;
  final List<Map<String, dynamic>> items;

  OtpPaymentRequest({
    required this.orderType,
    this.tableNumber,
    required this.phone,
    required this.provider,
    required this.amount,
    required this.otp,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      "order_type": orderType,
      "table_number": tableNumber,
      "phone": phone,
      "payment_method": "mobile_money",
      "provider": provider,
      "amount": amount,
      "otp": otp,
      "otp_phone": phone,
      "items": items,
    };
  }
}
