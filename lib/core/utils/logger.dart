import 'dart:developer' as developer;

class AppLogger {
  AppLogger._();

  static void d(String message, {String name = 'App'}) => developer.log(message, name: name);
  static void e(String message, {String name = 'App'}) => developer.log('ERROR: $message', name: name);
}
