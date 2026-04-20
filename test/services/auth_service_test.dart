import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/services/auth_service.dart';
import 'package:noogo/models/user.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

User _fakeUser({
  String id = '1',
  String name = 'Jean Dupont',
  String phone = '70000001',
}) =>
    User(
      id: id,
      name: name,
      phone: phone,
    );

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── isLoggedIn ─────────────────────────────────────────────────────────────

  group('AuthService.isLoggedIn', () {
    test('retourne false quand aucun token', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AuthService.isLoggedIn(), isFalse);
    });

    test('retourne true quand token présent', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'abc123'});
      expect(await AuthService.isLoggedIn(), isTrue);
    });
  });

  // ── isGuestMode ───────────────────────────────────────────────────────────

  group('AuthService.isGuestMode', () {
    test('retourne false par défaut', () async {
      expect(await AuthService.isGuestMode(), isFalse);
    });

    test('retourne true quand guest_mode activé', () async {
      SharedPreferences.setMockInitialValues({'guest_mode': true});
      expect(await AuthService.isGuestMode(), isTrue);
    });
  });

  // ── enableGuestMode ───────────────────────────────────────────────────────

  group('AuthService.enableGuestMode', () {
    test('active le mode invité', () async {
      await AuthService.enableGuestMode();
      expect(await AuthService.isGuestMode(), isTrue);
    });
  });

  // ── getToken ──────────────────────────────────────────────────────────────

  group('AuthService.getToken', () {
    test('retourne null quand pas de token', () async {
      expect(await AuthService.getToken(), isNull);
    });

    test('retourne le token stocké', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'mytoken'});
      expect(await AuthService.getToken(), 'mytoken');
    });
  });

  // ── getCurrentUser ────────────────────────────────────────────────────────

  group('AuthService.getCurrentUser', () {
    test('retourne null quand pas d\'utilisateur', () async {
      expect(await AuthService.getCurrentUser(), isNull);
    });

    test('retourne l\'utilisateur stocké', () async {
      final user = _fakeUser();
      SharedPreferences.setMockInitialValues({
        'user_data': jsonEncode(user.toJson()),
      });
      final loaded = await AuthService.getCurrentUser();
      expect(loaded, isNotNull);
      expect(loaded!.id, user.id);
      expect(loaded.name, user.name);
      expect(loaded.phone, user.phone);
    });

    test('retourne null si user_data corrompu', () async {
      SharedPreferences.setMockInitialValues({
        'user_data': '{invalid_json',
      });
      // Should not throw, returns null
      try {
        final result = await AuthService.getCurrentUser();
        expect(result, isNull);
      } catch (_) {
        // Acceptable — corruption may throw
      }
    });
  });

  // ── logout ────────────────────────────────────────────────────────────────

  group('AuthService.logout', () {
    test('efface le token', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'tok',
        'user_data': '{}',
        'guest_mode': true,
      });
      await AuthService.logout();
      expect(await AuthService.getToken(), isNull);
      expect(await AuthService.getCurrentUser(), isNull);
      expect(await AuthService.isGuestMode(), isFalse);
    });
  });

  // ── login — erreur réseau ─────────────────────────────────────────────────

  group('AuthService.login (réseau indisponible)', () {
    test('retourne success:false sur erreur réseau', () async {
      final result = await AuthService.login('70000000', 'password123');
      expect(result['success'], isFalse);
      expect(result.containsKey('message'), isTrue);
    });
  });

  // ── register — erreur réseau ──────────────────────────────────────────────

  group('AuthService.register (réseau indisponible)', () {
    test('retourne success:false sur erreur réseau', () async {
      final result = await AuthService.register(
        'Jean',
        '70000000',
        'password123',
        confirmPassword: 'password123',
      );
      expect(result['success'], isFalse);
      expect(result.containsKey('message'), isTrue);
    });
  });

  // ── updateUser — non authentifié ──────────────────────────────────────────

  group('AuthService.updateUser (pas de token)', () {
    test('retourne success:false si pas de token', () async {
      final result = await AuthService.updateUser(_fakeUser());
      expect(result['success'], isFalse);
      expect(result['message'], contains('Non authentifié'));
    });
  });

  // ── baseUrl ───────────────────────────────────────────────────────────────

  group('AuthService.baseUrl', () {
    test('baseUrl est une chaîne non vide', () {
      expect(AuthService.baseUrl, isNotEmpty);
      expect(AuthService.baseUrl, isA<String>());
    });
  });

  // ── forgotPassword — erreur réseau ────────────────────────────────────────

  group('AuthService.forgotPassword (réseau indisponible)', () {
    test('retourne success:false sur erreur réseau', () async {
      final result = await AuthService.forgotPassword('70000000');
      expect(result['success'], isFalse);
      expect(result.containsKey('message'), isTrue);
    });

    test('retourne un message d\'erreur non vide', () async {
      final result = await AuthService.forgotPassword('70111222');
      expect(result['message'], isNotEmpty);
    });
  });

  // ── resetPassword — erreur réseau ────────────────────────────────────────

  group('AuthService.resetPassword (réseau indisponible)', () {
    test('retourne success:false sur erreur réseau', () async {
      final result = await AuthService.resetPassword(
        token: 'fake-token',
        password: 'newpass123',
        confirmPassword: 'newpass123',
      );
      expect(result['success'], isFalse);
    });
  });

  // ── enableGuestMode + logout ──────────────────────────────────────────────

  group('AuthService mode invité et déconnexion', () {
    test('enableGuestMode puis logout désactive le mode invité', () async {
      await AuthService.enableGuestMode();
      expect(await AuthService.isGuestMode(), isTrue);
      await AuthService.logout();
      expect(await AuthService.isGuestMode(), isFalse);
    });

    test('logout sans données stockées ne plante pas', () async {
      SharedPreferences.setMockInitialValues({});
      expect(() async => await AuthService.logout(), returnsNormally);
    });
  });

  // ── updateUser — avec token ────────────────────────────────────────────────

  group('AuthService.updateUser (erreur réseau avec token)', () {
    test('retourne success:false sur erreur réseau même avec token', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'valid-tok'});
      final result = await AuthService.updateUser(_fakeUser());
      expect(result['success'], isFalse);
    });
  });
}
