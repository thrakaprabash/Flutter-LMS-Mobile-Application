# Day 3: Splash, onboarding, role dashboards and UI states

Implemented against Day 3 of the supplied detailed task plan.

## Entry flow

- Branded Flutter splash with a cancellable 1.2-second timer.
- Three onboarding pages using PageView, swipe, Next, Skip, page indicators and Get started.
- Splash is replaced; completing/skipping onboarding removes preceding routes.
- Back moves to the previous onboarding page; on the first page it stays in onboarding.
- Login retains Day 2 local validation. Home provides explicit role previews rather than claiming authentication.
- Fresh launches show onboarding again. Persistent onboarding completion and session routing are deferred to the session work.
- Android launch backgrounds match the splash color, with Android 12+ launch-theme resources.

## Role dashboards

One shared dashboard layout and card component, with separate typed sample configurations:

- Student: enrollments, lessons, streak, continue learning and recent activity.
- Instructor: courses, students, grading counts, course/submission/enrollment shortcuts and activity.
- Admin: users, courses, moderation counts, user/category/review shortcuts and activity.

Each role has four navigation destinations. Future features display honest coming-soon or empty states. Sample data lives in `lib/features/dashboard/data/dashboard_data.dart`, independently of the screen. No API calls, authentication or permissions are implemented on Day 3.

## Reusable UI feedback

`AppStateView` exposes loading, empty, error and success variants, an optional detail message, and a caller-owned action/retry callback. It is shared across features and used for dashboard placeholders.

## Verification

- `dart format lib test`: passed.
- `flutter analyze`: no issues.
- `flutter test --concurrency=1`: 10 tests passed.
- Tests cover onboarding swipe/Next/Skip/completion/Back, removal of entry routes, three role dashboards at 320 × 568 with 1.5× text, navigation placeholders, shared UI states and retry, and existing login validation/navigation.
- Android native launch appearance still requires visual verification on a device.

## References

- https://docs.flutter.dev/platform-integration/android/splash-screen
- https://docs.flutter.dev/ui/widgets

Android build check: Gradle failed with 'Unable to establish loopback connection'. A retry using the documented single-worker/Android Studio Java setup was declined, so APK compilation and device visual verification remain unconfirmed.

University dashboard refinement: Student overview now prioritizes a highlighted continue-lesson card, four quick-access actions, upcoming assignment/quiz deadlines, and individual course progress. The forest-green theme is retained. Course and deadline fixtures remain isolated from presentation; sample deadlines are illustrative. Instructor and Admin keep role-appropriate tools and summaries.

Instructor and Admin dashboard refinement: Both now share a prominent green priority card, a quick-action grid, attention queues, summary cards, and role-specific collections. Instructor content covers grading and teaching; Admin content covers moderation, account requests, and platform management. Fixtures remain separate from presentation. Actions continue to use navigation placeholders for later API features.
