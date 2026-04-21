import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noogo/services/client_prefs_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClientPrefsService', () {
    test('savePhone and getPhone round-trip', () async {
      await ClientPrefsService.savePhone('70123456');
      final phone = await ClientPrefsService.getPhone();
      expect(phone, '70123456');
    });

    test('getPhone returns null when not set', () async {
      final phone = await ClientPrefsService.getPhone();
      expect(phone, isNull);
    });

    test('saveMobileMoneyPrefs and getMobileMoneyPhone round-trip', () async {
      await ClientPrefsService.saveMobileMoneyPrefs(
          phone: '76543210', provider: 'orange');
      final mm = await ClientPrefsService.getMobileMoneyPhone();
      expect(mm, '76543210');
    });

    test('getMobileMoneyProvider round-trip', () async {
      await ClientPrefsService.saveMobileMoneyPrefs(
          phone: '76543210', provider: 'wave');
      final provider = await ClientPrefsService.getMobileMoneyProvider();
      expect(provider, 'wave');
    });

    test('getMobileMoneyPhone returns null when not set', () async {
      final mm = await ClientPrefsService.getMobileMoneyPhone();
      expect(mm, isNull);
    });

    test('clear removes all saved values', () async {
      await ClientPrefsService.savePhone('70000000');
      await ClientPrefsService.saveMobileMoneyPrefs(
          phone: '76000000', provider: 'moov');
      await ClientPrefsService.clear();

      expect(await ClientPrefsService.getPhone(), isNull);
      expect(await ClientPrefsService.getMobileMoneyPhone(), isNull);
      expect(await ClientPrefsService.getMobileMoneyProvider(), isNull);
    });

    test('overwriting phone keeps last value', () async {
      await ClientPrefsService.savePhone('70000000');
      await ClientPrefsService.savePhone('77000000');
      expect(await ClientPrefsService.getPhone(), '77000000');
    });
  });
}
