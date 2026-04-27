import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chorechamp2/data/models/child.dart';
import 'package:chorechamp2/data/models/chore.dart';

enum ChoreToggleResult { completed, uncompleted, blockedByDeadline, blockedByDate, notFound }

class ChoresLocalService {
  static const _kChildrenKey = 'cc_children';
  static const _kChoresKey = 'cc_chores';

  Future<void> seedIfEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    final hasChildren = prefs.containsKey(_kChildrenKey);
    final hasChores = prefs.containsKey(_kChoresKey);
    if (hasChildren && hasChores) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final children = [
      ChildModel(id: 'c1', name: 'childName1', age: 8, familyId: 'local', balance: 100, createdAt: now, updatedAt: now),
      ChildModel(id: 'c2', name: 'childName2', age: 10, familyId: 'local', balance: 160, createdAt: now, updatedAt: now),
    ];

    final chores = [
      ChoreModel(
        id: 'ch1',
        title: 'Tanden poetsen',
        time: const TimeOfDay(hour: 8, minute: 30),
        points: 20,
        date: today,
        childIds: ['c1'],
        familyId: 'local',
        completedByChildIds: [],
        createdAt: now,
        updatedAt: now,
      ),
      ChoreModel(
        id: 'ch2',
        title: 'Tanden poetsen',
        time: const TimeOfDay(hour: 8, minute: 30),
        points: 20,
        date: today,
        childIds: ['c2'],
        familyId: 'local',
        completedByChildIds: [],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await prefs.setString(_kChildrenKey, jsonEncode(children.map((e) => e.toJson()).toList()));
    await prefs.setString(_kChoresKey, jsonEncode(chores.map((e) => e.toJson()).toList()));
  }

  Future<List<ChildModel>> getChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kChildrenKey);
    if (str == null) return [];
    final list = (jsonDecode(str) as List).cast<Map<String, dynamic>>();
    return list.map(ChildModel.fromJson).toList();
  }

  Future<void> upsertChild(ChildModel child) async {
    final prefs = await SharedPreferences.getInstance();
    final children = await getChildren();
    final idx = children.indexWhere((c) => c.id == child.id);
    if (idx == -1) {
      children.add(child);
    } else {
      children[idx] = child.copyWith(updatedAt: DateTime.now());
    }
    await prefs.setString(_kChildrenKey, jsonEncode(children.map((e) => e.toJson()).toList()));
  }

  Future<List<ChoreModel>> getChoresForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kChoresKey);
    if (str == null) return [];
    final target = DateTime(date.year, date.month, date.day);
    final list = (jsonDecode(str) as List).cast<Map<String, dynamic>>();
    return list.map(ChoreModel.fromJson).where((c) {
      final d = DateTime(c.date.year, c.date.month, c.date.day);
      return d == target;
    }).toList();
  }

  Future<void> addChore(ChoreModel chore) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kChoresKey);
    final list = str == null ? <ChoreModel>[] : (jsonDecode(str) as List).cast<Map<String, dynamic>>().map(ChoreModel.fromJson).toList();
    list.add(chore);
    await prefs.setString(_kChoresKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveChores(List<ChoreModel> chores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kChoresKey, jsonEncode(chores.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveChildren(List<ChildModel> children) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kChildrenKey, jsonEncode(children.map((e) => e.toJson()).toList()));
  }

  // Legacy toggle without rules (kept if other callers use it)
  Future<void> toggleChoreCompletion(String choreId) async {
    final prefs = await SharedPreferences.getInstance();

    final choresStr = prefs.getString(_kChoresKey);
    if (choresStr == null) return;
    final chores = (jsonDecode(choresStr) as List)
        .cast<Map<String, dynamic>>()
        .map(ChoreModel.fromJson)
        .toList();

    final idx = chores.indexWhere((c) => c.id == choreId);
    if (idx == -1) return;

    final chore = chores[idx];
    final firstChildId = chore.childIds.isNotEmpty ? chore.childIds.first : '';
    final isCurrentlyCompleted = chore.completedByChildIds.contains(firstChildId);
    final nowCompleted = !isCurrentlyCompleted;
    
    List<String> updatedCompletedIds = List.from(chore.completedByChildIds);
    if (nowCompleted) {
      updatedCompletedIds.add(firstChildId);
    } else {
      updatedCompletedIds.remove(firstChildId);
    }
    
    final updatedChore = chore.copyWith(completedByChildIds: updatedCompletedIds, updatedAt: DateTime.now());
    chores[idx] = updatedChore;

    final children = await getChildren();
    final childIdx = children.indexWhere((c) => c.id == firstChildId);
    if (childIdx != -1) {
      final child = children[childIdx];
      final delta = nowCompleted ? chore.points : -chore.points;
      final newBalance = (child.balance + delta).clamp(0, 1 << 31);
      children[childIdx] = child.copyWith(balance: newBalance, updatedAt: DateTime.now());
    }

    await _saveChores(chores);
    await _saveChildren(children);
  }

  Future<ChoreToggleResult> toggleChoreWithRules(String choreId, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();

    final choresStr = prefs.getString(_kChoresKey);
    if (choresStr == null) return ChoreToggleResult.notFound;
    final chores = (jsonDecode(choresStr) as List)
        .cast<Map<String, dynamic>>()
        .map(ChoreModel.fromJson)
        .toList();

    final idx = chores.indexWhere((c) => c.id == choreId);
    if (idx == -1) return ChoreToggleResult.notFound;

    final chore = chores[idx];
    final today = DateTime(now.year, now.month, now.day);
    final choreDay = DateTime(chore.date.year, chore.date.month, chore.date.day);

    if (choreDay != today) {
      return ChoreToggleResult.blockedByDate;
    }

    final due = DateTime(chore.date.year, chore.date.month, chore.date.day, chore.time.hour, chore.time.minute);
    final deadlinePassed = !now.isBefore(due); // block at or after due time

    if (deadlinePassed) {
      // After deadline: block any changes (cannot complete, cannot undo)
      return ChoreToggleResult.blockedByDeadline;
    }

    // Before deadline: allow toggle and adjust balance accordingly
    final firstChildId = chore.childIds.isNotEmpty ? chore.childIds.first : '';
    final isCurrentlyCompleted = chore.completedByChildIds.contains(firstChildId);
    final nowCompleted = !isCurrentlyCompleted;
    
    List<String> updatedCompletedIds = List.from(chore.completedByChildIds);
    if (nowCompleted) {
      updatedCompletedIds.add(firstChildId);
    } else {
      updatedCompletedIds.remove(firstChildId);
    }
    
    chores[idx] = chore.copyWith(completedByChildIds: updatedCompletedIds, updatedAt: now);

    final children = await getChildren();
    final childIdx = children.indexWhere((c) => c.id == firstChildId);
    if (childIdx != -1) {
      final child = children[childIdx];
      final delta = nowCompleted ? chore.points : -chore.points;
      final newBalance = (child.balance + delta).clamp(0, 1 << 31);
      children[childIdx] = child.copyWith(balance: newBalance, updatedAt: now);
    }

    await _saveChores(chores);
    await _saveChildren(children);

    return nowCompleted ? ChoreToggleResult.completed : ChoreToggleResult.uncompleted;
  }
}
