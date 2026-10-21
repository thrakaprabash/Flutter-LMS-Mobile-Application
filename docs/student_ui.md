# Student interface refinement

The student area uses Home, Explore, My courses and Profile navigation. Home shows active enrollments from the existing API; Explore retains search, categories, refresh and pagination. My courses filters active, completed and cancelled enrollments.

Course collections use `ListView.builder` and the reusable `CourseCard` in `lib/features/student/learning/widgets/learning_widgets.dart`. Cards show backend thumbnails with a decorative fallback, instructor, level, language, enrollment status and progress. Missing progress remains explicitly unavailable.

Shared student headings, panels and empty states live in `lib/features/student/widgets/student_ui.dart`. Lessons use a readable text panel. Assignment instructions and submission fields have distinct sections; quiz information and question cards have consistent spacing. Notifications and activity lists use the same visual language. Role access, enrollment checks and backend operations remain in their existing flows; demo state remains separate.

Verification: Flutter analysis passed; all 68 tests passed. Navigation is checked at 412px and 320px widths, including 1.5x text scaling. Preview images are under `docs/evidence/student-*.png`; regenerate with `flutter test test/student_navigation_test.dart --dart-define=STUDENT_PREVIEWS=true`.
