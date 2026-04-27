import 'package:flutter/material.dart';
import 'package:chorechamp2/core/utils/kids_mode_notifier.dart';

/// Hides [child] when Kids Mode is enabled, while preserving layout space.
///
/// This uses Visibility with maintain* flags so the surrounding layout
/// doesn't shift when hidden. Ideal for hiding controls in kids mode
/// without causing UI jumps.
class HiddenWhenKidsMode extends StatelessWidget {
  const HiddenWhenKidsMode({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final notifier = KidsModeNotifier();
    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        final isKidsMode = notifier.isKidsMode;
        return Visibility(
          visible: !isKidsMode,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: child,
        );
      },
    );
  }
}
