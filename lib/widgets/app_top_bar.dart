import 'package:flutter/material.dart';
import 'package:chorechamp2/core/routes/app_routes.dart';
import 'package:chorechamp2/data/services/auth_service.dart';
import 'package:chorechamp2/core/utils/kids_mode_notifier.dart';
import 'package:chorechamp2/widgets/hidden_when_kids_mode.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.showMenuButton = false});

  final bool showMenuButton;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Builder gives a context below the Scaffold so Scaffold.of() resolves correctly.
            if (showMenuButton)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  color: Theme.of(ctx).colorScheme.primary,
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            _Logo(accent: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const _BrandTitle(),
            const Spacer(),
            Padding(padding: const EdgeInsets.all(8), child: const _KidsModeToggle()),
            Padding(
              padding: const EdgeInsets.all(8),
              child: HiddenWhenKidsMode(
                child: IconButton(
                  tooltip: 'Logout',
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushReplacementNamed(RouteNames.login);
                    }
                  },
                  icon: Icon(Icons.logout,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 2),
      ),
      child:
          Icon(Icons.sentiment_satisfied_alt_outlined, color: accent, size: 16),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('ChoreChamp',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            )),
        const SizedBox(width: 6),
        const Text('1.4',
            style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _KidsModeToggle extends StatefulWidget {
  const _KidsModeToggle();

  @override
  State<_KidsModeToggle> createState() => _KidsModeToggleState();
}

class _KidsModeToggleState extends State<_KidsModeToggle> {
  final _kidsModeNotifier = KidsModeNotifier();

  @override
  void initState() {
    super.initState();
    _kidsModeNotifier.addListener(_onKidsModeChanged);
  }

  @override
  void dispose() {
    _kidsModeNotifier.removeListener(_onKidsModeChanged);
    super.dispose();
  }

  void _onKidsModeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleKidsMode() async {
    if (_kidsModeNotifier.isKidsMode) {
      await _showPinDialog();
    } else {
      await _kidsModeNotifier.enableKidsMode();
    }
  }

  Future<void> _showPinDialog() async {
    final user = await AuthService().getCurrentAppUser();
    if (user == null || user.pinCode == null || user.pinCode!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Geen PIN-code ingesteld. Stel eerst een PIN in.')),
        );
      }
      await _kidsModeNotifier.disableKidsMode();
      return;
    }

    if (!mounted) return;
    final enteredPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PinDialog(correctPin: user.pinCode!),
    );

    if (enteredPin != null && enteredPin == user.pinCode) {
      await _kidsModeNotifier.disableKidsMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleKidsMode,
      icon: Icon(_kidsModeNotifier.isKidsMode ? Icons.lock : Icons.lock_open),
      tooltip: _kidsModeNotifier.isKidsMode ? 'Ouder modus' : 'Kinder modus',
      color: _kidsModeNotifier.isKidsMode ? Colors.red : Colors.blue,
      iconSize: 24.0,
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.correctPin});
  final String correctPin;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pinController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verify() {
    final pin = _pinController.text.trim();
    if (pin == widget.correctPin) {
      Navigator.pop(context, pin);
    } else {
      setState(() => _errorMessage = 'Verkeerde PIN-code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voer PIN-code in'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Voer de ouder PIN-code in om verder te gaan.'),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'PIN-code',
              border: const OutlineInputBorder(),
              errorText: _errorMessage.isEmpty ? null : _errorMessage,
            ),
            onSubmitted: (_) => _verify(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        ElevatedButton(
          onPressed: _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Bevestigen'),
        ),
      ],
    );
  }
}
