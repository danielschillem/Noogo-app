import 'dart:convert';
import 'package:flutter/material.dart';

class Restaurant {
  final int id;
  final String nom;
  final String telephone;
  final String adresse;
  final String? email;
  final String? logo;
  final String? description;
  final String? heuresOuverture;
  final int? userId;
  final List<String> images;
  final bool? isOpenFromApi; // ✅ Renommé pour clarté
  final double? latitude; // FEAT-003 : coordonnées GPS (optionnel)
  final double? longitude; // FEAT-003 : coordonnées GPS (optionnel)

  Restaurant({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.adresse,
    this.email,
    this.logo,
    this.description,
    this.heuresOuverture,
    this.userId,
    this.images = const [],
    this.isOpenFromApi,
    this.latitude,
    this.longitude,
  });

  // ✅ GETTER CALCULÉ AUTOMATIQUEMENT
  bool get isOpen {
    // Si le serveur fournit le statut, l'utiliser en priorité
    if (isOpenFromApi != null) {
      return isOpenFromApi!;
    }

    // Sinon, calculer selon les horaires
    return _calculateIsOpenNow();
  }

  // ✅ CALCUL DU STATUT SELON L'HEURE ACTUELLE
  bool _calculateIsOpenNow() {
    if (heuresOuverture == null || heuresOuverture!.isEmpty) {
      return false; // Pas d'horaires = fermé
    }

    try {
      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      // Format attendu: "08:00-22:00" ou "08:00-14:00,18:00-22:00"
      final timeRanges = heuresOuverture!.split(',');

      for (final range in timeRanges) {
        final times = range.trim().split('-');
        if (times.length != 2) continue;

        final openTime = _parseTime(times[0].trim());
        final closeTime = _parseTime(times[1].trim());

        if (openTime == null || closeTime == null) continue;

        if (_isTimeBetween(currentTime, openTime, closeTime)) {
          return true; // Ouvert dans cette plage horaire
        }
      }

      return false; // Fermé
    } catch (e) {
      debugPrint('⚠️ Erreur calcul isOpen: $e');
      return false;
    }
  }

  // ✅ Convertir "08:00" en TimeOfDay
  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.tryParse(parts[0].trim());
      final minute = int.tryParse(parts[1].trim());

      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23) return null;
      if (minute < 0 || minute > 59) return null;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  // ✅ Vérifier si l'heure actuelle est entre ouverture et fermeture
  bool _isTimeBetween(TimeOfDay current, TimeOfDay open, TimeOfDay close) {
    final currentMinutes = current.hour * 60 + current.minute;
    final openMinutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;

    // Cas normal: ouverture avant fermeture (ex: 08:00-22:00)
    if (openMinutes < closeMinutes) {
      return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
    }

    // Cas spécial: fermeture après minuit (ex: 22:00-02:00)
    return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
  }

  // ✅ MÉTHODE UTILE: Obtenir le texte des horaires formaté
  String get formattedOpeningHours {
    if (heuresOuverture == null || heuresOuverture!.isEmpty) {
      return 'Horaires non définis';
    }

    // Si c'est déjà bien formaté, retourner tel quel
    if (heuresOuverture!.contains('') || heuresOuverture!.contains('h')) {
      return heuresOuverture!;
    }

    // Sinon, formatter: "08:00-22:00" → "Tous les jours: 08h00 - 22h00"
    try {
      final ranges = heuresOuverture!.split(',');
      final formatted = ranges.map((range) {
        final times = range.trim().split('-');
        if (times.length == 2) {
          return '${times[0].replaceAll(':', 'h')} - ${times[1].replaceAll(':', 'h')}';
        }
        return range;
      }).join(' et ');

      return 'Tous les jours: $formatted';
    } catch (e) {
      return heuresOuverture!;
    }
  }

  // Conversion depuis JSON (API -> App)
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    try {
      return Restaurant(
        id: _parseInt(json['id']) ?? 0,
        nom: _parseString(json['nom']) ?? '',
        telephone: _parseString(json['telephone']) ?? '',
        adresse: _parseString(json['adresse']) ?? '',
        email: _parseString(json['email']),
        logo: _parseString(json['logo']),
        description: _parseString(json['description']),
        heuresOuverture: _parseString(json['heures_ouverture']),
        userId: _parseInt(json['user_id']),
        images: _parseImages(json['images']),
        isOpenFromApi: _parseBool(json['is_open']), // ✅ Renommé
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
      );
    } catch (e) {
      debugPrint('❌ Erreur parsing Restaurant: $e');
      debugPrint('JSON reçu: $json');
      rethrow;
    }
  }

  // ✅ Helper sécurisé pour parser les int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // ✅ Helper sécurisé pour parser les double (lat/lng)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ✅ Helper sécurisé pour parser les String
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  // ✅ Helper sécurisé pour parser les bool
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  // ✅ Helper robuste pour parser les images
  static List<String> _parseImages(dynamic imagesData) {
    if (imagesData == null) return [];

    try {
      if (imagesData is List) {
        return imagesData
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      if (imagesData is Map) {
        debugPrint('⚠️ Images reçues sous forme d\'objet - ignoré');
        return [];
      }

      if (imagesData is String) {
        if (imagesData.isEmpty) return [];

        try {
          final decoded = json.decode(imagesData);
          if (decoded is List) {
            return decoded
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {
          return [imagesData];
        }
      }

      return [];
    } catch (e) {
      debugPrint('⚠️ Erreur parsing images: $e');
      return [];
    }
  }

  // Conversion vers JSON (App -> API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'adresse': adresse,
      'email': email,
      'logo': logo,
      'description': description,
      'heures_ouverture': heuresOuverture,
      'user_id': userId,
      'images': images,
      'is_open': isOpenFromApi,
    };
  }

  // Getters pour compatibilité
  String get name => nom;
  String get phone => telephone;
  String get address => adresse;
  String get imageUrl => logo ?? (images.isNotEmpty ? images.first : '');
  String get openingHours => formattedOpeningHours; // ✅ Utilise le formatage

  // Copie avec modification
  Restaurant copyWith({
    int? id,
    String? nom,
    String? telephone,
    String? adresse,
    String? email,
    String? logo,
    String? description,
    String? heuresOuverture,
    int? userId,
    List<String>? images,
    bool? isOpenFromApi,
  }) {
    return Restaurant(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      email: email ?? this.email,
      logo: logo ?? this.logo,
      description: description ?? this.description,
      heuresOuverture: heuresOuverture ?? this.heuresOuverture,
      userId: userId ?? this.userId,
      images: images ?? this.images,
      isOpenFromApi: isOpenFromApi ?? this.isOpenFromApi,
    );
  }

  @override
  String toString() {
    return 'Restaurant(id: $id, nom: $nom, telephone: $telephone, adresse: $adresse, isOpen: $isOpen)';
  }
}
