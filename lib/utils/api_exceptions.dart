// Hiérarchie d'exceptions typées pour les appels API.
//
// Usage dans les services :
// ```dart
// throw ApiException.fromStatusCode(response.statusCode, response.body);
// ```
//
// Usage dans les widgets :
// ```dart
// } on NetworkException catch (e) {
//   _showError('Pas de réseau : ${e.message}');
// } on ApiException catch (e) {
//   _showError(e.userMessage);
// }
// ```

/// Exception de base — toutes les erreurs API héritent de celle-ci.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  /// Message destiné à l'utilisateur final (sans détails techniques).
  String get userMessage => message;

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Fabrique une exception typée depuis un code HTTP et le corps de réponse.
  factory ApiException.fromStatusCode(int statusCode, String? body) {
    switch (statusCode) {
      case 401:
        return const AuthException(
            'Session expirée. Veuillez vous reconnecter.');
      case 403:
        return const ForbiddenException('Accès refusé.');
      case 404:
        return const NotFoundException('Ressource introuvable.');
      case 422:
        return ValidationException(
          _extractMessage(body) ?? 'Données invalides.',
          statusCode: statusCode,
        );
      case 429:
        return const RateLimitException(
            'Trop de requêtes. Attendez un instant.');
      default:
        if (statusCode >= 500) {
          return ServerException(
            'Erreur serveur ($statusCode). Réessayez plus tard.',
            statusCode: statusCode,
          );
        }
        return ApiException(
          _extractMessage(body) ?? 'Erreur inattendue ($statusCode).',
          statusCode: statusCode,
        );
    }
  }

  static String? _extractMessage(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      // Tente de lire le champ "message" du JSON Laravel
      final decoded = body.trim();
      if (decoded.contains('"message"')) {
        final start = decoded.indexOf('"message"') + 11;
        final end = decoded.indexOf('"', start + 1);
        if (start > 10 && end > start) {
          return decoded.substring(start, end);
        }
      }
    } catch (_) {}
    return null;
  }
}

/// Erreur réseau (pas de connexion, timeout, DNS).
class NetworkException extends ApiException {
  const NetworkException(super.message) : super(statusCode: null);

  @override
  String get userMessage =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String toString() => 'NetworkException: $message';
}

/// 401 — Non authentifié.
class AuthException extends ApiException {
  const AuthException(super.message) : super(statusCode: 401);

  @override
  String toString() => 'AuthException: $message';
}

/// 403 — Accès interdit (ressource appartenant à un autre utilisateur).
class ForbiddenException extends ApiException {
  const ForbiddenException(super.message) : super(statusCode: 403);

  @override
  String toString() => 'ForbiddenException: $message';
}

/// 404 — Ressource introuvable.
class NotFoundException extends ApiException {
  const NotFoundException(super.message) : super(statusCode: 404);

  @override
  String toString() => 'NotFoundException: $message';
}

/// 422 — Erreur de validation Laravel.
class ValidationException extends ApiException {
  const ValidationException(super.message, {super.statusCode = 422});

  @override
  String toString() => 'ValidationException: $message';
}

/// 429 — Rate limit dépassé.
class RateLimitException extends ApiException {
  const RateLimitException(super.message) : super(statusCode: 429);

  @override
  String toString() => 'RateLimitException: $message';
}

/// 5xx — Erreur serveur.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Réponse JSON malformée ou inattendue.
class ParseException extends ApiException {
  const ParseException(super.message) : super(statusCode: null);

  @override
  String get userMessage =>
      'Réponse du serveur invalide. Contactez le support.';

  @override
  String toString() => 'ParseException: $message';
}
