import 'dart:convert';

/// Représente un restaurant sauvegardé localement après scan QR.
class SavedRestaurant {
  final int id;
  final String name;
  final String? imageUrl;
  final String? address;
  final String? phone;
  final DateTime lastScannedAt;

  const SavedRestaurant({
    required this.id,
    required this.name,
    this.imageUrl,
    this.address,
    this.phone,
    required this.lastScannedAt,
  });

  SavedRestaurant copyWith({DateTime? lastScannedAt}) => SavedRestaurant(
        id: id,
        name: name,
        imageUrl: imageUrl,
        address: address,
        phone: phone,
        lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        'lastScannedAt': lastScannedAt.toIso8601String(),
      };

  factory SavedRestaurant.fromJson(Map<String, dynamic> json) =>
      SavedRestaurant(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as String?) ?? 'Restaurant',
        imageUrl: json['imageUrl'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        lastScannedAt: json['lastScannedAt'] != null
            ? DateTime.tryParse(json['lastScannedAt'] as String) ??
                DateTime.now()
            : DateTime.now(),
      );

  static List<SavedRestaurant> listFromJsonString(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => SavedRestaurant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<SavedRestaurant> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  /// Durée depuis le dernier scan, formatée en français.
  String get lastSeenLabel {
    final diff = DateTime.now().difference(lastScannedAt);
    if (diff.inMinutes < 2) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} sem';
    return 'Le ${lastScannedAt.day}/${lastScannedAt.month}/${lastScannedAt.year}';
  }
}
