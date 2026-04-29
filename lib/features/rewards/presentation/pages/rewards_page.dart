import 'package:chorechamp2/core/utils/format.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:confetti/confetti.dart';
// File picking is handled via a small cross-platform helper.
// On web we use a native <input type="file"> to avoid plugin init issues.
import 'package:chorechamp2/core/utils/image_picker_bytes.dart';
import 'package:image/image.dart' as img;
import 'package:chorechamp2/widgets/app_top_bar.dart';
import 'package:chorechamp2/data/services/children_service.dart';
import 'package:chorechamp2/data/services/rewards_service.dart';
import 'package:chorechamp2/data/services/auth_service.dart';
import 'package:chorechamp2/data/models/child.dart';
import 'package:chorechamp2/data/models/reward.dart';
import 'package:chorechamp2/core/utils/kids_mode_notifier.dart';
import 'package:chorechamp2/core/utils/logger.dart';
import 'package:chorechamp2/widgets/left_nav_pane.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final _childrenService = ChildrenService();
  final _rewardsService = RewardsService();
  final _authService = AuthService();
  final _kidsModeNotifier = KidsModeNotifier();

  List<ChildModel> _children = const [];
  List<RewardModel> _rewards = const [];
  String? _familyId;
  bool _isLoading = true;

  final Map<String, int> _filterByChild = {};

  @override
  void initState() {
    super.initState();
    _kidsModeNotifier.addListener(_onKidsModeChanged);
    _load();
  }

  @override
  void dispose() {
    _kidsModeNotifier.removeListener(_onKidsModeChanged);
    super.dispose();
  }

  void _onKidsModeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentAppUser();
      if (user != null) {
        final kids = await _childrenService.getChildren(user.id);
        final rewards = await _rewardsService.getRewards(user.id);
        setState(() {
          _familyId = user.id;
          _children = kids;
          _rewards = rewards;
          for (final c in kids) {
            _filterByChild.putIfAbsent(c.id, () => 0);
          }
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKidsMode = _kidsModeNotifier.isKidsMode;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      appBar: AppTopBar(showMenuButton: isMobile),
      drawer: isMobile
          ? NavDrawer(current: LeftNavItem.rewards, isKidsMode: isKidsMode)
          : null,
      floatingActionButton: (_familyId != null && !isKidsMode)
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                await _openRewardDialog(editing: null);
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile)
            LeftNavPane(
                current: LeftNavItem.rewards,
                isKidsMode: isKidsMode,
                userEmail: ''),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                              accent: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          LayoutBuilder(builder: (context, c) {
                            final isTwoCols = c.maxWidth >= 900;
                            return Wrap(
                              spacing: 24,
                              runSpacing: isTwoCols ? 16 : 36,
                              children: _children.map((child) {
                                final width = isTwoCols
                                    ? (c.maxWidth - 24) / 2
                                    : c.maxWidth;
                                final statusIndex =
                                    _filterByChild[child.id] ?? 0;
                                final status = [
                                  'open',
                                  'pending',
                                  'fulfilled'
                                ][statusIndex];
                                final items = _rewards.where((r) {
                                  final childStatus = r.statusByChild[child.id];
                                  if (status == 'open') {
                                    return childStatus == 'open' ||
                                        childStatus == 'committed';
                                  }
                                  return childStatus == status;
                                }).toList();
                                return SizedBox(
                                  width: width,
                                  child: _ChildRewardsPanel(
                                    child: child,
                                    rewards: items,
                                    selectedIndex: statusIndex,
                                    isKidsMode: isKidsMode,
                                    onFilterChange: (i) => setState(
                                        () => _filterByChild[child.id] = i),
                                    onRequest: (reward) async {
                                      try {
                                        await _rewardsService.requestReward(
                                            reward.id, child.id);
                                        await _load();
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(e
                                                  .toString()
                                                  .replaceAll(
                                                      'Exception: ', '')),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    onCancel: (reward) async {
                                      await _rewardsService.cancelRewardRequest(
                                          reward.id, child.id);
                                      await _load();
                                    },
                                    onFulfill: (reward) async {
                                      await _rewardsService
                                          .fulfillRewardForChild(
                                              reward.id, child.id);
                                      await _load();
                                    },
                                    onEdit: (reward) async {
                                      await _openRewardDialog(editing: reward);
                                    },
                                    onDuplicate: (reward) async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                              'Beloning dupliceren?'),
                                          content: Text(
                                              'Een kopie van "${reward.title}" wordt aangemaakt met dezelfde instellingen en titel met suffix.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('Annuleren'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('Dupliceer'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm != true) return;
                                      try {
                                        final newReward = await _rewardsService
                                            .duplicateReward(
                                          reward,
                                          suffix: ' (kopie)',
                                          resetStatuses: true,
                                          copyImage: true,
                                        );
                                        await _load();
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Beloning gedupliceerd.')),
                                        );
                                        await _openRewardDialog(
                                            editing: newReward);
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Dupliceren mislukt: $e'),
                                              backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                                    peopleIcon: Icon(Icons.group_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20),
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                          const SizedBox(height: 80),
                        ]),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRewardDialog({RewardModel? editing}) async {
    if (_familyId == null) return;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
          child: Center(
            child: _AddRewardDialog(
              children: _children,
              familyId: _familyId!,
              onSave: (reward) async {
                if (editing == null) {
                  await _rewardsService.addReward(reward);
                } else {
                  await _rewardsService.updateReward(reward);
                }
                await _load();
              },
              editingReward: editing,
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.star, color: accent),
        ),
        const SizedBox(width: 10),
        Text("Beloningen",
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87)),
      ]),
    );
  }
}

class _ChildRewardsPanel extends StatelessWidget {
  const _ChildRewardsPanel({
    required this.child,
    required this.rewards,
    required this.selectedIndex,
    required this.onFilterChange,
    required this.onRequest,
    required this.onCancel,
    required this.onFulfill,
    required this.onEdit,
    required this.onDuplicate,
    required this.peopleIcon,
    required this.isKidsMode,
  });
  final ChildModel child;
  final List<RewardModel> rewards;
  final int selectedIndex;
  final ValueChanged<int> onFilterChange;
  final ValueChanged<RewardModel> onRequest;
  final ValueChanged<RewardModel> onCancel;
  final ValueChanged<RewardModel> onFulfill;
  final ValueChanged<RewardModel> onEdit;
  final ValueChanged<RewardModel> onDuplicate;
  final Widget peopleIcon;
  final bool isKidsMode;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                child.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          _PointsBadge(points: child.balance),
        ],
      ),
      const SizedBox(height: 6),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        child: _FilterTabs(
            selectedIndex: selectedIndex, onChanged: onFilterChange),
      ),
      const SizedBox(height: 32),
      ...rewards.map(
        (r) => _RewardCard(
          reward: r,
          child: child,
          onRequest: onRequest,
          onCancel: onCancel,
          onFulfill: onFulfill,
          onEdit: onEdit,
          onDuplicate: onDuplicate,
          peopleIcon: peopleIcon,
          isKidsMode: isKidsMode,
        ),
      ),
    ]);
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String text, int idx) {
      final isSelected = selectedIndex == idx;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          selected: isSelected,
          onSelected: (_) => onChanged(idx),
          label: Text(text),
          labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87),
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.grey[200],
          side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent),
        ),
      );
    }

    return Row(children: [
      tab('Open', 0),
      tab('Aangevraagd', 1),
      tab('Ontvangen', 2),
    ]);
  }
}

class _RewardCard extends StatefulWidget {
  const _RewardCard({
    required this.reward,
    required this.child,
    required this.onRequest,
    required this.onCancel,
    required this.onFulfill,
    required this.onEdit,
    required this.onDuplicate,
    required this.peopleIcon,
    required this.isKidsMode,
  });
  final RewardModel reward;
  final ChildModel child;
  final ValueChanged<RewardModel> onRequest;
  final ValueChanged<RewardModel> onCancel;
  final ValueChanged<RewardModel> onFulfill;
  final ValueChanged<RewardModel> onEdit;
  final ValueChanged<RewardModel> onDuplicate;
  final Widget peopleIcon;
  final bool isKidsMode;

  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti =
        ConfettiController(duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final child = widget.child;
    final status = reward.statusByChild[child.id] ?? 'open';
    final isOpen = status == 'open';
    final isCommitted = status == 'committed';
    final isPending = status == 'pending';
    final canEdit = !widget.isKidsMode;
    final primary = Theme.of(context).colorScheme.primary;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    final secondary = Theme.of(context).colorScheme.secondary;

    String? progressText;
    if (reward.isCombo && (isOpen || isCommitted)) {
      final totalChildren = reward.statusByChild.length;
      final committedCount = reward.statusByChild.values
          .where((s) => s == 'committed' || s == 'pending' || s == 'fulfilled')
          .length;
      if (committedCount > 0) {
        progressText =
            '$committedCount/$totalChildren kinderen hebben dit aangevraagd';
      }
    }

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 44),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RewardCardImage(imageUrl: reward.imageUrl),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              reward.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (reward.isCombo) ...[
                            const SizedBox(width: 6),
                            widget.peopleIcon,
                          ],
                          if (canEdit) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: Colors.grey[500],
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              tooltip: 'Bewerk beloning',
                              onPressed: () => widget.onEdit(reward),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              color: Colors.grey[500],
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              tooltip: 'Dupliceer beloning',
                              onPressed: () => widget.onDuplicate(reward),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: tertiary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: tertiary.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 16, color: tertiary),
                            const SizedBox(width: 5),
                            Text(
                              '${reward.points} punten',
                              style: const TextStyle(
                                color: Color(0xFF7A5500),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (progressText != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 7, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  progressText,
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (isOpen)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.isKidsMode &&
                                  child.balance >= reward.points) {
                                _confetti.play();
                              }
                              widget.onRequest(reward);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('\u{1F389}',
                                    style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8),
                                Text(
                                  'Aanvragen!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isCommitted)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Text('⏳', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Wachten op broer of zus...',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => widget.onCancel(reward),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.close,
                                      size: 18, color: Colors.black38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isPending)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: secondary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_top_rounded,
                                  size: 16, color: secondary),
                              const SizedBox(width: 6),
                              const Text(
                                'Beloning aangevraagd!',
                                style: TextStyle(
                                  color: Color(0xFF003826),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          maxBlastForce: 30,
          minBlastForce: 12,
          emissionFrequency: 0.04,
          gravity: 0.35,
          colors: const [
            Color(0xFF2B7DE1),
            Color(0xFF5FD4A8),
            Color(0xFFFDB748),
            Color(0xFFFF6B6B),
            Color(0xFFFF9FF3),
            Color(0xFFFFFFFF),
          ],
        ),
      ],
    );
  }
}

class _RewardCardImage extends StatelessWidget {
  const _RewardCardImage({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final placeholder = Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            primary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.card_giftcard_rounded,
        color: primary.withValues(alpha: 0.35),
        size: 64,
      ),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return Image.network(
      imageUrl!,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

class _RewardImage extends StatelessWidget {
  const _RewardImage({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double size = screenWidth * 0.15; // Max 15% of screen width
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.white70, size: 48),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Builder(
        builder: (context) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16)),
              child: Text('${Format.points(points)} punten',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ));
  }
}

class _AddRewardDialog extends StatefulWidget {
  const _AddRewardDialog(
      {required this.children,
      required this.familyId,
      required this.onSave,
      this.editingReward});
  final List<ChildModel> children;
  final String familyId;
  final ValueChanged<RewardModel> onSave;
  final RewardModel? editingReward;

  @override
  State<_AddRewardDialog> createState() => _AddRewardDialogState();
}

class _AddRewardDialogState extends State<_AddRewardDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();

  String _status = 'open';
  bool _isCombo = false;
  late Set<String> _selectedChildren;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  bool _isUploadingImage = false;
  late final String _draftRewardId;
  String? _imageStatusText;
  Color _imageStatusColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingReward;
    if (editing != null) {
      _titleCtrl.text = editing.title;
      _descCtrl.text = editing.description;
      _pointsCtrl.text = editing.points.toString();
      _isCombo = editing.isCombo;
      _selectedChildren = editing.statusByChild.keys.toSet();
      _existingImageUrl = editing.imageUrl;
      _status = editing.statusByChild.values.isNotEmpty
          ? editing.statusByChild.values.first
          : 'open';
      _draftRewardId = editing.id;
    } else {
      _selectedChildren =
          widget.children.isNotEmpty ? {widget.children.first.id} : <String>{};
      _draftRewardId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.editingReward != null
                          ? 'Bewerk Beloning'
                          : 'Nieuwe Beloning',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  widget.editingReward != null
                      ? 'Pas de beloning aan.'
                      : 'Maak hier een nieuwe beloning aan voor jouw kinderen.',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),

              _ImagePickerRow(
                imageBytes: _imageBytes,
                imageUrl: _existingImageUrl,
                onPick: _onPickImage,
                onClear: () async {
                  try {
                    final svc = RewardsService();
                    await svc.deleteRewardImage(
                      familyId: widget.familyId,
                      rewardId: _draftRewardId,
                    );
                  } catch (_) {}
                  if (mounted) {
                    setState(() {
                      _imageBytes = null;
                      _existingImageUrl = null;
                      _imageStatusText = 'Afbeelding verwijderd';
                      _imageStatusColor = Colors.black54;
                    });
                  }
                },
                isUploading: _isUploadingImage,
                statusText: _imageStatusText,
                statusColor: _imageStatusColor,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                      value: 'fulfilled', child: Text('Fullfilled')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'open'),
                decoration: _inputDecoration('Status'),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _titleCtrl,
                decoration: _inputDecoration('Naam'),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _descCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: _inputDecoration('Omschrijving'),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Aantal punten'),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(
                      child: Text(
                          'Beloning die door beide kinderen moet worden betaald:')),
                  Switch(
                    value: _isCombo,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    onChanged: (v) {
                      setState(() {
                        _isCombo = v;
                        if (v) {
                          _selectedChildren =
                              widget.children.map((c) => c.id).toSet();
                        } else if (_selectedChildren.isEmpty &&
                            widget.children.isNotEmpty) {
                          _selectedChildren = {widget.children.first.id};
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Text('Beloning voor kinderen:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: widget.children.map((c) {
                  final checked = _selectedChildren.contains(c.id);
                  return SizedBox(
                    width: 220,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(c.name),
                      value: checked,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedChildren.add(c.id);
                          } else {
                            _selectedChildren.remove(c.id);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary)),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text('Annuleren'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Text('Opslaan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Future<void> _onSave() async {
    final editing = widget.editingReward;
    final id = _draftRewardId;
    final now = DateTime.now();
    final points = int.tryParse(_pointsCtrl.text.trim()) ?? 0;
    final sel = _selectedChildren;
    if (sel.isEmpty) return;

    final map = {
      for (final childId in sel) childId: editing != null ? _status : 'open'
    };

    String? imageUrl = _existingImageUrl;
    if (imageUrl == null && _imageBytes != null) {
      try {
        final service = RewardsService();
        imageUrl = await service.uploadRewardImage(
          familyId: widget.familyId,
          rewardId: id,
          bytes: _imageBytes!,
          contentType: 'image/jpeg',
        );
        if (mounted) {
          _imageStatusText = 'Afbeelding geüpload.';
          _imageStatusColor = Colors.green[700]!;
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          _imageStatusText = 'Upload mislukt: $e';
          _imageStatusColor = Colors.red[700]!;
          setState(() {});
        }
      }
    }

    final reward = RewardModel(
      id: id,
      title:
          _titleCtrl.text.trim().isEmpty ? 'Beloning' : _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      points: points,
      familyId: widget.familyId,
      isCombo: _isCombo,
      statusByChild: map,
      createdAt: editing?.createdAt ?? now,
      updatedAt: now,
      imageUrl: imageUrl,
    );

    widget.onSave(reward);
    Navigator.pop(context);
  }

  Future<void> _onPickImage() async {
    AppLogger.d('Image pick started');
    if (mounted) {
      setState(() {
        _imageStatusText = 'Bestand kiezen…';
        _imageStatusColor = Colors.black54;
      });
    }
    final picked = await pickSingleImageBytes();
    if (picked == null) {
      if (mounted) {
        setState(() {
          _imageStatusText = 'Geen afbeelding gekozen.';
          _imageStatusColor = Colors.black54;
        });
      }
      return;
    }
    final data = picked.bytes;
    final size = data.length;
    const max = 10 * 1024 * 1024;
    if (size > max) {
      if (mounted) {
        _imageStatusText = 'Bestand is groter dan 10 MB.';
        _imageStatusColor = Colors.red[700]!;
        setState(() {});
      }
      return;
    }
    try {
      AppLogger.d(
          'Picked image: name=${picked.fileName} mime=${picked.mimeType} bytes=$size');
      final decoded = img.decodeImage(data);
      if (decoded == null) {
        throw 'Ongeldig afbeeldingsformaat';
      }
      AppLogger.d('Decoded image: ${decoded.width}x${decoded.height}');
      final minSide =
          decoded.width < decoded.height ? decoded.width : decoded.height;
      final offsetX = (decoded.width - minSide) ~/ 2;
      final offsetY = (decoded.height - minSide) ~/ 2;
      final cropped = img.copyCrop(decoded,
          x: offsetX, y: offsetY, width: minSide, height: minSide);
      final resized = img.copyResize(cropped,
          width: 200, height: 200, interpolation: img.Interpolation.cubic);
      final jpg = img.encodeJpg(resized, quality: 85);
      setState(() {
        _imageBytes = Uint8List.fromList(jpg);
        _imageStatusText = 'Voorbeeld klaar. Start upload…';
        _imageStatusColor = Colors.black54;
      });
      setState(() {
        _isUploadingImage = true;
      });
      try {
        final service = RewardsService();
        final url = await service.uploadRewardImage(
          familyId: widget.familyId,
          rewardId: _draftRewardId,
          bytes: jpg,
          contentType: 'image/jpeg',
        );
        if (!mounted) return;
        setState(() {
          _existingImageUrl = url;
          _imageStatusText = 'Afbeelding geüpload. Voorbeeld bijgewerkt.';
          _imageStatusColor = Colors.green[700]!;
        });
        AppLogger.d('Image upload completed: $url');
      } catch (e) {
        if (mounted) {
          _imageStatusText = 'Upload mislukt: $e';
          _imageStatusColor = Colors.red[700]!;
          setState(() {});
          AppLogger.e('Image upload failed: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _imageStatusText = 'Afbeelding verwerken mislukt: $e';
        _imageStatusColor = Colors.red[700]!;
        setState(() {});
        AppLogger.e('Image processing failed: $e');
      }
    }
  }
}

class _ImagePickerRow extends StatelessWidget {
  const _ImagePickerRow({
    required this.imageBytes,
    required this.imageUrl,
    required this.onPick,
    required this.onClear,
    this.isUploading = false,
    this.statusText,
    this.statusColor,
  });
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool isUploading;
  final String? statusText;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final preview = imageBytes != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(imageBytes!,
                width: 200, height: 200, fit: BoxFit.cover),
          )
        : _RewardImage(imageUrl: imageUrl);

    Widget rightColumn() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label:
                  Text(isUploading ? 'Bezig met uploaden…' : 'Kies afbeelding'),
              onPressed: isUploading ? null : onPick,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
            if (isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: SizedBox(width: 200, child: LinearProgressIndicator()),
              ),
            const SizedBox(height: 8),
            if (statusText != null)
              Text(
                statusText!,
                style: TextStyle(
                    fontSize: 12, color: statusColor ?? Colors.black54),
              ),
            if (statusText != null) const SizedBox(height: 8),
            Text(
              '200 x 200 px, JPG/PNG, max 10 MB',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: (imageBytes != null ||
                      (imageUrl != null && imageUrl!.isNotEmpty))
                  ? onClear
                  : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Verwijder afbeelding'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              preview,
              const SizedBox(height: 12),
              rightColumn(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            preview,
            const SizedBox(width: 12),
            Expanded(child: rightColumn()),
          ],
        );
      },
    );
  }
}
