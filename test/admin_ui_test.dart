import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/theme/app_theme.dart';
import 'package:flutter_lms/features/admin/dashboard/screens/admin_home_screen.dart';
import 'package:flutter_lms/features/admin/screens/admin_list_screen.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

import 'day_09_test.dart' as fixtures;

void main() {
  testWidgets(
    'admin design renders dashboard and management screens at phone width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = FontLoader('LmsRoboto')
        ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
      await font.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final account = fixtures.AdminAccount();
      final auth = AuthProvider(account, fixtures.storage)
        ..user = {'_id': 'admin-one', 'firstName': 'Alex', 'role': 'ADMIN'};
      addTearDown(auth.dispose);
      account.respond = (method, path, data) async => {
        'data': path.contains('dashboard')
            ? {
                'totalStudents': 248,
                'totalInstructors': 18,
                'activeUsers': 260,
                'publishedCourses': 36,
                'totalEnrollments': 512,
                'completedEnrollments': 126,
              }
            : {
                'users': [
                  {
                    '_id': 'learner-one',
                    'firstName': 'Amelia',
                    'lastName': 'Perera',
                    'email': 'amelia@example.test',
                    'role': 'STUDENT',
                    'status': 'ACTIVE',
                  },
                ],
                'courses': [
                  {
                    '_id': 'course-one',
                    'title': 'Designing better digital experiences',
                    'shortDescription': 'Build thoughtful interfaces with practical design foundations.',
                    'description': 'A practical introduction to visual design, user research and accessible interfaces.',
                    'status': 'PUBLISHED',
                    'language': 'English',
                    'level': 'BEGINNER',
                  },
                ],
                'categories': [
                  {
                    '_id': 'category-one',
                    'name': 'Design & creativity',
                    'description': 'Ideas, tools and techniques for curious creative minds.',
                    'isActive': true,
                  },
                ],
                'reviews': [
                  {
                    '_id': 'review-one',
                    'rating': 5,
                    'student': {'firstName': 'Amelia', 'lastName': 'Perera'},
                    'comment': 'Clear explanations and thoughtful projects. I feel much more confident applying these ideas.',
                    'isVisible': true,
                  },
                ],
                'enrollments': [
                  {
                    '_id': 'enrollment-one',
                    'status': 'ACTIVE',
                    'progressPercentage': 65,
                    'course': {'title': 'Designing better digital experiences'},
                    'student': {
                      'firstName': 'Amelia',
                      'lastName': 'Perera',
                      'email': 'amelia@example.test',
                    },
                  },
                ],
              },
      };
      for (final feature in [
        'dashboard',
        'users',
        'courses',
        'categories',
        'enrollments',
        'reviews',
      ]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ChangeNotifierProvider<AuthProvider>.value(
              value: auth,
              child: MaterialApp(
                theme: AppTheme.light,
                debugShowCheckedModeBanner: false,
                home: feature == 'dashboard'
                    ? const AdminHomeScreen()
                    : AdminListScreen(
                        key: ValueKey(feature),
                        feature: feature,
                        courseId: feature == 'reviews' ? 'course-one' : null,
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: feature);
        if (const bool.fromEnvironment('ADMIN_UI_PREVIEWS')) {
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('docs/evidence/admin-$feature.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    },
  );
}
