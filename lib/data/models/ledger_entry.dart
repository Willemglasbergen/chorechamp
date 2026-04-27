class LedgerEntryModel {
  final String id;
  final String childId;
  final String familyId;
  final int amount; // positive=credit, negative=debit
  final String type; // opening_balance | chore | reward_request | reward_cancel | manual_adjustment
  final String? note;
  final String? relatedId; // e.g., choreId or rewardId
  final String createdByUserId;
  final DateTime createdAt;

  const LedgerEntryModel({
    required this.id,
    required this.childId,
    required this.familyId,
    required this.amount,
    required this.type,
    required this.createdByUserId,
    required this.createdAt,
    this.note,
    this.relatedId,
  });

  LedgerEntryModel copyWith({
    String? id,
    String? childId,
    String? familyId,
    int? amount,
    String? type,
    String? note,
    String? relatedId,
    String? createdByUserId,
    DateTime? createdAt,
  }) => LedgerEntryModel(
        id: id ?? this.id,
        childId: childId ?? this.childId,
        familyId: familyId ?? this.familyId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        note: note ?? this.note,
        relatedId: relatedId ?? this.relatedId,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'familyId': familyId,
        'amount': amount,
        'type': type,
        'note': note,
        'relatedId': relatedId,
        'createdByUserId': createdByUserId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) => LedgerEntryModel(
        id: json['id'] as String,
        childId: json['childId'] as String,
        familyId: json['familyId'] as String,
        amount: _asInt(json['amount']),
        type: (json['type'] as String?) ?? 'manual_adjustment',
        note: json['note'] as String?,
        relatedId: json['relatedId'] as String?,
        createdByUserId: (json['createdByUserId'] as String?) ?? '',
        createdAt: _parseDate(json['createdAt']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    if (v != null && v.runtimeType.toString() == 'Timestamp') {
      return (v as dynamic).toDate();
    }
    if (v is num) {
      final isSeconds = v < 1000000000000;
      final ms = isSeconds ? (v * 1000).toInt() : v.toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
    }
    return DateTime.now();
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    final s = v.toString();
    final parsed = int.tryParse(s) ?? double.tryParse(s)?.toInt();
    return parsed ?? 0;
  }
}

class LedgerEntryType {
  static const openingBalance = 'opening_balance';
  static const chore = 'chore';
  static const rewardRequest = 'reward_request';
  static const rewardCancel = 'reward_cancel';
  static const manualAdjustment = 'manual_adjustment';
}
