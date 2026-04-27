import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chorechamp2/theme.dart';
import 'package:chorechamp2/core/routes/app_routes.dart';
import 'package:chorechamp2/firebase_options.dart';
import 'package:chorechamp2/core/utils/kids_mode_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await KidsModeNotifier().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DreamFlow Demo',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: RouteNames.login,
      routes: AppRouter.routes,
    );
  }
}
