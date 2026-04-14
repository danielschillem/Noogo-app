import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/app_logger.dart';

class Dish {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int categoryId;
  final String category;
  final bool isAvailable;
  final bool isDishOfTheDay;
  final int preparationTime;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.category,
    required this.isAvailable,
    this.isDishOfTheDay = false,
    this.preparationTime = 0,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ Debug amélioré : afficher tout le JSON reçu
      if (kDebugMode) {
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📥 Parsing Dish depuis JSON');
        debugPrint('JSON complet: ${json.toString()}');
      }

      // Parsing robuste des images avec URL complète
      final String imageUrl = _parseImageUrl(json['images']);

      if (kDebugMode) {
        debugPrint('🖼️ Image parsée:');
        debugPrint('   - JSON images: ${json['images']}');
        debugPrint('   - URL finale: $imageUrl');
      }

      // Parsing robuste du category_id
      final int categoryId = _parseCategoryId(json);

      // Parsing robuste du prix
      final double price = _parsePrice(json['prix']);

      final dish = Dish(
        id: _parseInt(json['id']) ?? 0,
        name: _parseString(json['nom']) ?? 'Plat sans nom',
        description: _parseString(json['description']) ?? '',
        price: price,
        imageUrl: imageUrl,
        categoryId: categoryId,
        category: _parseString(json['categorie']) ??
            _parseString(json['category_name']) ??
            '',
        isAvailable: _parseBool(json['disponibilite']) ?? true,
        isDishOfTheDay: _parseBool(json['is_plat_du_jour']) ?? false,
        preparationTime: _parseInt(json['temps_preparation']) ?? 0,
      );

      if (kDebugMode) {
        debugPrint('✅ Dish créé: ${dish.name}');
        debugPrint('   - ID: ${dish.id}');
        debugPrint('   - Prix: ${dish.formattedPrice}');
        debugPrint('   - Image URL: ${dish.imageUrl}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }

      return dish;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur critique parsing Dish — JSON: $json',
        tag: 'Dish',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ✅ Helper pour parser l'URL de l'image (VERSION AMÉLIORÉE)
  static String _parseImageUrl(dynamic images) {
    String? relativePath;

    try {
      if (kDebugMode) {
        debugPrint('🔍 Parsing image URL...');
        debugPrint('   - Type: ${images.runtimeType}');
        debugPrint('   - Valeur: $images');
      }

      if (images == null) {
        if (kDebugMode) debugPrint('   ⚠️ Images null');
        relativePath = null;
      }
      // Si c'est une liste
      else if (images is List) {
        if (kDebugMode) {
          debugPrint('   - Liste détectée (${images.length} éléments)');
        }

        if (images.isEmpty) {
          relativePath = null;
        } else {
          final first = images[0];
          if (kDebugMode) {
            debugPrint('   - Premier élément: $first (${first.runtimeType})');
          }

          if (first is String && first.isNotEmpty) {
            relativePath = first;
          } else if (first is Map && first.containsKey('url')) {
            relativePath = first['url']?.toString();
          } else if (first is Map && first.containsKey('chemin')) {
            // ✅ Certaines APIs utilisent 'chemin' au lieu de 'url'
            relativePath = first['chemin']?.toString();
          } else {
            relativePath = first?.toString();
          }
        }
      }
      // Si c'est une string
      else if (images is String && images.isNotEmpty) {
        if (kDebugMode) debugPrint('   - String détectée: $images');
        relativePath = images;
      }
      // Si c'est un objet avec une propriété 'url'
      else if (images is Map && images.containsKey('url')) {
        if (kDebugMode) debugPrint('   - Map avec url détectée');
        relativePath = images['url']?.toString();
      }
      // ✅ Vérifier aussi 'chemin'
      else if (images is Map && images.containsKey('chemin')) {
        if (kDebugMode) debugPrint('   - Map avec chemin détectée');
        relativePath = images['chemin']?.toString();
      }

      if (kDebugMode) {
        debugPrint('   - Chemin relatif extrait: $relativePath');
      }

      if (relativePath == null || relativePath.isEmpty) {
        AppLogger.warning(
            'Image absente pour un plat, utilisation du placeholder',
            tag: 'Dish');
      }

      // ✅ Utiliser la méthode sécurisée de ApiConfig
      final fullUrl = ApiConfig.getSafeImageUrl(relativePath);

      if (kDebugMode) {
        debugPrint('   ✅ URL complète: $fullUrl');
      }

      return fullUrl;
    } catch (e) {
      AppLogger.error('Erreur parsing image URL', tag: 'Dish', error: e);
      return ApiConfig.defaultImageUrl;
    }
  }

  // ✅ Helper pour extraire le category_id
  static int _parseCategoryId(Map<String, dynamic> json) {
    // Essayer différentes clés possibles
    final keys = ['categorie_id', 'category_id', 'categoryId'];
    for (final key in keys) {
      if (json.containsKey(key)) {
        final value = _parseInt(json[key]);
        if (value != null && value > 0) return value;
      }
    }
    return 0;
  }

  // ✅ Helper pour parser le prix (avec gestion des virgules)
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Gérer les virgules comme séparateur décimal (format européen)
      final cleanValue = value.replaceAll(',', '.').replaceAll(' ', '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  // ✅ Helper pour parser les int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // ✅ Helper pour parser les String (avec nettoyage)
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString().trim();
  }

  // ✅ Helper pour parser les bool
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return null;
  }

  // ✅ Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'category_name': category,
      'is_available': isAvailable,
      'is_dish_of_the_day': isDishOfTheDay,
      'preparation_time': preparationTime,
    };
  }

  // ✅ Formatage du prix
  String get formattedPrice => '${price.toStringAsFixed(0)} FCFA';

  // ✅ Méthode copyWith pour faciliter les mises à jour
  Dish copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    String? category,
    bool? isAvailable,
    bool? isDishOfTheDay,
    int? preparationTime,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      isDishOfTheDay: isDishOfTheDay ?? this.isDishOfTheDay,
      preparationTime: preparationTime ?? this.preparationTime,
    );
  }

  // ✅ Méthode toString pour le debug
  @override
  String toString() {
    return 'Dish(id: $id, name: $name, price: $formattedPrice, available: $isAvailable, imageUrl: $imageUrl)';
  }

  // ✅ Méthodes d'égalité pour comparaison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dish && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
