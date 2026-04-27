import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chorechamp2/data/models/chore.dart';
import 'package:chorechamp2/data/services/ledger_service.dart';
import 'package:chorechamp2/data/services/auth_service.dart';
import 'package:chorechamp2/data/models/ledger_entry.dart';
import 'package:flutter/foundation.dart';

enum ChoreToggleResult {
  completed,
  uncompleted,
  pendingVerification,
  blockedByDeadline,
  blockedByDate,
  notFound
}

class ChoresService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LedgerService _ledgerService = LedgerService();
  final AuthService _authService = AuthService();

  Stream<List<ChoreModel>> getChoresForDateStream(
      String familyId, DateTime date) {
    return _firestore
        .collection('chores')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
      final allChores = snapshot.docs
          .map((doc) => ChoreModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
      final chores = allChores
          .where((chore) => _isChoreActiveOnDate(chore, date))
          .toList();
      chores.sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });
      return chores;
    });
  }

  Future<List<ChoreModel>> getChoresForDate(
      String familyId, DateTime date) async {
    final snapshot = await _firestore
        .collection('chores')
        .where('familyId', isEqualTo: familyId)
        .get();
    final allChores = snapshot.docs
        .map((doc) => ChoreModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    final chores =
        allChores.where((chore) => _isChoreActiveOnDate(chore, date)).toList();
    chores.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return chores;
  }

  bool _isChoreActiveOnDate(ChoreModel chore, DateTime date) {
    final target = DateTime(date.year, date.month, date.day);

    if (!chore.isRecurring) {
      final choreDay =
          DateTime(chore.date.year, chore.date.month, chore.date.day);
      return choreDay == target;
    }

    if (chore.recurrenceStartDate == null || chore.recurrenceEndDate == null) {
      return false;
    }

    final startDay = DateTime(chore.recurrenceStartDate!.year,
        chore.recurrenceStartDate!.month, chore.recurrenceStartDate!.day);
    final endDay = DateTime(chore.recurrenceEndDate!.year,
        chore.recurrenceEndDate!.month, chore.recurrenceEndDate!.day);

    if (target.isBefore(startDay) || target.isAfter(endDay)) return false;

    return chore.recurringDays.contains(date.weekday);
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> addChore(ChoreModel chore) async {
    final json = chore.toJson();
    json.remove('id');
    await _firestore.collection('chores').doc(chore.id).set(json);
  }

  Future<void> updateChore(ChoreModel chore) async {
    final updated = chore.copyWith(updatedAt: DateTime.now());
    final json = updated.toJson();
    json.remove('id');
    await _firestore.collection('chores').doc(chore.id).update(json);
  }

  Future<void> deleteChore(String choreId) async {
    await _firestore.collection('chores').doc(choreId).delete();
  }

  Future<ChoreToggleResult> toggleChoreWithRules(
      String choreId, String childId, DateTime now) async {
    try {
      final choreRef = _firestore.collection('chores').doc(choreId);
      final choreSnap = await choreRef.get();
      if (!choreSnap.exists) return ChoreToggleResult.notFound;

      final chore =
          ChoreModel.fromJson({'id': choreSnap.id, ...choreSnap.data()!});
      final today = DateTime(now.year, now.month, now.day);

      if (!_isChoreActiveOnDate(chore, today)) {
        return ChoreToggleResult.blockedByDate;
      }

      final dateKey = _dateKey(today);
      final completionKey = '$childId-$dateKey';

      final bool isApproved = chore.isRecurring
          ? chore.completedDates.contains(completionKey)
          : chore.completedByChildIds.contains(childId);

      // Once approved by a parent the child cannot toggle anymore
      if (isApproved) return ChoreToggleResult.blockedByDate;

      if (chore.requiresVerification) {
        final bool isPending = chore.isRecurring
            ? chore.pendingVerificationDates.contains(completionKey)
            : chore.pendingVerificationChildIds.contains(childId);

        final Map<String, dynamic> updates = {
          'updatedAt': DateTime.now().toIso8601String(),
        };

        if (isPending) {
          // Child unsubmits — remove from pending, no points change
          if (chore.isRecurring) {
            updates['pendingVerificationDates'] =
                List<String>.from(chore.pendingVerificationDates)
                  ..remove(completionKey);
          } else {
            updates['pendingVerificationChildIds'] =
                List<String>.from(chore.pendingVerificationChildIds)
                  ..remove(childId);
          }
          await choreRef.update(updates);
          return ChoreToggleResult.uncompleted;
        } else {
          // Child submits — check deadline first
          final due = DateTime(today.year, today.month, today.day,
              chore.time.hour, chore.time.minute);
          if (!now.isBefore(due)) return ChoreToggleResult.blockedByDeadline;

          if (chore.isRecurring) {
            final pending =
                List<String>.from(chore.pendingVerificationDates);
            if (!pending.contains(completionKey)) pending.add(completionKey);
            updates['pendingVerificationDates'] = pending;
          } else {
            final pending =
                List<String>.from(chore.pendingVerificationChildIds);
            if (!pending.contains(childId)) pending.add(childId);
            updates['pendingVerificationChildIds'] = pending;
          }
          await choreRef.update(updates);
          return ChoreToggleResult.pendingVerification;
        }
      } else {
        // No verification required — original direct complete/uncomplete flow
        final due = DateTime(today.year, today.month, today.day,
            chore.time.hour, chore.time.minute);
        if (!now.isBefore(due)) return ChoreToggleResult.blockedByDeadline;

        final bool isCurrentlyCompleted = chore.isRecurring
            ? chore.completedDates.contains(completionKey)
            : chore.completedByChildIds.contains(childId);
        final nowCompleted = !isCurrentlyCompleted;

        final Map<String, dynamic> updates = {
          'updatedAt': DateTime.now().toIso8601String(),
        };
        if (chore.isRecurring) {
          final dates = List<String>.from(chore.completedDates);
          if (nowCompleted) {
            if (!dates.contains(completionKey)) dates.add(completionKey);
          } else {
            dates.remove(completionKey);
          }
          updates['completedDates'] = dates;
        } else {
          final ids = List<String>.from(chore.completedByChildIds);
          if (nowCompleted) {
            if (!ids.contains(childId)) ids.add(childId);
          } else {
            ids.remove(childId);
          }
          updates['completedByChildIds'] = ids;
        }
        await choreRef.update(updates);

        try {
          final delta = nowCompleted ? chore.points : -chore.points;
          final uid = _authService.currentUser?.uid ?? '';
          await _ledgerService.addTransaction(
            childId: childId,
            familyId: chore.familyId,
            amount: delta,
            type: LedgerEntryType.chore,
            createdByUserId: uid,
            note: nowCompleted
                ? 'Taak voltooid: ${chore.title}'
                : 'Taak ongedaan: ${chore.title}',
            relatedId: chore.id,
          );
        } catch (e) {
          debugPrint('Failed to add chore ledger entry: $e');
        }

        return nowCompleted
            ? ChoreToggleResult.completed
            : ChoreToggleResult.uncompleted;
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Parent approves a pending chore: moves it to completed and awards points.
  Future<void> approveChore(
      String choreId, String childId, DateTime date) async {
    final choreRef = _firestore.collection('chores').doc(choreId);
    final choreSnap = await choreRef.get();
    if (!choreSnap.exists) return;

    final chore =
        ChoreModel.fromJson({'id': choreSnap.id, ...choreSnap.data()!});
    final today = DateTime(date.year, date.month, date.day);
    final dateKey = _dateKey(today);
    final completionKey = '$childId-$dateKey';

    final Map<String, dynamic> updates = {
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (chore.isRecurring) {
      final pending = List<String>.from(chore.pendingVerificationDates)
        ..remove(completionKey);
      final completed = List<String>.from(chore.completedDates);
      if (!completed.contains(completionKey)) completed.add(completionKey);
      updates['pendingVerificationDates'] = pending;
      updates['completedDates'] = completed;
    } else {
      final pending = List<String>.from(chore.pendingVerificationChildIds)
        ..remove(childId);
      final completed = List<String>.from(chore.completedByChildIds);
      if (!completed.contains(childId)) completed.add(childId);
      updates['pendingVerificationChildIds'] = pending;
      updates['completedByChildIds'] = completed;
    }

    await choreRef.update(updates);

    try {
      final uid = _authService.currentUser?.uid ?? '';
      await _ledgerService.addTransaction(
        childId: childId,
        familyId: chore.familyId,
        amount: chore.points,
        type: LedgerEntryType.chore,
        createdByUserId: uid,
        note: 'Taak goedgekeurd: ${chore.title}',
        relatedId: chore.id,
      );
    } catch (e) {
      debugPrint('Failed to add approval ledger entry: $e');
    }
  }

  /// Parent rejects a pending chore: removes it from pending, no points awarded.
  Future<void> rejectChore(
      String choreId, String childId, DateTime date) async {
    final choreRef = _firestore.collection('chores').doc(choreId);
    final choreSnap = await choreRef.get();
    if (!choreSnap.exists) return;

    final chore =
        ChoreModel.fromJson({'id': choreSnap.id, ...choreSnap.data()!});
    final today = DateTime(date.year, date.month, date.day);
    final dateKey = _dateKey(today);
    final completionKey = '$childId-$dateKey';

    final Map<String, dynamic> updates = {
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (chore.isRecurring) {
      updates['pendingVerificationDates'] =
          List<String>.from(chore.pendingVerificationDates)
            ..remove(completionKey);
    } else {
      updates['pendingVerificationChildIds'] =
          List<String>.from(chore.pendingVerificationChildIds)..remove(childId);
    }

    await choreRef.update(updates);
  }
}
