class ChildModel {
  final String id;
  final String name;
  final int age;
  final String familyId; // Links child to their family
  final int balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.familyId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  ChildModel copyWith({
    String? id,
    String? name,
    int? age,
    String? familyId,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChildModel(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        familyId: familyId ?? this.familyId,
        balance: balance ?? this.balance,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'familyId': familyId,
        'balance': balance,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
        id: json['id'] as String,
        name: json['name'] as String,
        age: _asInt(json['age'] ?? 0),
        familyId: json['familyId'] as String,
        balance: _asInt(json['balance'] ?? json['totalPoints'] ?? 0),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    if (v != null && v.runtimeType.toString() == 'Timestamp') {
      return (v as dynamic).toDate();
    }
    if (v is num) {
      // Detect seconds vs milliseconds since epoch
      final isSeconds = v < 1000000000000; // ~Sat Sep 09 2001
      final ms = isSeconds ? (v * 1000).toInt() : v.toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
    }
    // Fallback to now if missing/invalid instead of throwing to avoid breaking list loads
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
