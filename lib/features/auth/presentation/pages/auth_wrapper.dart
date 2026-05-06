import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chorechamp2/data/services/auth_service.dart';
import 'package:chorechamp2/core/routes/app_routes.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final user = _authService.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteNames.login);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString('last_active_time');
    
    bool sessionExpired = false;
    
    if (lastActiveStr != null) {
      final lastActiveTime = DateTime.tryParse(lastActiveStr);
      if (lastActiveTime != null) {
        final difference = DateTime.now().difference(lastActiveTime);
        if (difference.inDays >= 14) {
          sessionExpired = true;
        }
      }
    }

    if (sessionExpired) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteNames.login);
      }
    } else {
      await prefs.setString('last_active_time', DateTime.now().toIso8601String());
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteNames.family);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
