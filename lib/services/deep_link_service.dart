import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Gère les deep links entrants (noogo://restaurant/{id}).
///
/// Usage :
/// ```dart
/// await DeepLinkService.init();
/// DeepLinkService.restaurantIdStream.listen((id) { ... });
/// ```
class DeepLinkService {
  static final _appLinks = AppLinks();
  static final StreamController<int> _ctrl = StreamController<int>.broadcast();
  static StreamSubscription<Uri>? _sub;

  /// Stream des IDs restaurant reçus via deep link.
  static Stream<int> get restaurantIdStream => _ctrl.stream;

  static Future<void> init() async {
    try {
      // Lien initial (app lancée depuis un lien)
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        if (kDebugMode) debugPrint('🔗 Deep link initial: $initial');
        _handle(initial);
      }

      // Écoute des liens suivants (app déjà ouverte)
      _sub = _appLinks.uriLinkStream.listen(
        (uri) {
          if (kDebugMode) debugPrint('🔗 Deep link reçu: $uri');
          _handle(uri);
        },
        onError: (e) {
          if (kDebugMode) debugPrint('🔗 Erreur deep link: $e');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('🔗 Init deep link échoué: $e');
    }
  }

  static void _handle(Uri uri) {
    int? id;

    // noogo://restaurant/42
    if (uri.scheme == 'noogo' && uri.host == 'restaurant') {
      id = uri.pathSegments.isNotEmpty
          ? int.tryParse(uri.pathSegments.first)
          : null;
    }

    // https://dashboard-noogo.quickdev-it.com/restaurant/42  ou  /restaurant/42/menu
    else if (uri.pathSegments.contains('restaurant')) {
      final idx = uri.pathSegments.indexOf('restaurant');
      if (idx + 1 < uri.pathSegments.length) {
        id = int.tryParse(uri.pathSegments[idx + 1]);
      }
    }

    if (id != null && id > 0) _ctrl.add(id);
  }

  static void dispose() {
    _sub?.cancel();
    _ctrl.close();
  }
}
