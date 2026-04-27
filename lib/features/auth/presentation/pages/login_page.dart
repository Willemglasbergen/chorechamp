import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chorechamp2/core/routes/app_routes.dart';
import 'package:chorechamp2/data/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Vul e-mail en wachtwoord in.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteNames.family);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Vul alle velden in.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteNames.family);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final left = _LeftPane(
            tabController: _tabController,
            emailController: _emailController,
            passwordController: _passwordController,
            nameController: _nameController,
            obscure: _obscure,
            isLoading: _isLoading,
            onTogglePassword: () => setState(() => _obscure = !_obscure),
            onForgotPassword: () =>
                _showError('Wachtwoord reset is nog niet geconfigureerd.'),
            onLogin: _handleLogin,
            onSignUp: _handleSignUp,
            accent: Theme.of(context).colorScheme.primary,
          );

          final right =
              _RightPane(accent: Theme.of(context).colorScheme.primary);

          if (isWide) {
            return Row(children: [
              Expanded(flex: 5, child: left),
              Expanded(flex: 5, child: right),
            ]);
          }
          return SingleChildScrollView(
            child: Column(children: [right, left]),
          );
        },
      ),
    );
  }
}

class _LeftPane extends StatelessWidget {
  const _LeftPane({
    required this.tabController,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.obscure,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onLogin,
    required this.onSignUp,
    required this.accent,
  });

  final TabController tabController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sentiment_satisfied_alt_outlined,
                      color: accent, size: 48),
                  const SizedBox(width: 6),
                  Text('ChoreChamp',
                      style: TextStyle(fontSize: 28, color: accent)),
                ],
              ),
              const SizedBox(height: 34),
              DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        labelPadding: const EdgeInsets.only(right: 32),
                        labelColor: accent,
                        unselectedLabelColor: Colors.grey[600],
                        indicator:
                            UnderlineTabIndicator(borderSide: BorderSide.none),
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: [
                          Tab(
                              child: Text('Login',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600))),
                          Tab(
                              child: Text('Registreer',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 290,
                      child: TabBarView(
                        controller: tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _LoginForm(
                            emailController: emailController,
                            passwordController: passwordController,
                            obscure: obscure,
                            isLoading: isLoading,
                            onTogglePassword: onTogglePassword,
                            onForgotPassword: onForgotPassword,
                            onLogin: onLogin,
                            accent: accent,
                          ),
                          _SignUpForm(
                            nameController: nameController,
                            emailController: emailController,
                            passwordController: passwordController,
                            obscure: obscure,
                            isLoading: isLoading,
                            onTogglePassword: onTogglePassword,
                            onSignUp: onSignUp,
                            accent: accent,
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
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onLogin,
    required this.accent,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  final Color accent;

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: _border,
            focusedBorder:
                _border.copyWith(borderSide: BorderSide(color: accent)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'Wachtwoord',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: _border,
            focusedBorder:
                _border.copyWith(borderSide: BorderSide(color: accent)),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
                foregroundColor: accent, padding: EdgeInsets.zero),
            child: const Text('Wachtwoord vergeten?'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Login'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSignUp,
    required this.accent,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignUp;
  final Color accent;

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Naam',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: _border,
            focusedBorder:
                _border.copyWith(borderSide: BorderSide(color: accent)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: _border,
            focusedBorder:
                _border.copyWith(borderSide: BorderSide(color: accent)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'Wachtwoord',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: _border,
            focusedBorder:
                _border.copyWith(borderSide: BorderSide(color: accent)),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Registreer'),
            ),
          ),
        ),
      ],
    );
  }
}

class _RightPane extends StatelessWidget {
  const _RightPane({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Image(
                  width: 400,
                  height: 300,
                  fit: BoxFit.none,
                  image: AssetImage('assets/images/Frontpage.png'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Taakjes doen was nog nooit zó leuk!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Je kinderen voeren zelf hun taken uit zonder dat jij er om hoeft te vragen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
