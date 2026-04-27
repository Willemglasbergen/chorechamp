import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chorechamp2/data/models/reward.dart';
import 'package:chorechamp2/core/utils/logger.dart';
import 'package:chorechamp2/data/models/child.dart';
import 'package:chorechamp2/data/services/ledger_service.dart';
import 'package:chorechamp2/data/services/auth_service.dart';
import 'package:chorechamp2/data/models/ledger_entry.dart';
import 'package:flutter/foundation.dart';

class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LedgerService _ledgerService = LedgerService();
  final AuthService _authService = AuthService();

  Stream<List<RewardModel>> getRewardsStream(String familyId) {
    return _firestore
        .collection('rewards')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
      final rewards = snapshot.docs
          .map((doc) => RewardModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
      rewards.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return rewards;
    });
  }

  Future<List<RewardModel>> getRewards(String familyId) async {
    final snapshot = await _firestore
        .collection('rewards')
        .where('familyId', isEqualTo: familyId)
        .get();
    final rewards = snapshot.docs
        .map((doc) => RewardModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    rewards.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return rewards;
  }

  Future<void> addReward(RewardModel reward) async {
    final json = reward.toJson();
    json.remove('id');
    await _firestore.collection('rewards').doc(reward.id).set(json);
  }

  Future<RewardModel?> updateReward(RewardModel reward) async {
    final updated = reward.copyWith(updatedAt: DateTime.now());
    final json = updated.toJson();
    json.remove('id');
    await _firestore.collection('rewards').doc(reward.id).update(json);
    return updated;
  }

  // Uploads a resized image for a reward and returns the download URL
  Future<String> uploadRewardImage({
    required String familyId,
    required String rewardId,
    required List<int> bytes,
    required String contentType,
  }) async {
    final ref =
        _storage.ref().child('rewards').child(familyId).child('$rewardId.jpg');
    AppLogger.d(
        'Uploading reward image: familyId=$familyId rewardId=$rewardId bytes=${bytes.length}');
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(
          contentType: contentType, cacheControl: 'public, max-age=604800'),
    );
    final url = await ref.getDownloadURL();
    AppLogger.d('Upload complete: $url');
    return url;
  }

  Future<void> deleteRewardImage({
    required String familyId,
    required String rewardId,
  }) async {
    final ref =
        _storage.ref().child('rewards').child(familyId).child('$rewardId.jpg');
    try {
      await ref.delete();
    } catch (_) {
      // ignore if not found
    }
  }

  Future<void> deleteReward(String rewardId) async {
    await _firestore.collection('rewards').doc(rewardId).delete();
  }

  /// Duplicates an existing reward into a new document with a fresh id.
  ///
  /// - Appends [suffix] to the title.
  /// - When [resetStatuses] is true, all child statuses are reset to 'open'.
  /// - When [copyImage] is true and an image exists, it is copied to the new id path.
  Future<RewardModel> duplicateReward(
    RewardModel original, {
    String suffix = ' (kopie)',
    bool resetStatuses = true,
    bool copyImage = true,
  }) async {
    // Prepare new doc id up-front so we can use it for image path as well
    final newDocRef = _firestore.collection('rewards').doc();
    final newId = newDocRef.id;

    // Build new status map
    final Map<String, String> newStatusByChild =
        Map<String, String>.from(original.statusByChild);
    if (resetStatuses) {
      for (final k in newStatusByChild.keys.toList()) {
        newStatusByChild[k] = 'open';
      }
    }

    // Title with suffix
    final String newTitle = '${original.title}$suffix';

    // Copy image if requested
    String? newImageUrl;
    if (copyImage &&
        (original.imageUrl != null && original.imageUrl!.isNotEmpty)) {
      try {
        final srcRef = _storage
            .ref()
            .child('rewards')
            .child(original.familyId)
            .child('${original.id}.jpg');
        // 10MB cap; originals are ~200x200 so this is safe
        final data = await srcRef.getData(10 * 1024 * 1024);
        if (data != null) {
          final dstRef = _storage
              .ref()
              .child('rewards')
              .child(original.familyId)
              .child('$newId.jpg');
          await dstRef.putData(
            data,
            SettableMetadata(
                contentType: 'image/jpeg',
                cacheControl: 'public, max-age=604800'),
          );
          newImageUrl = await dstRef.getDownloadURL();
        }
      } catch (e) {
        debugPrint('duplicateReward: failed to copy image: $e');
      }
    }

    final now = DateTime.now();
    final duplicated = RewardModel(
      id: newId,
      title: newTitle,
      description: original.description,
      points: original.points,
      familyId: original.familyId,
      isCombo: original.isCombo,
      statusByChild: newStatusByChild,
      createdAt: now,
      updatedAt: now,
      imageUrl: newImageUrl,
    );

    final json = duplicated.toJson();
    json.remove('id');
    await newDocRef.set(json);
    return duplicated;
  }

  Future<RewardModel?> requestReward(String rewardId, String childId) async {
    final doc = await _firestore.collection('rewards').doc(rewardId).get();
    if (!doc.exists) return null;

    final reward = RewardModel.fromJson({'id': doc.id, ...doc.data()!});

    // Check if child/children have enough points
    if (reward.isCombo) {
      // For combo rewards, check if this child has enough points for their share
      final childIds = reward.statusByChild.keys.toList();
      final pointsPerChild = reward.points ~/ childIds.length;
      final remainder = reward.points % childIds.length;
      final isFirstChild = childIds.indexOf(childId) == 0;
      final childShare = pointsPerChild + (isFirstChild ? remainder : 0);

      final childDoc =
          await _firestore.collection('children').doc(childId).get();
      if (!childDoc.exists) return null;

      final child =
          ChildModel.fromJson({'id': childDoc.id, ...childDoc.data()!});
      if (child.balance < childShare) {
        throw Exception('Sorry, maar je hebt nog niet genoeg punten.');
      }
      // Deduct points via ledger entry
      try {
        final uid = _authService.currentUser?.uid ?? '';
        await _ledgerService.addTransaction(
          childId: childId,
          familyId: reward.familyId,
          amount: -childShare,
          type: LedgerEntryType.rewardRequest,
          createdByUserId: uid,
          note: 'Beloning aangevraagd (combo): ${reward.title}',
          relatedId: reward.id,
        );
      } catch (e) {
        debugPrint('Failed to add combo reward ledger entry: $e');
      }

      // Mark this child as committed
      final map = Map<String, String>.from(reward.statusByChild);
      map[childId] = 'committed';

      // Check if all children have committed
      final allCommitted = map.values
          .every((s) => s == 'committed' || s == 'pending' || s == 'fulfilled');
      if (allCommitted) {
        // Change all committed to pending
        for (final key in map.keys) {
          if (map[key] == 'committed') {
            map[key] = 'pending';
          }
        }
      }

      final updated =
          reward.copyWith(statusByChild: map, updatedAt: DateTime.now());
      final json = updated.toJson();
      json.remove('id');
      await _firestore.collection('rewards').doc(rewardId).update(json);
      return updated;
    } else {
      // For regular rewards, check individual child balance
      final childDoc =
          await _firestore.collection('children').doc(childId).get();
      if (!childDoc.exists) return null;

      final child =
          ChildModel.fromJson({'id': childDoc.id, ...childDoc.data()!});
      if (child.balance < reward.points) {
        throw Exception('Sorry, maar je hebt nog niet genoeg punten.');
      }
      // Deduct points via ledger entry
      try {
        final uid = _authService.currentUser?.uid ?? '';
        await _ledgerService.addTransaction(
          childId: childId,
          familyId: reward.familyId,
          amount: -reward.points,
          type: LedgerEntryType.rewardRequest,
          createdByUserId: uid,
          note: 'Beloning aangevraagd: ${reward.title}',
          relatedId: reward.id,
        );
      } catch (e) {
        debugPrint('Failed to add reward ledger entry: $e');
      }

      final map = Map<String, String>.from(reward.statusByChild);
      map[childId] = 'pending';

      final updated =
          reward.copyWith(statusByChild: map, updatedAt: DateTime.now());
      final json = updated.toJson();
      json.remove('id');
      await _firestore.collection('rewards').doc(rewardId).update(json);
      return updated;
    }
  }

  Future<RewardModel?> cancelRewardRequest(
      String rewardId, String childId) async {
    final doc = await _firestore.collection('rewards').doc(rewardId).get();
    if (!doc.exists) return null;

    final reward = RewardModel.fromJson({'id': doc.id, ...doc.data()!});
    final currentStatus = reward.statusByChild[childId];

    // Only allow canceling if status is 'committed'
    if (currentStatus != 'committed') return null;

    // Refund points to child via ledger
    if (reward.isCombo) {
      final childIds = reward.statusByChild.keys.toList();
      final pointsPerChild = reward.points ~/ childIds.length;
      final remainder = reward.points % childIds.length;
      final isFirstChild = childIds.indexOf(childId) == 0;
      final childShare = pointsPerChild + (isFirstChild ? remainder : 0);

      final childDoc =
          await _firestore.collection('children').doc(childId).get();
      if (childDoc.exists) {
        try {
          final uid = _authService.currentUser?.uid ?? '';
          await _ledgerService.addTransaction(
            childId: childId,
            familyId: reward.familyId,
            amount: childShare,
            type: LedgerEntryType.rewardCancel,
            createdByUserId: uid,
            note: 'Beloning geannuleerd (combo): ${reward.title}',
            relatedId: reward.id,
          );
        } catch (e) {
          debugPrint('Failed to add combo reward cancel ledger entry: $e');
        }
      }
    } else {
      final childDoc =
          await _firestore.collection('children').doc(childId).get();
      if (childDoc.exists) {
        try {
          final uid = _authService.currentUser?.uid ?? '';
          await _ledgerService.addTransaction(
            childId: childId,
            familyId: reward.familyId,
            amount: reward.points,
            type: LedgerEntryType.rewardCancel,
            createdByUserId: uid,
            note: 'Beloning geannuleerd: ${reward.title}',
            relatedId: reward.id,
          );
        } catch (e) {
          debugPrint('Failed to add reward cancel ledger entry: $e');
        }
      }
    }

    // Change status back to open
    final map = Map<String, String>.from(reward.statusByChild);
    map[childId] = 'open';

    final updated =
        reward.copyWith(statusByChild: map, updatedAt: DateTime.now());
    final json = updated.toJson();
    json.remove('id');
    await _firestore.collection('rewards').doc(rewardId).update(json);
    return updated;
  }

  Future<RewardModel?> fulfillRewardForChild(
      String rewardId, String childId) async {
    final doc = await _firestore.collection('rewards').doc(rewardId).get();
    if (!doc.exists) return null;

    final reward = RewardModel.fromJson({'id': doc.id, ...doc.data()!});
    final map = Map<String, String>.from(reward.statusByChild);
    map[childId] = 'fulfilled';

    if (reward.isCombo) {
      final allRequested =
          map.values.every((s) => s == 'pending' || s == 'fulfilled');
      if (allRequested) {
        for (final k in map.keys) {
          map[k] = 'fulfilled';
        }
      }
    }

    final updated =
        reward.copyWith(statusByChild: map, updatedAt: DateTime.now());
    final json = updated.toJson();
    json.remove('id');
    await _firestore.collection('rewards').doc(rewardId).update(json);
    return updated;
  }
}
