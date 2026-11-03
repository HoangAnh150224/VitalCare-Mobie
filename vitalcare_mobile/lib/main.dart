import 'package:flutter/material.dart';
import 'vitalcare/api/api.dart';
import 'vitalcare/view/login_screen.dart';
import 'vitalcare/view/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

/// Lets the API client send the user back to the login screen from anywhere.
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Api.instance.client.onSessionExpired = _toLogin;
  }

  @override
  void dispose() {
    if (Api.instance.client.onSessionExpired == _toLogin) {
      Api.instance.client.onSessionExpired = null;
    }
    super.dispose();
  }

  void _toLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    ScaffoldMessenger.maybeOf(navigator.context)?.showSnackBar(
      const SnackBar(content: Text(ApiException.sessionExpiredMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalCare',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008BA8),
        ).copyWith(primary: const Color(0xFF008BA8)),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}
