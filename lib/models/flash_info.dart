import 'package:flutter/material.dart';

class FlashInfo {
  final int id;
  final String name;
  final String description;
  final String? validityPeriod;
  final String? discountType;
  final String? discountValue;
  final String? conditions;
  final DateTime? expiryDate;
  final String imageUrl;
  final String backgroundColor;
  final String buttonText;

  FlashInfo({
    required this.id,
    required this.name,
    required this.description,
    this.validityPeriod,
    this.discountType,
    this.discountValue,
    this.conditions,
    this.expiryDate,
    required this.imageUrl,
    this.backgroundColor = '#FF6B6B',
    this.buttonText = 'Profiter de l\'offre',
  });

  factory FlashInfo.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 Parsing FlashInfo: $json');

    // Construire l'URL complète de l'image
    String imageUrl = '';
    if (json['image'] != null && json['image'].toString().isNotEmpty) {
      final imagePath = json['image'].toString();
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        imageUrl = imagePath;
      } else {
        imageUrl = 'https://noogo-e5ygx.ondigitalocean.app/storage/$imagePath';
      }
    }

    // Parser la date d'expiration de manière sécurisée
    DateTime? expiryDate;
    if (json['expiry_date'] != null && json['expiry_date'].toString().isNotEmpty) {
      try {
        expiryDate = DateTime.parse(json['expiry_date'].toString());
      } catch (e) {
        debugPrint('⚠️ Erreur parsing expiry_date: $e');
      }
    }

    // Gérer discount_value qui peut être null
    String? discountValue;
    if (json['discount_value'] != null) {
      discountValue = json['discount_value'].toString();
    }

    return FlashInfo(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      validityPeriod: json['validity_period']?.toString(),
      discountType: json['discount_type']?.toString(),
      discountValue: discountValue,
      conditions: json['conditions']?.toString(),
      expiryDate: expiryDate,
      imageUrl: imageUrl,
      backgroundColor: json['background_color']?.toString() ?? '#FF6B6B',
      buttonText: json['button_text']?.toString() ?? 'Profiter de l\'offre',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'validity_period': validityPeriod,
      'discount_type': discountType,
      'discount_value': discountValue,
      'conditions': conditions,
      'expiry_date': expiryDate?.toIso8601String(),
      'image': imageUrl,
      'background_color': backgroundColor,
      'button_text': buttonText,
    };
  }

  // Getters pour l'affichage

  /// Titre à afficher (nom de l'offre)
  String get title => name;

  /// Vérifier si l'offre est encore valide
  bool get isValid {
    if (expiryDate == null) return true;
    return DateTime.now().isBefore(expiryDate!);
  }

  /// Formater la date d'expiration
  String get formattedExpiryDate {
    if (expiryDate == null) return 'Sans limite de temps';

    final now = DateTime.now();
    final difference = expiryDate!.difference(now);

    if (difference.inDays == 0) {
      return 'Expire aujourd\'hui !';
    } else if (difference.inDays == 1) {
      return 'Expire demain';
    } else if (difference.inDays < 7) {
      return 'Expire dans ${difference.inDays} jours';
    } else {
      final day = expiryDate!.day.toString().padLeft(2, '0');
      final month = expiryDate!.month.toString().padLeft(2, '0');
      final year = expiryDate!.year;
      return 'Valable jusqu\'au $day/$month/$year';
    }
  }

  /// Formater la réduction
  String get formattedDiscount {
    // Si pas de discount_value, retourner la description
    if (discountValue == null || discountValue!.isEmpty || discountValue == 'null') {
      return description;
    }

    if (discountType != null && discountType!.isNotEmpty) {
      final type = discountType!.toLowerCase();
      if (type.contains('pourcentage') || type.contains('percent')) {
        return '-$discountValue%';
      } else if (type.contains('fixe') || type.contains('fixed')) {
        return '-$discountValue FCFA';
      }
    }

    return description;
  }

  /// Badge de réduction pour affichage
  String get discountBadge {
    // Si on a un discount_value valide
    if (discountValue != null && discountValue!.isNotEmpty && discountValue != 'null') {
      if (discountType != null && discountType!.isNotEmpty) {
        final type = discountType!.toLowerCase();
        if (type.contains('pourcentage') || type.contains('percent')) {
          return '-$discountValue%';
        } else if (type.contains('fixe') || type.contains('fixed')) {
          return '-$discountValue FCFA';
        }
      }
    }

    // Sinon, utiliser la description si elle est courte
    if (description.length <= 10) {
      return description;
    }

    return 'PROMO';
  }

  /// Icône selon le type de réduction
  IconData get discountIcon {
    if (discountType == null || discountType!.isEmpty) return Icons.local_offer;

    final type = discountType!.toLowerCase();
    if (type.contains('pourcentage') || type.contains('percent')) {
      return Icons.percent;
    } else if (type.contains('fixe') || type.contains('fixed')) {
      return Icons.attach_money;
    }

    return Icons.local_offer;
  }

  /// Jours restants avant expiration
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final difference = expiryDate!.difference(DateTime.now());
    return difference.inDays;
  }

  /// L'offre expire bientôt (moins de 3 jours)
  bool get expiresSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 3 && days >= 0;
  }
}