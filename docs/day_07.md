> Historical milestone record: all application demo modes and sample dashboards were removed on 21 October 2026. See [current backend-only status](backend_only.md).

# Day 7 - Student assessments, communication and profile

Implemented on 19 October 2026 using the supplied Day 7 plan, Mobile API Integration Guide, Backend API Report and Postman collection.

## Implemented

- Enrolled course details link to paginated quizzes and assignments; reviews are accessible from course details.
- Quiz instructions show backend limits and passing score. Starting stores the returned attempt ID and displays student-safe questions, supporting single choice, true/false and multiple choice. Existing active attempts can be resumed from returned history. Submission sends question/option IDs and displays returned score, percentage, pass/fail and status without computing official results. The returned deadline is displayed when supplied. History scans all returned pages; another attempt remains subject to backend limits.
- Assignment lists retrieve the current submission status for each available assignment. No submission (404/empty response) displays Pending; other failures display Status unavailable. Lists refresh after returning from details.
- Assignment details show instructions, due date, maximum marks, attachment links, current submission and instructor feedback. A single multipart implementation handles text-only, file-only and combined submissions. Empty input is rejected. File selection uses the installed file_picker 13 API; Dio sets the multipart boundary and file MIME type is supplied.
- RESUBMISSION_REQUIRED displays feedback and enables Submit correction. GRADED disables answer, attachment and submit controls. Grading and late status come from the backend.
- Course reviews load visible reviews and identify the current student's review by its returned owner ID. Enrolled students can create or update a 1-5 rating/comment. The backend enforces enrollment, uniqueness and ownership. Public review listing omits authorization. Hidden reviews are absent from the public response: the backend still rejects duplicate creation, but editing a hidden review cannot be offered without an authenticated owner lookup in the contract.
- Student notifications support pagination, unread filtering, mark read, mark all read and confirmed deletion. The unread count is fetched after mutations and the home badge refreshes on initial display, app resume and return from notifications. Count failures show unavailable rather than a false zero.
- Student Profile retains account/photo/edit controls and adds active-learning and completed-course summaries from all enrollment pages. Failed summaries expose retry.
- Shared cards, status chips and confirmation dialogs use the existing green theme. Student routes retain the authenticated account and learning scope.
- Explicit debug demo sessions include isolated quiz, correction, graded-assignment, review and notification fixtures. Demo transport never forwards to the backend. The demo quiz returns a fixed illustrative result; it does not represent official grading. Fixtures reset with the demo account session.

## Integrated contract

| Method | Endpoint |
| --- | --- |
| GET | /api/v1/courses/:courseId/quizzes |
| GET | /api/v1/quizzes/:quizId |
| POST | /api/v1/quizzes/:quizId/start |
| POST | /api/v1/quiz-attempts/:attemptId/submit |
| GET | /api/v1/quizzes/:quizId/attempts/me |
| GET | /api/v1/courses/:courseId/assignments |
| GET | /api/v1/assignments/:assignmentId |
| GET | /api/v1/assignments/:assignmentId/submission/me |
| POST | /api/v1/assignments/:assignmentId/submissions (FormData only) |
| GET / POST | /api/v1/courses/:courseId/reviews |
| PATCH | /api/v1/reviews/:reviewId |
| GET | /api/v1/notifications/me |
| GET | /api/v1/notifications/me/unread-count |
| PATCH | /api/v1/notifications/:notificationId/read |
| PATCH | /api/v1/notifications/me/read-all |
| DELETE | /api/v1/notifications/:notificationId |

## Verification

- Full automated suite: 43 tests passed, including seven Day 7 tests covering all three multipart payloads, empty rejection, protected/public authorization, pagination metadata, corrected submissions, graded edit locks, quiz submission/result display, notification mutations and review updates.
- Final static analysis: no issues found.
- Android debug build: succeeded (306 Gradle tasks, 58 seconds). After the user started emulator-5554, the updated APK installed successfully and the app opened with the existing Student session. Device inspection confirmed the course catalogue, unread badge, and notifications list load from the backend; both badge and list showed 10 unread. Notifications were not marked read or deleted during this check. Remaining assessment, profile and native file-picker device checks are pending.

## Remaining live acceptance

Authenticated backend checks are still required for real quiz start/timeout/attempt limits/results; all three actual file upload variants; instructor-requested correction and graded locks; review uniqueness/ownership; notification counts and pagination; and completed-course summaries. No production quiz, submission or review was created during automated verification. Existing account suspension must be resolved by the backend owner if encountered; demo sessions never bypass backend authorization.

Instructor/Admin business features remain outside Day 7. Git commit and push remain manual.

## Review UI refinement - 20 October 2026

Replaced the numeric dropdown with five tappable gold star icons, accessible rating labels, selected-state semantics and a descriptive rating caption. The review form now uses a spacious card, comment guidance and an icon submit/update action. Learner cards show avatars, names when returned, star ratings and comments; an illustrated empty state invites the first review. Uses native Material icons with the existing green theme. Backend rating/comment requests and ownership behavior are unchanged.

Verification: static analysis passed; all seven Day 7 tests passed, including selecting four stars and preserving that rating through review creation and editing. Android rebuild succeeded and the updated app installed successfully on emulator-5554.

## Course details UI refinement - 20 October 2026

Added a forest-green gradient course header with instructor, level/language badges and optional thumbnail, a separate learning-progress/enrollment card, responsive assessment/review shortcut cards, an overview/outcomes panel and rounded curriculum cards with folder icons. Missing metadata stays absent; official progress still comes from the backend. Navigation and enrollment/lesson services are unchanged.

Verification: analysis passed. All five Day 6 tests, all seven Day 7 tests and both learning-widget tests passed across the targeted runs. The existing end-to-end learning test now scrolls back to the relocated progress card after lesson completion. Android build succeeded and the update installed and opened on emulator-5554. The fresh launch displayed onboarding; course details device inspection remains pending navigation into a course.

## Profile UI refinement - 20 October 2026

Added a matching forest-green identity header with photo controls, name, email and role badge. Learning totals now use separate icon cards with an explicit loading state. Personal details, learning/professional details and account/security controls are grouped into rounded cards; name inputs stack on narrow layouts. Existing profile/photo endpoints, validation, save recovery and logout confirmations are retained.

Verification: analysis passed. Both profile-save tests and the isolated demo/session test passed. Tests wait for scrolling to settle and locate the Save action again after partial-save feedback expands the page. Android build succeeded and the updated app installed and opened on emulator-5554.
