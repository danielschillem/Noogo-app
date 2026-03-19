import 'package:flutter/foundation.dart';
import 'package:noogo/config/api_config.dart';

/// Service de logging centralisé pour l'application Noogo
/// 
/// Utilisation:
/// ```dart
/// AppLogger.info('Message informatif');
/// AppLogger.error('Erreur', error: e, stackTrace: stack);
/// AppLogger.debug('Debug uniquement en mode debug');
/// ```
class AppLogger {
  // ============================================
  // 🎨 CONFIGURATION
  // ============================================
  
  static const String _appName = 'NOOGO';
  static const bool _showTimestamp = true;
  static const bool _showEmoji = true;

  // ============================================
  // 📊 NIVEAUX DE LOG
  // ============================================
  
  /// Log de niveau DEBUG (uniquement en mode debug)
  static void debug(String message, {String? tag}) {
    if (ApiConfig.isDebugMode) {
      _log('🔍', 'DEBUG', message, tag: tag);
    }
  }

  /// Log de niveau INFO
  static void info(String message, {String? tag}) {
    _log('ℹ️', 'INFO', message, tag: tag);
  }

  /// Log de niveau WARNING
  static void warning(String message, {String? tag}) {
    _log('⚠️', 'WARN', message, tag: tag);
  }

  /// Log de niveau ERROR
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('❌', 'ERROR', message, tag: tag);
    
    if (error != null) {
      _log('❌', 'ERROR', 'Exception: $error', tag: tag);
    }
    
    if (stackTrace != null && ApiConfig.isDebugMode) {
      _log('❌', 'ERROR', 'StackTrace:\n$stackTrace', tag: tag);
    }
  }

  /// Log de niveau SUCCESS
  static void success(String message, {String? tag}) {
    _log('✅', 'SUCCESS', message, tag: tag);
  }

  /// Log pour les requêtes API
  static void api(String method, String url, {int? statusCode, String? response}) {
    final emoji = statusCode != null && statusCode >= 200 && statusCode < 300 
        ? '📡' 
        : '📡❌';
    
    _log(emoji, 'API', '$method $url', tag: 'HTTP');
    
    if (statusCode != null) {
      _log(emoji, 'API', 'Status: $statusCode', tag: 'HTTP');
    }
    
    if (response != null && ApiConfig.isDebugMode) {
      // Tronquer les réponses longues
      final truncated = response.length > 500 
          ? '${response.substring(0, 500)}...' 
          : response;
      _log(emoji, 'API', 'Response: $truncated', tag: 'HTTP');
    }
  }

  /// Log pour Pusher/WebSocket
  static void realtime(String message, {String? channel, String? event}) {
    var fullMessage = message;
    if (channel != null) fullMessage += ' [Canal: $channel]';
    if (event != null) fullMessage += ' [Event: $event]';
    
    _log('🔌', 'REALTIME', fullMessage, tag: 'PUSHER');
  }

  /// Log pour la navigation
  static void navigation(String from, String to) {
    _log('🧭', 'NAV', '$from → $to', tag: 'NAVIGATION');
  }

  // ============================================
  // 🛠️ MÉTHODES UTILITAIRES
  // ============================================

  /// Affiche un séparateur visuel dans les logs
  static void separator({String? title}) {
    if (!ApiConfig.isDebugMode) return;
    
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════');
    if (title != null) {
      debugPrint('  $title');
      debugPrint('═══════════════════════════════════════════════');
    }
  }

  /// Log une map/objet formaté
  static void object(String label, Map<String, dynamic> data, {String? tag}) {
    if (!ApiConfig.isDebugMode) return;
    
    _log('📦', 'OBJECT', '$label:', tag: tag);
    data.forEach((key, value) {
      debugPrint('    $key: $value');
    });
  }

  // ============================================
  // 🔧 MÉTHODE INTERNE
  // ============================================

  static void _log(String emoji, String level, String message, {String? tag}) {
    // Ne rien logger en production (sauf erreurs)
    if (ApiConfig.isProduction && level != 'ERROR') return;
    
    final buffer = StringBuffer();
    
    // Timestamp
    if (_showTimestamp) {
      final now = DateTime.now();
      final timestamp = '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
      buffer.write('[$timestamp] ');
    }
    
    // App name
    buffer.write('[$_appName');
    
    // Tag optionnel
    if (tag != null) {
      buffer.write('/$tag');
    }
    
    buffer.write('] ');
    
    // Emoji
    if (_showEmoji) {
      buffer.write('$emoji ');
    }
    
    // Level
    buffer.write('$level: ');
    
    // Message
    buffer.write(message);
    
    debugPrint(buffer.toString());
  }
}
