import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalcare_mobile/main.dart';
import 'package:vitalcare_mobile/vitalcare/api/api.dart';
import 'package:vitalcare_mobile/vitalcare/api/api_client.dart';
import 'package:vitalcare_mobile/vitalcare/api/session_store.dart';
import 'package:vitalcare_mobile/vitalcare/view/home_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/login_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/splash_screen.dart';

/// A backend that signs anybody in and has no data yet.
http.Response _fakeBackend(http.Request request) {
  final body = switch (request.url.path) {
    '/api/auth/login' => {
      'accessToken': 'access',
      'refreshToken': 'refresh',
      'user': {'id': 1, 'phone': '0912345678', 'fullName': 'Trần Thu Trang'},
    },
    '/api/notifications/unread-count' => {'unread': 0},
    '/api/my_vital_signs/latest' => {'readings24h': 0},
    _ => <String, Object>{},
  };
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Api.instance = Api(
      ApiClient(
        httpClient: MockClient((request) async => _fakeBackend(request)),
        store: SessionStore(),
        baseUrl: 'http://api.test/api',
      ),
    );
  });

  testWidgets('A remembered session opens home after the splash', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vc.accessToken': 'access',
      'vc.refreshToken': 'refresh',
    });
    await tester.pumpWidget(const MyApp());
    await tester.pump(SplashScreen.displayDuration);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets(
    'Returning from background keeps login without replaying splash',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const MyApp());
      await tester.pump(SplashScreen.displayDuration);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '0912345678');

      for (var attempt = 0; attempt < 2; attempt++) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(seconds: 3));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('0912345678'), findsOneWidget);
        expect(
          tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
          isFalse,
        );
      }
    },
  );

  testWidgets('Temporary focus loss does not restart login', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const MyApp());
    await tester.pump(SplashScreen.displayDuration);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('Startup shows logo for three seconds then replaces splash', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 2999));
    expect(find.byType(LoginScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('Removing splash cancels pending navigation', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Login validates fields and toggles password and remember option',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(SplashScreen.displayDuration);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      final logo = tester.widget<Image>(find.byType(Image));
      expect((logo.image as AssetImage).assetName, 'assets/images/logo.jpg');
      expect(logo.fit, BoxFit.contain);
      expect(find.byType(AppBar), findsNothing);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '0912345678');
      await tester.enterText(
        find.byType(TextFormField).last,
        'example-password',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(Api.instance.client.store.current?.accessToken, 'access');
      expect(tester.takeException(), isNull);
    },
  );
}
