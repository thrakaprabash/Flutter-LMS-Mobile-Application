import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/core/theme/app_theme.dart';
import 'package:flutter_lms/features/demo/demo_screen.dart';
import 'package:flutter_lms/features/student/learning/screens/learning_screens.dart';
import 'package:flutter_lms/features/student/learning/widgets/learning_widgets.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

const previews = bool.fromEnvironment('STUDENT_PREVIEWS');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  setUpAll(() async {
    if (previews) {
      await (FontLoader('LmsRoboto')
            ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
            ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    if (!previews) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final picture = await boundary.toImage(pixelRatio: 2);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      final file = File('docs/evidence/student-$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  for (final narrow in [false, true]) {
    testWidgets(
      'student tabs, reusable cards and safe spacing${narrow ? ' with large text' : ''}',
      (tester) async {
        tester.view.physicalSize = narrow
            ? const Size(320, 700)
            : const Size(412, 892);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = DemoAuthProvider(
          DemoAccountService(
            ApiClient(const TokenStorage(FlutterSecureStorage())),
            'STUDENT',
          ),
          const TokenStorage(FlutterSecureStorage()),
        );
        addTearDown(auth.dispose);
        final key = GlobalKey();
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(narrow ? 1.5 : 1)),
                  child: child!,
                ),
                home: const StudentLearningHome(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('A little learning, every day.'), findsOneWidget);
        if (!narrow) await capture(tester, key, 'home');
        await tester.tap(find.text('Explore'));
        await tester.pumpAndSettle();
        final list = tester.widget<ListView>(find.byType(ListView).first);
        expect(list.childrenDelegate, isA<SliverChildBuilderDelegate>());
        await tester.scrollUntilVisible(
          find.byType(CourseCard),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.byType(CourseCard), findsOneWidget);
        if (!narrow) await capture(tester, key, 'explore');
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('My courses'));
        await tester.pumpAndSettle();
        expect(find.text('Your learning journey'), findsOneWidget);
        if (!narrow) await capture(tester, key, 'learning');
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('MY PROFILE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
