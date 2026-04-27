class RewardModel {
  final String id;
  final String title;
  final String description;
  final int points;
  final String familyId; // Links reward to family
  final bool isCombo;
  final Map<String, String> statusByChild;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl; // Optional image url for this reward

  const RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.familyId,
    required this.isCombo,
    required this.statusByChild,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  RewardModel copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    String? familyId,
    bool? isCombo,
    Map<String, String>? statusByChild,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) => RewardModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        points: points ?? this.points,
        familyId: familyId ?? this.familyId,
        isCombo: isCombo ?? this.isCombo,
        statusByChild: statusByChild ?? Map<String, String>.from(this.statusByChild),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'points': points,
        'familyId': familyId,
        'isCombo': isCombo,
        'statusByChild': statusByChild,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'imageUrl': imageUrl,
      };

  factory RewardModel.fromJson(Map<String, dynamic> json) => RewardModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        points: _asInt(json['points']),
        familyId: json['familyId'] as String,
        isCombo: json['isCombo'] as bool? ?? false,
        // Be defensive: older docs may have null/missing statusByChild
        statusByChild: (() {
          final raw = json['statusByChild'];
          if (raw is Map) {
            return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
          return <String, String>{};
        })(),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        imageUrl: json['imageUrl'] as String?,
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
