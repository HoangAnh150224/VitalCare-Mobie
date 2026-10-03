import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalcare_mobile/main.dart';
import 'package:vitalcare_mobile/vitalcare/view/login_screen.dart';

void main() {
  testWidgets(
    'Login validates fields and toggles password and remember option',
    (tester) async {
      await tester.pumpWidget(const MyApp());
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
      await tester.tap(find.text('Hiện'));
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
      expect(
        find.text('Chức năng đăng nhập chưa được kết nối máy chủ.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
