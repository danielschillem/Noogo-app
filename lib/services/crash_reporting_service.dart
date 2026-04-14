import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/api_config.dart';
import '../utils/app_logger.dart';

/// Service centralisé de crash reporting via Sentry.
///
/// Initialisation dans main() via [CrashReportingService.init].
/// Capture automatique des erreurs Flutter + Dart non gérées.
/// En mode debug ou si le DSN est absent, Sentry est désactivé silencieusement.
class CrashReportingService {
  CrashReportingService._();

  static bool _initialized = false;

  // ================================================================
  // INITIALISATION
  // ================================================================

  /// Initialise Sentry et enroule [appRunner].
  /// À appeler AVANT [runApp], remplaçant l'appel direct à [runApp].
  static Future<void> init(AppRunner appRunner) async {
    final dsn = ApiConfig.sentryDsn;

    if (dsn.isEmpty) {
      AppLogger.warning(
          'MON-002: SENTRY_DSN absent — crash reporting désactivé',
          tag: 'Sentry');
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = ApiConfig.environment; // development / production
        options.release = 'noogo@1.0.0+1';
        options.debug = kDebugMode;

        // ✅ Ne capturer qu'en production (ou si DEBUG_MODE=false)
        options.sampleRate = ApiConfig.isProduction ? 1.0 : 0.1;

        // ✅ Traces de performance (10% en prod)
        options.tracesSampleRate = ApiConfig.isProduction ? 0.1 : 0.0;

        // Exclure les erreurs de réseau bénignes
        options.beforeSend = (event, hint) {
          final msg = event.throwable?.toString() ?? '';
          if (msg.contains('SocketException') ||
              msg.contains('TimeoutException') ||
              msg.contains('HandshakeException')) {
            // Ne pas envoyer vers Sentry — erreurs réseau attendues
            return null;
          }
          return event;
        };
      },
      appRunner: appRunner,
    );

    _initialized = true;
    AppLogger.info('MON-002: Sentry initialisé (env: ${ApiConfig.environment})',
        tag: 'Sentry');
  }

  // ================================================================
  // CAPTURE MANUELLE
  // ================================================================

  /// Capture une exception manuellement avec contexte optionnel.
  static Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? tag,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) return;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (tag != null) scope.setTag('component', tag);
        if (extras != null) {
          scope.setContexts('extra', extras);
        }
      },
    );
  }

  /// Capture un message informatif (non-exception).
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    String? tag,
  }) async {
    if (!_initialized) return;

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (tag != null) scope.setTag('component', tag);
      },
    );
  }

  // ================================================================
  // CONTEXTE UTILISATEUR
  // ================================================================

  /// Définit l'utilisateur courant pour enrichir les rapports.
  static Future<void> setUser({String? id, String? phone}) async {
    if (!_initialized) return;
    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: id, username: phone));
    });
  }

  /// Efface le contexte utilisateur (déconnexion).
  static Future<void> clearUser() async {
    if (!_initialized) return;
    await Sentry.configureScope((scope) => scope.setUser(null));
  }

  // ================================================================
  // BREADCRUMBS (fil d'ariane)
  // ================================================================

  /// Ajoute un breadcrumb pour tracer les actions avant un crash.
  static void addBreadcrumb(String message,
      {String? category, Map<String, dynamic>? data}) {
    if (!_initialized) return;
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category ?? 'app',
      data: data,
      timestamp: DateTime.now(),
    ));
  }
}

typedef AppRunner = Future<void> Function();
