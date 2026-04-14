import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/utils/api_exceptions.dart';

void main() {
  group('ApiException.fromStatusCode', () {
    test('401 → AuthException', () {
      final e = ApiException.fromStatusCode(401, null);
      expect(e, isA<AuthException>());
      expect(e.statusCode, 401);
    });

    test('403 → ForbiddenException', () {
      final e = ApiException.fromStatusCode(403, null);
      expect(e, isA<ForbiddenException>());
      expect(e.statusCode, 403);
    });

    test('404 → NotFoundException', () {
      final e = ApiException.fromStatusCode(404, null);
      expect(e, isA<NotFoundException>());
      expect(e.statusCode, 404);
    });

    test('422 → ValidationException avec message générique', () {
      final e = ApiException.fromStatusCode(422, null);
      expect(e, isA<ValidationException>());
      expect(e.statusCode, 422);
    });

    test('422 → ValidationException extrait "message" du JSON', () {
      const body = '{"message":"Le champ email est requis.","errors":{}}';
      final e = ApiException.fromStatusCode(422, body);
      expect(e, isA<ValidationException>());
      expect(e.message, contains('email'));
    });

    test('429 → RateLimitException', () {
      final e = ApiException.fromStatusCode(429, null);
      expect(e, isA<RateLimitException>());
    });

    test('500 → ServerException', () {
      final e = ApiException.fromStatusCode(500, null);
      expect(e, isA<ServerException>());
      expect(e.statusCode, 500);
    });

    test('503 → ServerException', () {
      final e = ApiException.fromStatusCode(503, null);
      expect(e, isA<ServerException>());
      expect(e.statusCode, 503);
    });

    test('400 avec corps JSON → ApiException avec message extrait', () {
      const body = '{"message":"Requête invalide."}';
      final e = ApiException.fromStatusCode(400, body);
      expect(e, isA<ApiException>());
      expect(e.message, contains('Requête invalide'));
    });

    test('code inconnu sans corps → ApiException générique', () {
      final e = ApiException.fromStatusCode(418, null);
      expect(e, isA<ApiException>());
      expect(e.statusCode, 418);
    });
  });

  group('ApiException.toString', () {
    test('affiche code + message', () {
      final e = ApiException('Erreur test', statusCode: 400);
      expect(e.toString(), contains('400'));
      expect(e.toString(), contains('Erreur test'));
    });

    test('userMessage par défaut = message', () {
      final e = ApiException('Erreur visible');
      expect(e.userMessage, 'Erreur visible');
    });
  });

  group('NetworkException', () {
    test('statusCode est null', () {
      const e = NetworkException('Timeout');
      expect(e.statusCode, isNull);
    });

    test('userMessage est convivial', () {
      const e = NetworkException('Connection refused');
      expect(e.userMessage, contains('réseau'));
    });

    test('toString est lisible', () {
      const e = NetworkException('DNS failed');
      expect(e.toString(), contains('NetworkException'));
    });
  });

  group('AuthException', () {
    test('statusCode = 401', () {
      const e = AuthException('Session expirée.');
      expect(e.statusCode, 401);
    });
  });

  group('ForbiddenException', () {
    test('statusCode = 403', () {
      const e = ForbiddenException('Accès refusé.');
      expect(e.statusCode, 403);
    });
  });

  group('NotFoundException', () {
    test('statusCode = 404', () {
      const e = NotFoundException('Ressource introuvable.');
      expect(e.statusCode, 404);
    });
  });
}
