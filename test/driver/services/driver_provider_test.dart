import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/driver/services/driver_provider.dart';
import 'package:noogo/driver/models/delivery.dart';

void main() {
  group('DriverProvider', () {
    late DriverProvider provider;

    setUp(() {
      provider = DriverProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state', () {
      expect(provider.activeDeliveries, isEmpty);
      expect(provider.history, isEmpty);
      expect(provider.currentDelivery, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.isOnline, isFalse);
      expect(provider.error, isNull);
    });

    test('selectDelivery sets currentDelivery and notifies', () {
      final delivery = Delivery.fromJson({
        'id': 1,
        'order_id': 10,
        'status': 'assigned',
        'created_at': '2026-04-22T12:00:00Z',
      });

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.selectDelivery(delivery);

      expect(provider.currentDelivery, delivery);
      expect(notifyCount, 1);
    });

    test('advanceStatus returns false when no currentDelivery', () async {
      final result = await provider.advanceStatus();
      expect(result, isFalse);
    });

    test('markFailed returns false when no currentDelivery', () async {
      final result = await provider.markFailed();
      expect(result, isFalse);
    });
  });
}
