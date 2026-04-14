import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/services/payment_service.dart';

void main() {
  group('PaymentResult', () {
    test('PaymentResult.ok() — success est true, errorMessage est null', () {
      final result = PaymentResult.ok();
      expect(result.success, true);
      expect(result.errorMessage, isNull);
    });

    test('PaymentResult.fail() — success est false, errorMessage renseigné',
        () {
      const msg = 'Code OTP invalide';
      final result = PaymentResult.fail(msg);
      expect(result.success, false);
      expect(result.errorMessage, msg);
    });

    test('PaymentResult.fail() — message vide est conservé', () {
      final result = PaymentResult.fail('');
      expect(result.success, false);
      expect(result.errorMessage, '');
    });
  });
}
