# Student interface refinement

The student area uses Home, Explore, My courses and Profile navigation. Home shows active enrollments from the existing API; Explore retains search, categories, refresh and pagination. My courses filters active, completed and cancelled enrollments.

Course collections use `ListView.builder` and the reusable `CourseCard` in `lib/features/student/learning/widgets/learning_widgets.dart`. Cards show backend thumbnails with a decorative fallback, instructor, level, language, enrollment status and progress. Missing progress remains explicitly unavailable.

Shared student headings, panels and empty states live in `lib/features/student/widgets/student_ui.dart`. Lessons use a readable text panel. Assignment instructions and submission fields have distinct sections; quiz information and question cards have consistent spacing. Notifications and activity lists use the same visual language. Role access, enrollment checks and backend operations remain in their existing flows. All application data uses the backend.

The learning UI is split by responsibility:

- `dashboard/screens/student_learning_home.dart`: student navigation and service scope.
- `courses/screens/course_list_screen.dart`: course loading, pagination and lazy course lists.
- `courses/widgets/course_list_header.dart`: search, category selection and enrollment status filters.
- `courses/screens/course_details_screen.dart`: course state, enrollment and navigation actions.
- `courses/widgets/course_details_view.dart`: course detail layout.
- `courses/widgets/course_section_tile.dart`: expandable curriculum and lesson loading.
- `learning/screens/lesson_screen.dart`: lesson viewing, playback and completion.
- `learning/learning_scope.dart`: protected learning route scope.

`learning/screens/learning_screens.dart` is a small compatibility export file. Feature implementations import focused files directly.

The earlier split passed 69 tests. Demo-dependent visual tests and sample screenshots were subsequently removed; current verification is recorded in backend_only.md.
