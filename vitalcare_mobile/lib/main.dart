import 'package:flutter/material.dart';
import 'vitalcare/api/api.dart';
import 'vitalcare/view/login_screen.dart';
import 'vitalcare/view/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

/// Lets the API client send the user back to the login screen from anywhere.
final navigatorKey = GlobalKey<NavigatorState>();

/// The largest system text size the app follows. People who raise it still get bigger text, up to
/// one and a half times; past that, phone layouts stop fitting and every screen would need its own
/// fallback. Shared with the responsive test so it checks what the app really draws.
const maxTextScale = 1.5;

Widget clampTextScale(BuildContext context, Widget? child) =>
    MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: child ?? const SizedBox.shrink(),
    );

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
          seedColor: const Color(0xFF00777C),
        ).copyWith(primary: const Color(0xFF00777C)),
        scaffoldBackgroundColor: Colors.white,
      ),
      builder: clampTextScale,
      home: const SplashScreen(),
    );
  }
}
