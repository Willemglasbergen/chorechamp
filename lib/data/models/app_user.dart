class AppUser {
  final String id;
  final String name;
  final String email;
  final String? pinCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.pinCode,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? pinCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        pinCode: pinCode ?? this.pinCode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      pinCode: json['pinCode'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (pinCode != null) 'pinCode': pinCode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

DateTime _parseDate(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.parse(v);
  // Handle Firestore Timestamp
  if (v != null && v.runtimeType.toString() == 'Timestamp') {
    return (v as dynamic).toDate();
  }
  throw ArgumentError('Invalid date: $v');
}
