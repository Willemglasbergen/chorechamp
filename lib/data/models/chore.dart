import 'package:flutter/material.dart';

class ChoreModel {
  final String id;
  final String title;
  final TimeOfDay time;
  final int points;
  final DateTime date;
  final List<String> childIds;
  final String familyId; // Links chore to family
  final List<String> completedByChildIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRecurring;
  final DateTime? recurrenceStartDate;
  final DateTime? recurrenceEndDate;
  final List<int> recurringDays; // 1=Monday, 7=Sunday
  final List<String> completedDates; // ['childId-2025-06-15', 'childId-2025-06-16']
  final bool requiresVerification;
  final List<String> pendingVerificationDates; // same format as completedDates
  final List<String> pendingVerificationChildIds; // same format as completedByChildIds

  const ChoreModel({
    required this.id,
    required this.title,
    required this.time,
    required this.points,
    required this.date,
    required this.childIds,
    required this.familyId,
    required this.completedByChildIds,
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurrenceStartDate,
    this.recurrenceEndDate,
    this.recurringDays = const [],
    this.completedDates = const [],
    this.requiresVerification = true,
    this.pendingVerificationDates = const [],
    this.pendingVerificationChildIds = const [],
  });

  ChoreModel copyWith({
    String? id,
    String? title,
    TimeOfDay? time,
    int? points,
    DateTime? date,
    List<String>? childIds,
    String? familyId,
    List<String>? completedByChildIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    DateTime? recurrenceStartDate,
    DateTime? recurrenceEndDate,
    List<int>? recurringDays,
    List<String>? completedDates,
    bool? requiresVerification,
    List<String>? pendingVerificationDates,
    List<String>? pendingVerificationChildIds,
  }) => ChoreModel(
        id: id ?? this.id,
        title: title ?? this.title,
        time: time ?? this.time,
        points: points ?? this.points,
        date: date ?? this.date,
        childIds: childIds ?? this.childIds,
        familyId: familyId ?? this.familyId,
        completedByChildIds: completedByChildIds ?? this.completedByChildIds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrenceStartDate: recurrenceStartDate ?? this.recurrenceStartDate,
        recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
        recurringDays: recurringDays ?? this.recurringDays,
        completedDates: completedDates ?? this.completedDates,
        requiresVerification: requiresVerification ?? this.requiresVerification,
        pendingVerificationDates: pendingVerificationDates ?? this.pendingVerificationDates,
        pendingVerificationChildIds: pendingVerificationChildIds ?? this.pendingVerificationChildIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': _timeToString(time),
        'points': points,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'childIds': childIds,
        'familyId': familyId,
        'completedByChildIds': completedByChildIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isRecurring': isRecurring,
        'recurrenceStartDate': recurrenceStartDate != null ? DateTime(recurrenceStartDate!.year, recurrenceStartDate!.month, recurrenceStartDate!.day).toIso8601String() : null,
        'recurrenceEndDate': recurrenceEndDate != null ? DateTime(recurrenceEndDate!.year, recurrenceEndDate!.month, recurrenceEndDate!.day).toIso8601String() : null,
        'recurringDays': recurringDays,
        'completedDates': completedDates,
        'requiresVerification': requiresVerification,
        'pendingVerificationDates': pendingVerificationDates,
        'pendingVerificationChildIds': pendingVerificationChildIds,
      };

  factory ChoreModel.fromJson(Map<String, dynamic> json) => ChoreModel(
        id: json['id'] as String,
        title: json['title'] as String,
        time: _timeFromAny(json['time']),
        points: _asInt(json['points']),
        date: _parseDate(json['date']),
        childIds: (json['childIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        familyId: json['familyId'] as String,
        completedByChildIds: (json['completedByChildIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        isRecurring: json['isRecurring'] as bool? ?? false,
        recurrenceStartDate: json['recurrenceStartDate'] != null
            ? _parseDate(json['recurrenceStartDate'])
            : null,
        recurrenceEndDate: json['recurrenceEndDate'] != null
            ? _parseDate(json['recurrenceEndDate'])
            : null,
        recurringDays: (json['recurringDays'] as List<dynamic>?)
                ?.map((e) => _asInt(e))
                .toList() ??
            [],
        completedDates: (json['completedDates'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        requiresVerification: json['requiresVerification'] as bool? ?? true,
        pendingVerificationDates: (json['pendingVerificationDates'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        pendingVerificationChildIds: (json['pendingVerificationChildIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  static String _timeToString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  static TimeOfDay _timeFromString(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static TimeOfDay _timeFromAny(dynamic v) {
    if (v is TimeOfDay) return v;
    if (v is String) return _timeFromString(v);
    if (v is Map) {
      final h = _asInt(v['hour']);
      final m = _asInt(v['minute']);
      return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
    if (v is num) {
      // Treat as minutes since midnight
      final total = v.toInt();
      final h = (total ~/ 60).clamp(0, 23);
      final m = (total % 60).clamp(0, 59);
      return TimeOfDay(hour: h, minute: m);
    }
    // Default safe time
    return const TimeOfDay(hour: 8, minute: 0);
  }

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
