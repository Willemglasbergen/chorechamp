import 'package:flutter/material.dart';
import 'package:chorechamp2/core/routes/app_routes.dart';
import 'package:chorechamp2/core/utils/left_nav_controller.dart';
import 'package:chorechamp2/widgets/hidden_when_kids_mode.dart';
import 'package:chorechamp2/theme.dart';

/// Items in the app's left navigation
enum LeftNavItem { chores, rewards, family }

/// A reusable left navigation pane that can collapse to icons-only.
/// Collapse state is persisted across pages via LeftNavController.instance.
class LeftNavPane extends StatelessWidget {
  const LeftNavPane({super.key, required this.current, required this.isKidsMode, this.userEmail = '', this.onAccountPressed});

  final LeftNavItem current;
  final bool isKidsMode;
  final String userEmail;
  final VoidCallback? onAccountPressed;

  static const double _expandedWidth = 220;
  static const double _collapsedWidth = 72;

  @override
  Widget build(BuildContext context) {
    final controller = LeftNavController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final collapsed = controller.isCollapsed;
        return AnimatedContainer(
          width: collapsed ? _collapsedWidth : _expandedWidth,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            color: LightModeColors.lightPrimary,
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF2B7DE1), Color(0xFF59A1F7)],
              stops: [0.39, 0.8],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collapse/expand toggle
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: collapsed ? 'Uitklappen' : 'Inklappen',
                    onPressed: controller.toggle,
                    icon: Icon(
                      collapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: LightModeColors.lightOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _NavItemRow(
                  icon: Icons.check_circle_outline,
                  label: 'Taken',
                  selected: current == LeftNavItem.chores,
                  showLabel: !collapsed,
                  onTap: current == LeftNavItem.chores
                      ? null
                      : () => Navigator.of(context).pushReplacementNamed(RouteNames.chores),
                ),
                _NavItemRow(
                  icon: Icons.emoji_events_outlined,
                  label: 'Beloningen',
                  selected: current == LeftNavItem.rewards,
                  showLabel: !collapsed,
                  onTap: current == LeftNavItem.rewards
                      ? null
                      : () => Navigator.of(context).pushReplacementNamed(RouteNames.rewards),
                ),
                if (!isKidsMode)
                  _NavItemRow(
                    icon: Icons.family_restroom_outlined,
                    label: 'Familie',
                    selected: current == LeftNavItem.family,
                    showLabel: !collapsed,
                    onTap: current == LeftNavItem.family
                        ? null
                        : () => Navigator.of(context).pushReplacementNamed(RouteNames.family),
                  ),
                const Spacer(),
                // Account action (icon-only when collapsed, shows email when expanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: HiddenWhenKidsMode(
                    child: _AccountButton(
                      showLabel: !collapsed && userEmail.isNotEmpty,
                      label: userEmail,
                      onPressed: onAccountPressed ?? () => Navigator.of(context).pushReplacementNamed(RouteNames.family),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItemRow extends StatelessWidget {
  const _NavItemRow({required this.icon, required this.label, required this.selected, required this.showLabel, this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dot = selected
        ? Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          )
        : const SizedBox(width: 6);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            dot,
            const SizedBox(width: 12),
            Icon(icon, color: LightModeColors.lightOnPrimary),
            if (showLabel) ...[
              const SizedBox(width: 10),
              // Slide + fade the label
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(-0.12, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    label,
                    key: ValueKey<String>(label),
                    style: const TextStyle(
                      color: LightModeColors.lightOnPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.showLabel, required this.label, required this.onPressed});

  final bool showLabel;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final btn = IconButton(
      onPressed: onPressed,
      tooltip: 'Account',
      icon: const Icon(Icons.person, color: LightModeColors.lightOnPrimary),
    );

    if (!showLabel) return btn;

    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.person, color: LightModeColors.lightOnPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: LightModeColors.lightOnPrimary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
