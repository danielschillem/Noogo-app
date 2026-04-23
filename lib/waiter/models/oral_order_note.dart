/// Note de prise de commande à l’oral (alignée sur l’API Laravel).
class OralOrderNoteItem {
  OralOrderNoteItem({
    required this.id,
    this.dishId,
    required this.quantity,
    required this.dishNomSnapshot,
    required this.unitPriceSnapshot,
  });

  final int id;
  final int? dishId;
  final int quantity;
  final String dishNomSnapshot;
  final String unitPriceSnapshot;

  factory OralOrderNoteItem.fromJson(Map<String, dynamic> j) {
    return OralOrderNoteItem(
      id: j['id'] as int,
      dishId: j['dish_id'] as int?,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      dishNomSnapshot: j['dish_nom_snapshot']?.toString() ?? '',
      unitPriceSnapshot: j['unit_price_snapshot']?.toString() ?? '0',
    );
  }
}

class OralOrderNote {
  OralOrderNote({
    required this.id,
    required this.status,
    this.title,
    this.staffComment,
    this.validatedAt,
    this.convertedOrderId,
    this.items = const [],
  });

  final int id;
  final String status;
  final String? title;
  final String? staffComment;
  final String? validatedAt;
  final int? convertedOrderId;
  final List<OralOrderNoteItem> items;

  bool get isDraft => status == 'draft';
  bool get isValidated => status == 'validated';
  bool get isConverted => convertedOrderId != null;

  factory OralOrderNote.fromJson(Map<String, dynamic> j) {
    final raw = j['items'] as List? ?? [];
    return OralOrderNote(
      id: j['id'] as int,
      status: j['status']?.toString() ?? 'draft',
      title: j['title'] as String?,
      staffComment: j['staff_comment'] as String?,
      validatedAt: j['validated_at'] as String?,
      convertedOrderId: j['converted_order_id'] as int?,
      items: raw
          .map((e) => OralOrderNoteItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
