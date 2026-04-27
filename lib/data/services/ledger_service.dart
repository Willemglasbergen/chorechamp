import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chorechamp2/data/models/ledger_entry.dart';

class LedgerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _childrenCol() => _firestore.collection('children');

  CollectionReference<Map<String, dynamic>> _ledgerCol(String childId) => _childrenCol().doc(childId).collection('ledger');

  Stream<List<LedgerEntryModel>> streamLatest(String childId, {required String familyId, int limit = 20}) {
    // Avoid Firestore orderBy on mixed-type createdAt fields (string vs Timestamp) by
    // sorting client-side. This prevents query failures when legacy data exists.
    return _ledgerCol(childId)
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => LedgerEntryModel.fromJson({'id': d.id, ...d.data()}))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (list.length <= limit) return list;
          return list.sublist(0, limit);
        });
  }

  Future<void> createOpeningBalance({
    required String childId,
    required String familyId,
    required int amount,
    required String createdByUserId,
    DateTime? createdAt,
  }) async {
    await _adjustBalanceWithEntry(
      childId: childId,
      familyId: familyId,
      delta: amount,
      type: LedgerEntryType.openingBalance,
      createdByUserId: createdByUserId,
      note: 'Openingssaldo',
      createdAt: createdAt,
    );
  }

  Future<void> addTransaction({
    required String childId,
    required String familyId,
    required int amount,
    required String type,
    required String createdByUserId,
    String? note,
    String? relatedId,
    DateTime? createdAt,
  }) async {
    await _adjustBalanceWithEntry(
      childId: childId,
      familyId: familyId,
      delta: amount,
      type: type,
      createdByUserId: createdByUserId,
      note: note,
      relatedId: relatedId,
      createdAt: createdAt,
    );
  }

  Future<void> _adjustBalanceWithEntry({
    required String childId,
    required String familyId,
    required int delta,
    required String type,
    required String createdByUserId,
    String? note,
    String? relatedId,
    DateTime? createdAt,
  }) async {
    final childRef = _childrenCol().doc(childId);
    final ledgerRef = _ledgerCol(childId).doc();
    final now = createdAt ?? DateTime.now();

    final batch = _firestore.batch();
    batch.update(childRef, {
      'balance': FieldValue.increment(delta),
      'updatedAt': now.toIso8601String(),
    });
    batch.set(ledgerRef, {
      'childId': childId,
      'familyId': familyId,
      'amount': delta,
      'type': type,
      'note': note,
      'relatedId': relatedId,
      'createdByUserId': createdByUserId,
      'createdAt': now.toIso8601String(),
    });

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('LedgerService._adjustBalanceWithEntry failed: $e');
      rethrow;
    }
  }
}
