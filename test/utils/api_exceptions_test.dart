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
      const e = ApiException('Erreur test', statusCode: 400);
      expect(e.toString(), contains('400'));
      expect(e.toString(), contains('Erreur test'));
    });

    test('userMessage par défaut = message', () {
      const e = ApiException('Erreur visible');
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

  group('ValidationException', () {
    test('statusCode = 422', () {
      const e = ValidationException('Données invalides.');
      expect(e.statusCode, 422);
    });

    test('toString contient ValidationException', () {
      const e = ValidationException('Email invalide.');
      expect(e.toString(), contains('ValidationException'));
    });
  });

  group('RateLimitException', () {
    test('statusCode = 429', () {
      const e = RateLimitException('Trop de requêtes.');
      expect(e.statusCode, 429);
    });

    test('toString contient RateLimitException', () {
      const e = RateLimitException('Ralenti.');
      expect(e.toString(), contains('RateLimitException'));
    });
  });

  group('ServerException', () {
    test('statusCode est conservé', () {
      const e = ServerException('Erreur interne.', statusCode: 503);
      expect(e.statusCode, 503);
    });

    test('toString contient ServerException et code', () {
      const e = ServerException('Crash.', statusCode: 500);
      expect(e.toString(), contains('ServerException'));
      expect(e.toString(), contains('500'));
    });
  });

  group('ParseException', () {
    test('statusCode est null', () {
      const e = ParseException('JSON invalide');
      expect(e.statusCode, isNull);
    });

    test('userMessage est convivial', () {
      const e = ParseException('Unexpected token');
      expect(e.userMessage, contains('invalide'));
    });

    test('toString contient ParseException', () {
      const e = ParseException('Bad format');
      expect(e.toString(), contains('ParseException'));
    });
  });

  group('AuthException.toString', () {
    test('toString contient AuthException', () {
      const e = AuthException('Token expiré.');
      expect(e.toString(), contains('AuthException'));
    });
  });

  group('ForbiddenException.toString', () {
    test('toString contient ForbiddenException', () {
      const e = ForbiddenException('Accès interdit.');
      expect(e.toString(), contains('ForbiddenException'));
    });
  });

  group('NotFoundException.toString', () {
    test('toString contient NotFoundException', () {
      const e = NotFoundException('Non trouvé.');
      expect(e.toString(), contains('NotFoundException'));
    });
  });

  group('ApiException._extractMessage edge cases', () {
    test('corps vide → ApiException générique', () {
      final e = ApiException.fromStatusCode(400, '');
      expect(e, isA<ApiException>());
    });

    test('corps null → ApiException générique', () {
      final e = ApiException.fromStatusCode(400, null);
      expect(e, isA<ApiException>());
    });

    test('corps JSON sans message → ApiException générique', () {
      final e =
          ApiException.fromStatusCode(400, '{"errors":{"field":["err"]}}');
      expect(e, isA<ApiException>());
    });
  });
}
