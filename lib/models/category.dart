import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      if (kDebugMode) {
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📥 Parsing Category depuis JSON');
        debugPrint('JSON complet: ${json.toString()}');
      }

      // ✅ Parsing image robuste (même logique que Dish)
      final String imageUrl = _parseImageUrl(json);

      final category = Category(
        id: _parseCategoryId(json),
        name: _parseCategoryName(json),
        description: _parseString(json['categorie_description']) ??
            _parseString(json['description']),
        imageUrl: imageUrl,
      );

      if (kDebugMode) {
        debugPrint('✅ Category créée: ${category.name}');
        debugPrint('   - ID: ${category.id}');
        debugPrint('   - Image URL: ${category.imageUrl}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }

      return category;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ ERREUR CRITIQUE parsing Category');
        debugPrint('JSON reçu: $json');
        debugPrint('Erreur: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      rethrow;
    }
  }

  // ✅ Identique à Dish : parsing intelligent d’image
  static String _parseImageUrl(Map<String, dynamic> json) {
    String? relativePath;

    try {
      if (kDebugMode) {
        debugPrint('🔍 ═══ Parsing category image ═══');
        debugPrint('   JSON complet: ${json.toString()}');
      }

      // ✅ Liste exhaustive de toutes les clés possibles
      final imageKeys = [
        'categorie_image',
        'categorie_image_url',
        'image_url',
        'image',
        'images',
        'chemin',
        'path',
        'url',
        'photo',
        'picture',
        'img'
            'image_path',
        'image_chemin'
      ];

      for (final key in imageKeys) {
        if (json.containsKey(key)) {
          final value = json[key];

          if (kDebugMode) {
            debugPrint('   ✓ Clé "$key" trouvée');
            debugPrint('     Valeur: $value');
            debugPrint('     Type: ${value.runtimeType}');
          }

          if (value == null || value.toString().trim().isEmpty) {
            if (kDebugMode) debugPrint('     → Valeur vide, on continue...');
            continue;
          }

          // Si c'est une liste d'images
          if (value is List && value.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('     → C\'est une liste de ${value.length} éléments');
            }

            final first = value[0];
            if (first is String && first.isNotEmpty) {
              relativePath = first;
              if (kDebugMode) {
                debugPrint('     → Premier élément (String): $relativePath');
              }
              break;
            } else if (first is Map && first.containsKey('url')) {
              relativePath = first['url']?.toString();
              if (kDebugMode) {
                debugPrint(
                    '     → Premier élément (Map) avec url: $relativePath');
              }
              break;
            } else if (first is Map && first.containsKey('chemin')) {
              relativePath = first['chemin']?.toString();
              if (kDebugMode) {
                debugPrint(
                    '     → Premier élément (Map) avec chemin: $relativePath');
              }
              break;
            }
          }
          // Si c'est une simple string
          else if (value is String && value.isNotEmpty) {
            relativePath = value;
            if (kDebugMode) debugPrint('     → String directe: $relativePath');
            break;
          }
          // Si c'est un objet
          else if (value is Map) {
            if (kDebugMode) debugPrint('     → C\'est un Map');

            if (value.containsKey('url')) {
              relativePath = value['url']?.toString();
              if (kDebugMode) debugPrint('     → Map avec url: $relativePath');
              break;
            } else if (value.containsKey('chemin')) {
              relativePath = value['chemin']?.toString();
              if (kDebugMode) {
                debugPrint('     → Map avec chemin: $relativePath');
              }
              break;
            }
          }
        }
      }

      if (kDebugMode) {
        if (relativePath != null) {
          debugPrint('   ✅ Chemin relatif extrait: $relativePath');
        } else {
          debugPrint('   ⚠️ Aucun chemin d\'image trouvé dans le JSON');
          debugPrint('   → Clés disponibles: ${json.keys.toList()}');
        }
      }

      final fullUrl = ApiConfig.getSafeImageUrl(relativePath);

      if (kDebugMode) {}

      return fullUrl;
    } catch (e) {
      if (kDebugMode) {}
      return ApiConfig.defaultImageUrl;
    }
  }

  static int _parseCategoryId(Map<String, dynamic> json) {
    final keys = ['categorie_id', 'category_id', 'id', 'categoryId'];
    for (final key in keys) {
      if (json.containsKey(key)) {
        final value = _parseInt(json[key]);
        if (value != null && value > 0) return value;
      }
    }
    return 0;
  }

  static String _parseCategoryName(Map<String, dynamic> json) {
    final keys = ['categorie_nom', 'category_name', 'name', 'nom'];
    for (final key in keys) {
      if (json.containsKey(key)) {
        final value = _parseString(json[key]);
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return '';
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString().trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
    };
  }

  @override
  String toString() => 'Category(id: $id, name: $name, imageUrl: $imageUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
