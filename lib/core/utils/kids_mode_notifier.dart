import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KidsModeNotifier extends ChangeNotifier {
  static final KidsModeNotifier _instance = KidsModeNotifier._internal();
  factory KidsModeNotifier() => _instance;
  KidsModeNotifier._internal();

  bool _isKidsMode = false;
  bool get isKidsMode => _isKidsMode;

  static const String _kidsModePrefKey = 'kids_mode_enabled';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isKidsMode = prefs.getBool(_kidsModePrefKey) ?? false;
    notifyListeners();
  }

  Future<void> enableKidsMode() async {
    _isKidsMode = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kidsModePrefKey, true);
  }

  Future<void> disableKidsMode() async {
    _isKidsMode = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kidsModePrefKey, false);
  }
}
