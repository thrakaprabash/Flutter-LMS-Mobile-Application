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
import 'package:flutter_lms/features/instructor/screens/instructor_home_screen.dart';
import 'package:flutter_lms/features/instructor/screens/instructor_editor.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

const previews = bool.fromEnvironment('INSTRUCTOR_PREVIEWS');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = TokenStorage(FlutterSecureStorage());
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
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('docs/evidence/instructor-$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> launch(WidgetTester tester, GlobalKey key) async {
    final auth = DemoAuthProvider(
      DemoAccountService(ApiClient(storage), 'INSTRUCTOR'),
      storage,
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const InstructorHomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('account menu displays the current profile photo', (
    tester,
  ) async {
    await launch(tester, GlobalKey());
    final context = tester.element(find.byType(InstructorHomeScreen));
    final auth = context.read<AuthProvider>();
    expect(
      find.descendant(
        of: find.byTooltip('Account menu'),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    auth.user = {
      ...?auth.user,
      'profileImageUrl': 'https://example.com/avatar.png',
    };
    // Rebuild the shell as happens when the profile provider notifies listeners.
    tester.element(find.byType(InstructorHomeScreen)).markNeedsBuild();
    await tester.pump();
    final photo = find.descendant(
      of: find.byTooltip('Account menu'),
      matching: find.byType(Image),
    );
    expect(photo, findsOneWidget);
    expect(
      (tester.widget<Image>(photo).image as NetworkImage).url,
      'https://example.com/avatar.png',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bottom navigation opens courses, learner activity and instructor profile',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await launch(tester, key);
      expect(find.byType(NavigationBar), findsOneWidget);
      await capture(tester, key, 'dashboard');
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      await capture(tester, key, 'courses');
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      expect(find.text('Build your first Flutter app'), findsOneWidget);
      expect(find.text('Flutter foundations'), findsNothing);
      await tester.tap(find.text('Learners'));
      await tester.pumpAndSettle();
      expect(find.text('Support every learner'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Flutter foundations'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flutter foundations'));
      await tester.pumpAndSettle();
      expect(find.text('Enrollments'), findsOneWidget);
      await capture(tester, key, 'learner-activity');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Alex Taylor'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('all instructor tabs fit small screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, GlobalKey());
    for (final tab in ['Courses', 'Learners', 'Profile', 'Dashboard']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '$tab must fit without clipping.',
      );
    }
  });
  testWidgets(
    'course builder keeps content, assessments and settings separate',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await launch(tester, key);
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Build your first Flutter app'));
      await tester.pumpAndSettle();
      expect(find.text('Add section'), findsOneWidget);
      expect(find.text('Archive course'), findsNothing);
      await capture(tester, key, 'builder');
      await tester.tap(find.text('Assessments'));
      await tester.pumpAndSettle();
      expect(find.text('Quizzes'), findsOneWidget);
      expect(find.text('Add section'), findsNothing);
      await tester.ensureVisible(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Edit course'), findsOneWidget);
      expect(find.text('Archive course'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('save stays visible while editing a long course form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: InstructorEditor(
            title: 'Create draft course',
            fields: courseDetailsFields,
            onSave: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save').hitTestable(), findsOneWidget);
    await capture(tester, key, 'course-form');
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'quiz answer cards support multiple correct answers without exposing option IDs',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      Map<String, dynamic>? saved;
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: InstructorEditor(
              title: 'Add question',
              fields: questionFields,
              initial: const {
                'questionText': 'Which widgets help arrange a layout?',
                'questionType': 'MULTIPLE_CHOICE',
                'options': [
                  {'id': 'A', 'text': 'Row'},
                  {'id': 'B', 'text': 'Text'},
                  {'id': 'C', 'text': 'Column'},
                ],
                'marks': 2,
              },
              onSave: (data) async => saved = data,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, key, 'question-form');
      for (final index in [1, 3]) {
        final target = find.byTooltip('Mark answer $index correct');
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved?['correctOptionIds'], ['A', 'C']);
      expect(saved?['options'], hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );
}
