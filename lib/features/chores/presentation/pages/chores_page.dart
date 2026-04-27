import 'package:chorechamp2/core/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:chorechamp2/data/models/child.dart';
import 'package:chorechamp2/data/models/chore.dart';
import 'package:chorechamp2/data/services/chores_service.dart';
import 'package:chorechamp2/data/services/children_service.dart';
import 'package:chorechamp2/data/services/auth_service.dart';
import 'package:chorechamp2/widgets/app_top_bar.dart';
import 'package:chorechamp2/core/routes/app_routes.dart';
import 'package:chorechamp2/theme.dart';
import 'package:chorechamp2/core/utils/kids_mode_notifier.dart';
import 'package:chorechamp2/widgets/hidden_when_kids_mode.dart';
import 'package:chorechamp2/widgets/left_nav_pane.dart';

class ChoresPage extends StatefulWidget {
  const ChoresPage({super.key});

  @override
  State<ChoresPage> createState() => _ChoresPageState();
}

class _ChoresPageState extends State<ChoresPage> {
  final _choresService = ChoresService();
  final _childrenService = ChildrenService();
  final _authService = AuthService();
  final _kidsModeNotifier = KidsModeNotifier();
  DateTime _selectedDate = DateTime.now();
  List<ChildModel> _children = const [];
  List<ChoreModel> _chores = const [];
  String? _familyId;
  bool _isLoading = true;

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
        final children = await _childrenService.getChildren(user.id);
        final chores =
            await _choresService.getChoresForDate(user.id, _selectedDate);
        setState(() {
          _familyId = user.id;
          _children = children;
          _chores = chores;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeDay(int delta) async {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: delta)));
    if (_familyId != null) {
      final chores =
          await _choresService.getChoresForDate(_familyId!, _selectedDate);
      setState(() => _chores = chores);
    }
  }

  String _formatDutchDate(DateTime d) {
    const months = [
      'januari',
      'februari',
      'maart',
      'april',
      'mei',
      'juni',
      'juli',
      'augustus',
      'september',
      'oktober',
      'november',
      'december'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isKidsMode = _kidsModeNotifier.isKidsMode;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      appBar: AppTopBar(showMenuButton: isMobile),
      drawer: isMobile
          ? NavDrawer(current: LeftNavItem.chores, isKidsMode: isKidsMode)
          : null,
      backgroundColor: Colors.white,
      floatingActionButton: (_familyId != null && !isKidsMode)
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => _AddChoreDialog(
                    children: _children,
                    date: _selectedDate,
                    familyId: _familyId!,
                    onSave: (newChore) async {
                      await _choresService.addChore(newChore);
                      await _load();
                    },
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile)
            LeftNavPane(
                current: LeftNavItem.chores,
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
                        _Header(accent: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 8),
                        _DateSelector(
                          dateLabelTop:
                              _isSameDate(_selectedDate, DateTime.now())
                                  ? 'Today'
                                  : '',
                          dateText: _formatDutchDate(_selectedDate),
                          onPrev: () => _changeDay(-1),
                          onNext: () => _changeDay(1),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, c) {
                            final isTwoCols = c.maxWidth >= 900;
                            final children = _children;
                            return Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 24,
                              runSpacing: 16,
                              children: children.map((child) {
                                final childChores = _chores
                                    .where((e) => e.childIds.contains(child.id))
                                    .toList();
                                final width = isTwoCols
                                    ? (c.maxWidth - 24) / 2
                                    : c.maxWidth;
                                return SizedBox(
                                    width: width,
                                    child: _ChildPanel(
                                      child: child,
                                      chores: childChores,
                                      service: _choresService,
                                      onChanged: _load,
                                      allChildren: children,
                                      isKidsMode: isKidsMode,
                                      selectedDate: _selectedDate,
                                    ));
                              }).toList(),
                            );
                          },
                        )
                      ],
                    ),
                  ),
          )
        ],
      ),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.check_circle, color: accent),
          ),
          const SizedBox(width: 10),
          Text('Taken',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector(
      {required this.dateLabelTop,
      required this.dateText,
      required this.onPrev,
      required this.onNext});
  final String dateLabelTop;
  final String dateText;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        if (dateLabelTop.isNotEmpty)
          Center(
              child: Text("Vandaag",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: LightModeColors.lightSecondary,
                  ))),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left, color: Colors.grey)),
            Text(dateText,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _ChildPanel extends StatelessWidget {
  const _ChildPanel(
      {required this.child,
      required this.chores,
      required this.service,
      required this.onChanged,
      required this.allChildren,
      required this.isKidsMode,
      required this.selectedDate});
  final ChildModel child;
  final List<ChoreModel> chores;
  final ChoresService service;
  final VoidCallback onChanged;
  final List<ChildModel> allChildren;
  final bool isKidsMode;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(child.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
            _PointsBadge(points: child.balance),
          ],
        ),
        ...chores
            .map((c) => _ChoreRow(
                  chore: c,
                  childId: child.id,
                  selectedDate: selectedDate,
                  onToggle: () => service.toggleChoreWithRules(
                      c.id, child.id, DateTime.now()),
                  onApprove: () =>
                      service.approveChore(c.id, child.id, selectedDate),
                  onReject: () =>
                      service.rejectChore(c.id, child.id, selectedDate),
                  onChanged: onChanged,
                  allChildren: allChildren,
                  isKidsMode: isKidsMode,
                ))
            .toList(),
      ],
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
              margin: EdgeInsets.all(16),
              child: Text('${Format.points(points)} punten',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ));
  }
}

class _ChoreRow extends StatefulWidget {
  const _ChoreRow(
      {required this.chore,
      required this.childId,
      required this.selectedDate,
      required this.onToggle,
      required this.onApprove,
      required this.onReject,
      required this.onChanged,
      required this.allChildren,
      required this.isKidsMode});
  final ChoreModel chore;
  final String childId;
  final DateTime selectedDate;
  final Future<ChoreToggleResult> Function() onToggle;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final VoidCallback onChanged;
  final List<ChildModel> allChildren;
  final bool isKidsMode;

  @override
  State<_ChoreRow> createState() => _ChoreRowState();
}

class _ChoreRowState extends State<_ChoreRow> {
  late final ConfettiController _confettiController;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _showEditDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => _EditChoreDialog(
        chore: widget.chore,
        allChildren: widget.allChildren,
        onSave: (updatedChore) async {
          await ChoresService().updateChore(updatedChore);
          widget.onChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = widget.selectedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isToday = today == selected;

    final dateKey =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final completionKey = '${widget.childId}-$dateKey';

    final isDone = widget.chore.isRecurring
        ? widget.chore.completedDates.contains(completionKey)
        : widget.chore.completedByChildIds.contains(widget.childId);

    final isPending = !isDone &&
        widget.chore.requiresVerification &&
        (widget.chore.isRecurring
            ? widget.chore.pendingVerificationDates.contains(completionKey)
            : widget.chore.pendingVerificationChildIds
                .contains(widget.childId));

    final dueTime = DateTime(selected.year, selected.month, selected.day,
        widget.chore.time.hour, widget.chore.time.minute);
    final deadlinePassed = isToday && now.isAfter(dueTime);
    final canToggle = isToday && !deadlinePassed && !isDone;

    final bg = isDone
        ? Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: 0.3)
        : isPending
            ? Colors.orange.withValues(alpha: 0.07)
            : Colors.white;
    final border = isDone
        ? Theme.of(context).colorScheme.secondary
        : isPending
            ? Colors.orange
            : Colors.grey.withValues(alpha: 0.35);

    final rowWidget = Stack(
      children: [
        Material(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: (!isToday || isDone)
                ? null
                : () async {
                    try {
                      final result = await widget.onToggle();
                      switch (result) {
                        case ChoreToggleResult.completed:
                          _confettiController.play();
                          await Future.delayed(
                            const Duration(milliseconds: 1300),
                          );
                          if (mounted) widget.onChanged();
                        case ChoreToggleResult.pendingVerification:
                        case ChoreToggleResult.uncompleted:
                          widget.onChanged();
                        case ChoreToggleResult.blockedByDeadline:
                          if (context.mounted) {
                            await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Te laat'),
                                content: const Text(
                                    'Sorry, maar deze taak had je eerder af moeten maken. Je krijgt geen punten meer.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Oké')),
                                ],
                              ),
                            );
                          }
                        case ChoreToggleResult.blockedByDate:
                        case ChoreToggleResult.notFound:
                          break;
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fout: $e')),
                        );
                      }
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle
                              : isPending
                                  ? Icons.hourglass_top
                                  : Icons.radio_button_unchecked,
                          color: isDone
                              ? Theme.of(context).colorScheme.secondary
                              : isPending
                                  ? Colors.orange
                                  : (canToggle
                                      ? Colors.grey[500]
                                      : Colors.grey[300]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.chore.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: (canToggle || isPending)
                                ? Colors.black
                                : Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Complete',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Checking',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      _formatTime(widget.chore.time),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: (canToggle || isPending)
                              ? Colors.grey[800]
                              : Colors.grey[400]),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${widget.chore.points} punten',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: (canToggle || isPending)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[400],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!widget.isKidsMode)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending) ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline,
                                size: 22),
                            color: Colors.green[700],
                            onPressed: () async {
                              await widget.onApprove();
                              widget.onChanged();
                            },
                            tooltip: 'Goedkeuren',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, size: 22),
                            color: Colors.red[600],
                            onPressed: () async {
                              await widget.onReject();
                              widget.onChanged();
                            },
                            tooltip: 'Afwijzen',
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.grey[600],
                          onPressed: () => _showEditDialog(context),
                          tooltip: 'Bewerk taak',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 10,
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.9,
            gravity: 0.4,
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
              Colors.lightBlue,
            ],
          ),
        ),
      ],
    );

    // Kids cannot delete tasks — skip the swipe gesture entirely.
    if (widget.isKidsMode) return rowWidget;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Only render the red background while dragging. Rendering it always
        // would bleed red through semi-transparent row backgrounds (done/pending).
        if (_isDragging)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
            ),
          ),
        // HitTestBehavior.translucent lets the inner InkWell still receive taps
        // while this GestureDetector handles the long-press + drag.
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (_) {
            HapticFeedback.heavyImpact();
            setState(() => _isDragging = true);
          },
          onLongPressMoveUpdate: (details) {
            final dx = details.offsetFromOrigin.dx;
            if (dx < 0) {
              setState(() => _dragOffset = dx.clamp(-200.0, 0.0));
            }
          },
          onLongPressEnd: (_) {
            // 80 px threshold — enough to be intentional, not so far it feels broken.
            final shouldDelete = _dragOffset < -80;
            setState(() {
              _dragOffset = 0;
              _isDragging = false;
            });
            if (shouldDelete) _confirmAndDelete(context);
          },
          onLongPressCancel: () {
            setState(() {
              _dragOffset = 0;
              _isDragging = false;
            });
          },
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: rowWidget,
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmAndDelete(BuildContext context) async {
    final chore = widget.chore;

    // Build dialog content depending on recurrence
    final bool isRecurring = chore.isRecurring;
    final title =
        isRecurring ? 'Herhalende taak stoppen?' : 'Taak verwijderen?';
    final message = isRecurring
        ? 'Deze taak is herhalend. We stoppen de reeks per gisteren, zodat hij vandaag en later niet meer verschijnt. Punten blijven ongewijzigd.'
        : 'Dit verwijdert deze taak permanent. Punten blijven ongewijzigd.';
    final confirmLabel = isRecurring ? 'Stop reeks' : 'Verwijderen';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (isRecurring) {
        // End the recurrence yesterday (so hidden today and future)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final updated = chore.copyWith(
          recurrenceEndDate:
              DateTime(yesterday.year, yesterday.month, yesterday.day),
        );
        await ChoresService().updateChore(updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reeks gestopt per gisteren')),
          );
        }
      } else {
        await ChoresService().deleteChore(chore.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Taak verwijderd')),
          );
        }
      }
      widget.onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij verwijderen: $e')),
        );
      }
    }
  }
}

class _AddChoreDialog extends StatefulWidget {
  const _AddChoreDialog(
      {required this.children,
      required this.date,
      required this.familyId,
      required this.onSave});
  final List<ChildModel> children;
  final DateTime date;
  final String familyId;
  final void Function(ChoreModel newChore) onSave;

  @override
  State<_AddChoreDialog> createState() => _AddChoreDialogState();
}

class _AddChoreDialogState extends State<_AddChoreDialog> {
  final _titleCtrl = TextEditingController(text: 'Tanden poetsen');
  final _pointsCtrl = TextEditingController(text: '20');
  Set<String> _selectedChildIds = {};
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 30);
  bool _isRecurring = false;
  bool _requiresVerification = true;
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  final Set<int> _selectedDays = {}; // 1=Monday, 7=Sunday

  @override
  void initState() {
    super.initState();
    _selectedChildIds = {};
    _recurrenceStartDate = widget.date;
    _recurrenceEndDate = widget.date.add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  List<Widget> _buildRecurringFields() {
    return [
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _recurrenceStartDate ?? widget.date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _recurrenceStartDate = picked);
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(_recurrenceStartDate != null
                ? 'Start: ${_recurrenceStartDate!.day}/${_recurrenceStartDate!.month}/${_recurrenceStartDate!.year}'
                : 'Select start date'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _recurrenceEndDate ??
                    widget.date.add(const Duration(days: 30)),
                firstDate: _recurrenceStartDate ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _recurrenceEndDate = picked);
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(_recurrenceEndDate != null
                ? 'End: ${_recurrenceEndDate!.day}/${_recurrenceEndDate!.month}/${_recurrenceEndDate!.year}'
                : 'Select end date'),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      const Text('Repeat on:', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _DayChip(
              label: 'Mon',
              value: 1,
              selected: _selectedDays.contains(1),
              onChanged: (v) => _toggleDay(1)),
          _DayChip(
              label: 'Tue',
              value: 2,
              selected: _selectedDays.contains(2),
              onChanged: (v) => _toggleDay(2)),
          _DayChip(
              label: 'Wed',
              value: 3,
              selected: _selectedDays.contains(3),
              onChanged: (v) => _toggleDay(3)),
          _DayChip(
              label: 'Thu',
              value: 4,
              selected: _selectedDays.contains(4),
              onChanged: (v) => _toggleDay(4)),
          _DayChip(
              label: 'Fri',
              value: 5,
              selected: _selectedDays.contains(5),
              onChanged: (v) => _toggleDay(5)),
          _DayChip(
              label: 'Sat',
              value: 6,
              selected: _selectedDays.contains(6),
              onChanged: (v) => _toggleDay(6)),
          _DayChip(
              label: 'Sun',
              value: 7,
              selected: _selectedDays.contains(7),
              onChanged: (v) => _toggleDay(7)),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _selectedChildIds.isNotEmpty &&
        (!_isRecurring ||
            (_recurrenceStartDate != null &&
                _recurrenceEndDate != null &&
                _selectedDays.isNotEmpty));
    return AlertDialog(
      title: const Text('Nieuwe taak'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kinderen:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.children.map((child) {
                final isSelected = _selectedChildIds.contains(child.id);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(child.name),
                  value: isSelected,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedChildIds.add(child.id);
                      } else {
                        _selectedChildIds.remove(child.id);
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
              TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Taak')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _pointsCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Punten'))),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(
                      '${_time.hour}:${_time.minute.toString().padLeft(2, '0')}'),
                )
              ]),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Verificatie vereist',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ouder moet de taak goedkeuren'),
                value: _requiresVerification,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) => setState(() => _requiresVerification = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Herhalende taak',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                value: _isRecurring,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              if (_isRecurring) ..._buildRecurringFields(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren')),
        ElevatedButton(
          onPressed: canSave
              ? () {
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  final now = DateTime.now();
                  final points = int.tryParse(_pointsCtrl.text.trim()) ?? 0;
                  final chore = ChoreModel(
                    id: id,
                    title: _titleCtrl.text.trim().isEmpty
                        ? 'Taak'
                        : _titleCtrl.text.trim(),
                    time: _time,
                    points: points,
                    date: DateTime(
                        widget.date.year, widget.date.month, widget.date.day),
                    childIds: _selectedChildIds.toList(),
                    familyId: widget.familyId,
                    completedByChildIds: [],
                    createdAt: now,
                    updatedAt: now,
                    isRecurring: _isRecurring,
                    recurrenceStartDate:
                        _isRecurring ? _recurrenceStartDate : null,
                    recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
                    recurringDays: _isRecurring ? _selectedDays.toList() : [],
                    completedDates: const [],
                    requiresVerification: _requiresVerification,
                  );
                  widget.onSave(chore);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Opslaan'),
        )
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onChanged});
  final String label;
  final int value;
  final bool selected;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onChanged,
        selectedColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        checkmarkColor: Theme.of(context).colorScheme.primary,
      );
}

class _EditChoreDialog extends StatefulWidget {
  const _EditChoreDialog(
      {required this.chore, required this.allChildren, required this.onSave});
  final ChoreModel chore;
  final List<ChildModel> allChildren;
  final void Function(ChoreModel updatedChore) onSave;

  @override
  State<_EditChoreDialog> createState() => _EditChoreDialogState();
}

class _EditChoreDialogState extends State<_EditChoreDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _pointsCtrl;
  late Set<String> _selectedChildIds;
  late TimeOfDay _time;
  late bool _isRecurring;
  late bool _requiresVerification;
  late DateTime? _recurrenceStartDate;
  late DateTime? _recurrenceEndDate;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.chore.title);
    _pointsCtrl = TextEditingController(text: widget.chore.points.toString());
    _selectedChildIds = widget.chore.childIds.toSet();
    _time = widget.chore.time;
    _isRecurring = widget.chore.isRecurring;
    _requiresVerification = widget.chore.requiresVerification;
    _recurrenceStartDate = widget.chore.recurrenceStartDate;
    _recurrenceEndDate = widget.chore.recurrenceEndDate;
    _selectedDays = widget.chore.recurringDays.toSet();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  List<Widget> _buildRecurringFields() {
    return [
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _recurrenceStartDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _recurrenceStartDate = picked);
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(_recurrenceStartDate != null
                ? 'Start: ${_recurrenceStartDate!.day}/${_recurrenceStartDate!.month}/${_recurrenceStartDate!.year}'
                : 'Select start date'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _recurrenceEndDate ??
                    DateTime.now().add(const Duration(days: 30)),
                firstDate: _recurrenceStartDate ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _recurrenceEndDate = picked);
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(_recurrenceEndDate != null
                ? 'End: ${_recurrenceEndDate!.day}/${_recurrenceEndDate!.month}/${_recurrenceEndDate!.year}'
                : 'Select end date'),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      const Text('Repeat on:', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _DayChip(
              label: 'Mon',
              value: 1,
              selected: _selectedDays.contains(1),
              onChanged: (v) => _toggleDay(1)),
          _DayChip(
              label: 'Tue',
              value: 2,
              selected: _selectedDays.contains(2),
              onChanged: (v) => _toggleDay(2)),
          _DayChip(
              label: 'Wed',
              value: 3,
              selected: _selectedDays.contains(3),
              onChanged: (v) => _toggleDay(3)),
          _DayChip(
              label: 'Thu',
              value: 4,
              selected: _selectedDays.contains(4),
              onChanged: (v) => _toggleDay(4)),
          _DayChip(
              label: 'Fri',
              value: 5,
              selected: _selectedDays.contains(5),
              onChanged: (v) => _toggleDay(5)),
          _DayChip(
              label: 'Sat',
              value: 6,
              selected: _selectedDays.contains(6),
              onChanged: (v) => _toggleDay(6)),
          _DayChip(
              label: 'Sun',
              value: 7,
              selected: _selectedDays.contains(7),
              onChanged: (v) => _toggleDay(7)),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _selectedChildIds.isNotEmpty &&
        (!_isRecurring ||
            (_recurrenceStartDate != null &&
                _recurrenceEndDate != null &&
                _selectedDays.isNotEmpty));
    return AlertDialog(
      title: const Text('Bewerk taak'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kinderen:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.allChildren.map((child) {
                final isSelected = _selectedChildIds.contains(child.id);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(child.name),
                  value: isSelected,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedChildIds.add(child.id);
                      } else {
                        _selectedChildIds.remove(child.id);
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
              TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Taak')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _pointsCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Punten'))),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(
                      '${_time.hour}:${_time.minute.toString().padLeft(2, '0')}'),
                )
              ]),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Verificatie vereist',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ouder moet de taak goedkeuren'),
                value: _requiresVerification,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) => setState(() => _requiresVerification = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Herhalende taak',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                value: _isRecurring,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              if (_isRecurring) ..._buildRecurringFields(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren')),
        ElevatedButton(
          onPressed: canSave
              ? () {
                  final points = int.tryParse(_pointsCtrl.text.trim()) ?? 0;
                  final updatedChore = widget.chore.copyWith(
                    title: _titleCtrl.text.trim().isEmpty
                        ? 'Taak'
                        : _titleCtrl.text.trim(),
                    time: _time,
                    points: points,
                    childIds: _selectedChildIds.toList(),
                    isRecurring: _isRecurring,
                    requiresVerification: _requiresVerification,
                    recurrenceStartDate:
                        _isRecurring ? _recurrenceStartDate : null,
                    recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
                    recurringDays: _isRecurring ? _selectedDays.toList() : [],
                  );
                  widget.onSave(updatedChore);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Opslaan'),
        )
      ],
    );
  }
}
