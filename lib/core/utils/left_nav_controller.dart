import 'package:flutter/foundation.dart';

/// Global controller for the Left Navigation Pane collapsed/expanded state.
/// Keeps state in-memory so it persists across pages during the app session.
class LeftNavController extends ChangeNotifier {
  LeftNavController._();

  static final LeftNavController instance = LeftNavController._();

  bool _isCollapsed = false;

  bool get isCollapsed => _isCollapsed;

  void setCollapsed(bool value) {
    if (_isCollapsed == value) return;
    _isCollapsed = value;
    notifyListeners();
  }

  void toggle() => setCollapsed(!isCollapsed);
}
