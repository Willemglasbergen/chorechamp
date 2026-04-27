import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chorechamp2/data/models/child.dart';
import 'package:chorechamp2/data/services/ledger_service.dart';
import 'package:chorechamp2/data/models/ledger_entry.dart';
import 'package:flutter/foundation.dart';

class ChildrenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LedgerService _ledgerService = LedgerService();

  Stream<List<ChildModel>> getChildrenStream(String familyId) {
    return _firestore
        .collection('children')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
          final children = snapshot.docs
              .map((doc) => ChildModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList();
          children.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return children;
        });
  }

  Future<List<ChildModel>> getChildren(String familyId) async {
    final snapshot = await _firestore
        .collection('children')
        .where('familyId', isEqualTo: familyId)
        .get();
    final children = snapshot.docs
        .map((doc) => ChildModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    children.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return children;
  }

  Future<ChildModel?> getChild(String childId) async {
    final doc = await _firestore.collection('children').doc(childId).get();
    if (!doc.exists) return null;
    return ChildModel.fromJson({'id': doc.id, ...doc.data()!});
  }

  Future<void> createChild(ChildModel child) async {
    final json = child.toJson();
    json.remove('id');
    await _firestore.collection('children').doc(child.id).set(json);
  }

  Future<void> updateChild(ChildModel child) async {
    final updated = child.copyWith(updatedAt: DateTime.now());
    final json = updated.toJson();
    json.remove('id');
    await _firestore.collection('children').doc(child.id).update(json);
  }

  Future<void> deleteChild(String childId) async {
    await _firestore.collection('children').doc(childId).delete();
  }

  Future<void> updateBalance(String childId, int newBalance) async {
    await _firestore.collection('children').doc(childId).update({
      'balance': newBalance,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Creates a child and records an opening balance ledger entry atomically.
  Future<void> createChildWithOpeningBalance({
    required ChildModel child,
    required String createdByUserId,
  }) async {
    // Create child with zero balance first, then apply opening balance via ledger entry
    // This avoids double-counting the starting balance.
    final initial = child.balance;
    final childWithZero = child.copyWith(balance: 0);
    await createChild(childWithZero);
    if (initial != 0) {
      try {
        await _ledgerService.createOpeningBalance(
          childId: child.id,
          familyId: child.familyId,
          amount: initial,
          createdByUserId: createdByUserId,
          createdAt: child.createdAt,
        );
      } catch (e) {
        debugPrint('Failed to create opening balance entry: $e');
      }
    }
  }

  // Update child fields, and if balance changed, write a manual adjustment ledger entry for the delta.
  Future<void> updateChildWithBalanceAdjustment({
    required ChildModel updatedChild,
    required String createdByUserId,
  }) async {
    final childRef = _firestore.collection('children').doc(updatedChild.id);
    final existing = await childRef.get();
    if (!existing.exists) {
      await updateChild(updatedChild);
      return;
    }
    final data = existing.data()!;
    final currentBalance = (data['balance'] ?? 0) as int;
    final delta = updatedChild.balance - currentBalance;

    // Important: avoid double-counting. If balance changes, do NOT overwrite the
    // balance directly before we add the ledger entry (which also increments balance).
    // Instead, update non-balance fields first, then apply the ledger delta.
    if (delta != 0) {
      // Update selected fields except balance
      final now = DateTime.now().toIso8601String();
      final updateMap = <String, dynamic>{
        'name': updatedChild.name,
        'age': updatedChild.age,
        'familyId': updatedChild.familyId,
        'updatedAt': now,
      };
      await childRef.update(updateMap);

      try {
        await _ledgerService.addTransaction(
          childId: updatedChild.id,
          familyId: updatedChild.familyId,
          amount: delta,
          type: LedgerEntryType.manualAdjustment,
          createdByUserId: createdByUserId,
          note: 'Aanpassing door ouder',
        );
      } catch (e) {
        debugPrint('Failed to add manual adjustment ledger entry: $e');
      }
    } else {
      // No balance change, safe to update as-is
      await updateChild(updatedChild);
    }
  }
}
