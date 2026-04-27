import 'package:flutter/material.dart';
import 'package:chorechamp2/features/home/presentation/pages/home_page.dart';
import 'package:chorechamp2/features/auth/presentation/pages/login_page.dart';
import 'package:chorechamp2/features/chores/presentation/pages/chores_page.dart';
import 'package:chorechamp2/features/rewards/presentation/pages/rewards_page.dart';
import 'package:chorechamp2/features/family/presentation/pages/family_page.dart';

class RouteNames {
  RouteNames._();
  static const login = '/';
  static const home = '/home';
  static const chores = '/chores';
  static const rewards = '/rewards';
  static const family = '/family';
}

class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
        RouteNames.login: (context) => const LoginPage(),
        RouteNames.home: (context) => const HomePage(title: 'DreamFlow Starter Project'),
        RouteNames.chores: (context) => const ChoresPage(),
        RouteNames.rewards: (context) => const RewardsPage(),
        RouteNames.family: (context) => const FamilyPage(),
      };
}
