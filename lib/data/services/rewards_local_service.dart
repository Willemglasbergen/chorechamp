import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:chorechamp2/data/models/reward.dart';
import 'package:chorechamp2/data/models/child.dart';
import 'package:chorechamp2/data/services/chores_local_service.dart';

class RewardsLocalService {
  static const _kRewardsKey = 'cc_rewards';

  final _choresService = ChoresLocalService();

  Future<void> seedIfEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_kRewardsKey)) return;

    final children = await _choresService.getChildren();
    final now = DateTime.now();

    // Default statuses: all children 'open'
    Map<String, String> openForAll(List<ChildModel> kids) => {
          for (final c in kids) c.id: 'open',
        };

    final rewards = <RewardModel>[
      RewardModel(
        id: 'r1',
        title: 'Eten bij MC Donalds',
        description: 'Samen eten bij McDonald\'s',
        points: 200,
        familyId: 'local',
        isCombo: true,
        statusByChild: openForAll(children),
        createdAt: now,
        updatedAt: now,
      ),
      RewardModel(
        id: 'r2',
        title: 'Extra schermtijd (30 min)',
        description: 'Een half uur extra schermtijd',
        points: 80,
        familyId: 'local',
        isCombo: false,
        statusByChild: children.isNotEmpty ? {children.first.id: 'open'} : {},
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await prefs.setString(
      _kRewardsKey,
      jsonEncode(rewards.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<RewardModel>> getRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kRewardsKey);
    if (str == null) return [];
    final list = (jsonDecode(str) as List).cast<Map<String, dynamic>>();
    return list.map(RewardModel.fromJson).toList();
  }

  Future<void> saveRewards(List<RewardModel> rewards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kRewardsKey,
      jsonEncode(rewards.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addReward(RewardModel reward) async {
    final rewards = await getRewards();
    rewards.add(reward);
    await saveRewards(rewards);
  }

  Future<RewardModel?> updateReward(RewardModel reward) async {
    final rewards = await getRewards();
    final idx = rewards.indexWhere((r) => r.id == reward.id);
    if (idx == -1) return null;
    rewards[idx] = reward.copyWith(updatedAt: DateTime.now());
    await saveRewards(rewards);
    return rewards[idx];
  }

  Future<RewardModel?> requestReward(String rewardId, String childId) async {
    final rewards = await getRewards();
    final idx = rewards.indexWhere((r) => r.id == rewardId);
    if (idx == -1) return null;
    final r = rewards[idx];
    final map = Map<String, String>.from(r.statusByChild);
    map[childId] = 'pending';
    final updated = r.copyWith(statusByChild: map, updatedAt: DateTime.now());
    rewards[idx] = updated;
    await saveRewards(rewards);
    return updated;
  }

  Future<RewardModel?> fulfillRewardForChild(
      String rewardId, String childId) async {
    final rewards = await getRewards();
    final idx = rewards.indexWhere((r) => r.id == rewardId);
    if (idx == -1) return null;
    final r = rewards[idx];
    final map = Map<String, String>.from(r.statusByChild);
    map[childId] = 'fulfilled';

    // If combo: optionally auto-fulfill all when everyone is pending or fulfilled
    if (r.isCombo) {
      final allRequested =
          map.values.every((s) => s == 'pending' || s == 'fulfilled');
      if (allRequested) {
        for (final k in map.keys) {
          map[k] = 'fulfilled';
        }
      }
    }

    final updated = r.copyWith(statusByChild: map, updatedAt: DateTime.now());
    rewards[idx] = updated;
    await saveRewards(rewards);
    return updated;
  }
}
