import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noogo/utils/app_logger.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  group('AppLogger', () {
    test('info ne plante pas', () {
      expect(() => AppLogger.info('message info'), returnsNormally);
    });

    test('info avec tag ne plante pas', () {
      expect(() => AppLogger.info('message', tag: 'TEST'), returnsNormally);
    });

    test('warning ne plante pas', () {
      expect(() => AppLogger.warning('attention'), returnsNormally);
    });

    test('warning avec tag ne plante pas', () {
      expect(
          () => AppLogger.warning('attention', tag: 'WARN'), returnsNormally);
    });

    test('error ne plante pas', () {
      expect(() => AppLogger.error('erreur'), returnsNormally);
    });

    test('error avec objet ne plante pas', () {
      expect(
        () => AppLogger.error('erreur', tag: 'ERR', error: Exception('test')),
        returnsNormally,
      );
    });

    test('error avec stackTrace ne plante pas', () {
      expect(
        () => AppLogger.error(
          'erreur',
          tag: 'ERR',
          error: Exception('x'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('debug ne plante pas', () {
      expect(() => AppLogger.debug('debug'), returnsNormally);
    });

    test('debug avec tag ne plante pas', () {
      expect(() => AppLogger.debug('debug', tag: 'DBG'), returnsNormally);
    });

    test('log avec message vide ne plante pas', () {
      expect(() => AppLogger.info(''), returnsNormally);
    });

    test('log avec message long ne plante pas', () {
      final long = 'A' * 1000;
      expect(() => AppLogger.info(long), returnsNormally);
    });

    test('log avec caractères spéciaux ne plante pas', () {
      expect(() => AppLogger.info('msg 🔥 🎉 — spécial'), returnsNormally);
    });

    test('error sans tag ne plante pas', () {
      expect(() => AppLogger.error('erreur sans tag'), returnsNormally);
    });

    test('warning sans tag et long message', () {
      expect(() => AppLogger.warning('W' * 500), returnsNormally);
    });

    test('debug sans tag ne plante pas', () {
      expect(() => AppLogger.debug('debug sans tag'), returnsNormally);
    });

    test('info avec null tag ne plante pas', () {
      expect(() => AppLogger.info('test', tag: null), returnsNormally);
    });

    test('error avec error null ne plante pas', () {
      expect(
        () => AppLogger.error('err', error: null, stackTrace: null),
        returnsNormally,
      );
    });

    test('plusieurs appels successifs sans erreur', () {
      expect(() {
        for (var i = 0; i < 10; i++) {
          AppLogger.info('Log $i');
          AppLogger.debug('Debug $i');
          AppLogger.warning('Warn $i');
        }
      }, returnsNormally);
    });
  });
}
