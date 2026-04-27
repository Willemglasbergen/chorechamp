import 'package:flutter/material.dart';
import 'package:chorechamp2/widgets/app_top_bar.dart';
import 'package:chorechamp2/data/services/children_service.dart';
import 'package:chorechamp2/data/services/auth_service.dart';
import 'package:chorechamp2/data/models/child.dart';
import 'package:chorechamp2/data/models/app_user.dart';
import 'package:chorechamp2/core/routes/app_routes.dart';
import 'package:chorechamp2/core/utils/kids_mode_notifier.dart';
import 'package:chorechamp2/widgets/left_nav_pane.dart';
import 'package:chorechamp2/data/services/ledger_service.dart';
import 'package:chorechamp2/data/models/ledger_entry.dart';
import 'package:chorechamp2/core/utils/format.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final _childrenService = ChildrenService();
  final _authService = AuthService();
  final _kidsModeNotifier = KidsModeNotifier();

  List<ChildModel> _children = [];
  AppUser? _currentUser;
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
        final kids = await _childrenService.getChildren(user.id);
        setState(() {
          _currentUser = user;
          _children = kids;
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
    Future<void> accountPressed() async {
      await showDialog(
        context: context,
        builder: (_) => _EditProfileDialog(
          onProfileUpdated: () =>
              Navigator.of(context).pushReplacementNamed(RouteNames.family),
        ),
      );
    }
    return Scaffold(
      appBar: AppTopBar(showMenuButton: isMobile),
      drawer: isMobile
          ? NavDrawer(
              current: LeftNavItem.family,
              isKidsMode: isKidsMode,
              userEmail: _currentUser?.email ?? '',
              onAccountPressed: accountPressed,
            )
          : null,
      floatingActionButton: isKidsMode
          ? null
          : FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => _AddEditChildDialog(
                    onSave: (child) async {
                      final uid = _currentUser?.id ?? '';
                      await _childrenService.createChildWithOpeningBalance(
                        child: child,
                        createdByUserId: uid,
                      );
                      await _load();
                    },
                    familyId: _currentUser?.id ?? '',
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile)
            LeftNavPane(
              current: LeftNavItem.family,
              userEmail: _currentUser?.email ?? '',
              isKidsMode: isKidsMode,
              onAccountPressed: accountPressed,
            ),
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
                        const SizedBox(height: 24),
                        if (_currentUser != null) ...[
                          _MemberCard(
                            name: _currentUser!.name,
                            role: 'Ouder',
                            isParent: true,
                            email: _currentUser!.email,
                          ),
                          const SizedBox(height: 16),
                        ],
                        ..._children.map((child) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _MemberCard(
                                name: child.name,
                                role: 'Kind',
                                age: child.age,
                                balance: child.balance,
                                isParent: false,
                                isKidsMode: isKidsMode,
                                onEdit: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => _AddEditChildDialog(
                                      child: child,
                                      onSave: (updatedChild) async {
                                        final uid = _currentUser?.id ?? '';
                                        await _childrenService
                                            .updateChildWithBalanceAdjustment(
                                          updatedChild: updatedChild,
                                          createdByUserId: uid,
                                        );
                                        await _load();
                                      },
                                      familyId: _currentUser?.id ?? '',
                                    ),
                                  );
                                },
                                onViewLedger: () => _openLedger(child),
                                onAdjust: isKidsMode
                                    ? null
                                    : () => _openAdjustDialog(child),
                                onDelete: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Kind verwijderen'),
                                      content: Text(
                                          'Weet je zeker dat je ${child.name} wilt verwijderen?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Annuleren'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Verwijderen'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _childrenService
                                        .deleteChild(child.id);
                                    await _load();
                                  }
                                },
                              ),
                            )),
                      ],
                    ),
                  ),
          ),
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
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.family_restroom_outlined, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          'Familie',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
        ),
      ]),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.name,
    required this.role,
    required this.isParent,
    this.age,
    this.balance,
    this.email,
    this.onEdit,
    this.onViewLedger,
    this.onAdjust,
    this.onDelete,
    this.isKidsMode = false,
  });

  final String name;
  final String role;
  final bool isParent;
  final int? age;
  final int? balance;
  final String? email;
  final VoidCallback? onEdit;
  final VoidCallback? onViewLedger;
  final VoidCallback? onAdjust;
  final VoidCallback? onDelete;
  final bool isKidsMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isParent ? Icons.person : Icons.child_care,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (age != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$age jaar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (balance != null)
            InkWell(
              onTap: onViewLedger,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${Format.points(balance!)} punten',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (!isParent && !isKidsMode) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary),
            ),
            IconButton(
              onPressed: onAdjust,
              tooltip: 'Saldo aanpassen',
              icon: Icon(Icons.tune,
                  color: Theme.of(context).colorScheme.primary),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddEditChildDialog extends StatefulWidget {
  const _AddEditChildDialog({
    this.child,
    required this.onSave,
    required this.familyId,
  });

  final ChildModel? child;
  final ValueChanged<ChildModel> onSave;
  final String familyId;

  @override
  State<_AddEditChildDialog> createState() => _AddEditChildDialogState();
}

class _AddEditChildDialogState extends State<_AddEditChildDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _balanceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.child?.name ?? '');
    _ageCtrl = TextEditingController(text: widget.child?.age.toString() ?? '');
    _balanceCtrl =
        TextEditingController(text: widget.child?.balance.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.child != null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Kind bewerken' : 'Kind toevoegen',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                isEdit
                    ? 'Pas de gegevens van het kind aan.'
                    : 'Voeg een nieuw kind toe aan je familie.',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: _inputDecoration('Naam'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Leeftijd'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Punten'),
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
                          color: Theme.of(context).colorScheme.primary),
                    ),
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
                      foregroundColor: Colors.white,
                    ),
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
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  void _onSave() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naam is verplicht')),
      );
      return;
    }

    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final balance = int.tryParse(_balanceCtrl.text.trim()) ?? 0;
    final now = DateTime.now();

    final child = ChildModel(
      id: widget.child?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      age: age,
      familyId: widget.familyId,
      balance: balance,
      createdAt: widget.child?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(child);
    Navigator.pop(context);
  }
}

extension on _FamilyPageState {
  void _openLedger(ChildModel child) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _LedgerSheet(child: child),
    );
  }

  void _openAdjustDialog(ChildModel child) {
    final createdBy = _currentUser?.id ?? '';
    showDialog<bool>(
      context: context,
      builder: (_) =>
          _AdjustBalanceDialog(child: child, createdByUserId: createdBy),
    ).then((saved) {
      if (saved == true) {
        _load();
      }
    });
  }
}

class _LedgerSheet extends StatelessWidget {
  const _LedgerSheet({required this.child});
  final ChildModel child;

  @override
  Widget build(BuildContext context) {
    final service = LedgerService();
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Text('Transacties voor ${child.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(16)),
                  child: Text('${Format.points(child.balance)} punten',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<LedgerEntryModel>>(
                  stream: service.streamLatest(child.id,
                      familyId: child.familyId, limit: 20),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint('Ledger stream error: ${snapshot.error}');
                      return const Center(
                          child: Text('Kan transacties niet laden.'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nog geen transacties.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.black.withValues(alpha: 0.06)),
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final isCredit = e.amount >= 0;
                        final color =
                            isCredit ? Colors.green[700] : Colors.red[700];
                        final sign = isCredit ? '+' : '-';
                        return ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: Icon(
                            e.type == LedgerEntryType.chore
                                ? Icons.check_circle_outline
                                : e.type == LedgerEntryType.rewardRequest
                                    ? Icons.card_giftcard
                                    : e.type == LedgerEntryType.rewardCancel
                                        ? Icons.refresh
                                        : e.type ==
                                                LedgerEntryType.openingBalance
                                            ? Icons.flag
                                            : Icons.tune,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(e.note ?? _humanizeType(e.type)),
                          subtitle: Text(_formatDateTime(e.createdAt)),
                          trailing: Text(
                            '$sign${Format.points(e.amount.abs())}',
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _humanizeType(String t) {
    switch (t) {
      case LedgerEntryType.openingBalance:
        return 'Openingssaldo';
      case LedgerEntryType.chore:
        return 'Taak';
      case LedgerEntryType.rewardRequest:
        return 'Beloning aangevraagd';
      case LedgerEntryType.rewardCancel:
        return 'Beloning geannuleerd';
      case LedgerEntryType.manualAdjustment:
      default:
        return 'Aanpassing';
    }
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d-$m-$y $hh:$mm';
  }
}

class _AdjustBalanceDialog extends StatefulWidget {
  const _AdjustBalanceDialog(
      {required this.child, required this.createdByUserId});
  final ChildModel child;
  final String createdByUserId;

  @override
  State<_AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<_AdjustBalanceDialog> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saldo aanpassen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bedrag (+/-)')),
              const SizedBox(height: 8),
              TextField(
                  controller: _noteCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Notitie (optioneel)')),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Annuleren')),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: const Text('Opslaan')),
              ])
            ]),
      ),
    );
  }

  Future<void> _save() async {
    final delta = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (delta == 0) {
      Navigator.pop(context, false);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final service = LedgerService();
      // We don't have current user here; using child.familyId as family, createdBy will be empty handled by service caller in a full flow.
      // In this page we can't access current user id directly, so we'll best-effort set empty string.
      await service.addTransaction(
        childId: widget.child.id,
        familyId: widget.child.familyId,
        amount: delta,
        type: LedgerEntryType.manualAdjustment,
        createdByUserId: widget.createdByUserId,
        note: _noteCtrl.text.trim().isEmpty
            ? 'Aanpassing door ouder'
            : _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fout bij opslaan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.onProfileUpdated});

  final VoidCallback onProfileUpdated;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _authService = AuthService();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentAppUser();
    if (user != null) {
      setState(() {
        _nameCtrl.text = user.name;
        _email = user.email;
        _pinCtrl.text = user.pinCode ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profiel bewerken',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pas je profielgegevens aan.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('Naam'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditingController(text: _email),
                      enabled: false,
                      decoration: _inputDecoration('E-mail'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: _inputDecoration('PIN-code (4 cijfers)'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Text('Annuleren'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
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
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Future<void> _onSave() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naam is verplicht')),
      );
      return;
    }

    final pin = _pinCtrl.text.trim();
    if (pin.isNotEmpty && (pin.length != 4 || int.tryParse(pin) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN moet 4 cijfers zijn')),
      );
      return;
    }

    try {
      final user = await _authService.getCurrentAppUser();
      if (user == null) return;

      await _authService.updateUserProfile(
        user.id,
        name: _nameCtrl.text.trim(),
        pinCode: pin.isNotEmpty ? pin : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profiel succesvol bijgewerkt')),
        );
        widget.onProfileUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij opslaan: $e')),
        );
      }
    }
  }
}
