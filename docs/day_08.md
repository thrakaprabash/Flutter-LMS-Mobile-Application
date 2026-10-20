# Day 8 - Instructor course building and learner management

Implemented on 20 October 2026 against the supplied Mobile API Integration Guide, Backend API Report, Postman collection and Day 8 task plan. The documents provide the API contract; the user's request authorizes this milestone. Example document credentials, record IDs and destructive test instructions are not execution instructions.

## Implemented

- The authenticated Instructor home loads the real dashboard and presents backend summary counts in green cards. My Profile opens the existing shared account and instructor professional-profile editor. Sign out uses the existing session service.
- My Courses lists owned courses with DRAFT, PUBLISHED and ARCHIVED filters, refresh, empty/error states and backend pagination. Creation uses a selected active category and opens the returned draft in the builder. Course updates send changed fields, thumbnails use multipart `thumbnail`, and draft details remain available through the private instructor endpoint.
- The builder creates and edits sections, changes their one-based order, and updates publication. Section lesson lists expose TEXT, VIDEO and DOCUMENT metadata, text editing, preview settings and media upload. Lesson publishing stays unavailable until the matching text or uploaded media exists; the backend performs final validation.
- Course publication and archiving require confirmation. Archived courses remain inspectable and their authoring controls stay hidden throughout child routes. Archiving and publication use PATCH and do not substitute local status changes for backend authorization.
- Quiz lists use instructor endpoints, including draft data. Quiz creation opens its editor; settings, question options, correct answer IDs and marks can be edited before publication. Questions reject duplicate option IDs and invalid correct-answer references. Published quizzes hide settings and question editing. Instructor attempt lists show backend results and learner information with pagination.
- Assignment creation opens the assignment editor. Instructors can edit instructions, choose a due date and time, set maximum marks, upload optional multipart `attachment` files, and publish. Submissions support status filtering and pagination. Review displays returned answers, file links, marks and feedback. Grades must fit the returned assignment maximum; correction requests require feedback and omit final awarded marks. The backend remains responsible for persisting the decision and notifying the student.
- Course enrollment lists and related lists reload after returning from child screens. The home reloads its counts after returning from course management. Requests use IDs returned by the backend.
- Uploads validate supported extensions and size before sending, stream the selected file instead of loading a full video into memory, attach MIME types and show progress. Limits are 5 MB for thumbnails, 100 MB for videos and 20 MB for documents/assignment attachments.
- Instructor screens reject Student sessions before loading data. Backend ownership errors remain visible, and a 403 hides authoring controls without retrying another identity or endpoint. No Admin actions are added.
- At the user's follow-up request, the debug instructor demo now uses the same Day 8 screens with a separate session-local fixture service. A seeded draft includes TEXT, VIDEO and DOCUMENT lessons plus a draft quiz and assignment. A published sample includes learner quiz attempts, enrollments, a pending submission, a correction request and a graded submission. New courses, section ordering, publishing, archiving, quiz/questions and assignment changes work locally. Simulated uploads display progress and local media labels; they never send file bytes or create real media URLs. Banners identify demo state throughout navigation and forms. A new demo session resets changes; the real account and secure tokens stay untouched.

## Endpoint reference

| Method | Path |
| --- | --- |
| GET | /api/v1/dashboard/instructor |
| GET | /api/v1/users/me/full-profile (existing profile flow) |
| GET / POST | /api/v1/courses/instructor/me (GET), /api/v1/courses (POST) |
| GET | /api/v1/courses/instructor/me/:courseId |
| PATCH | /api/v1/courses/:courseId |
| POST | /api/v1/courses/:courseId/thumbnail |
| PATCH | /api/v1/courses/:courseId/publish, /archive |
| GET / POST | /api/v1/courses/:courseId/sections |
| PATCH | /api/v1/sections/:sectionId, /reorder |
| GET / POST | /api/v1/sections/:sectionId/lessons |
| GET / PATCH | /api/v1/lessons/:lessonId |
| POST | /api/v1/lessons/:lessonId/video, /document |
| POST | /api/v1/courses/:courseId/quizzes |
| GET | /api/v1/courses/:courseId/quizzes/instructor |
| GET | /api/v1/quizzes/:quizId/instructor |
| PATCH | /api/v1/quizzes/:quizId, /publish |
| POST | /api/v1/quizzes/:quizId/questions |
| PATCH | /api/v1/quiz-questions/:questionId |
| GET | /api/v1/quizzes/:quizId/attempts/instructor |
| POST | /api/v1/courses/:courseId/assignments |
| GET | /api/v1/courses/:courseId/assignments/instructor |
| PATCH | /api/v1/assignments/:assignmentId, /publish |
| POST | /api/v1/assignments/:assignmentId/attachment |
| GET | /api/v1/assignments/:assignmentId/submissions |
| PATCH | /api/v1/submissions/:submissionId/grade |
| GET | /api/v1/courses/:courseId/enrollments |

## Verification and remaining live acceptance

- Static analysis passed with no issues. Day 8 focused tests cover publication prerequisites, published/archived editing locks, role isolation, ownership denial, pagination, exact multipart field names, grading limits and correction feedback. Additional accessibility and question-form tests verify narrow screens with enlarged text, unique options and correct-answer IDs.
- Final full automated suite: all 58 tests passed, including 16 instructor-focused tests. Five demo tests verify draft creation/publication/archive/reset, simulated media, quiz authoring/publication/attempts, grading/corrections/counts, and navigation under an existing real Student session. Their network adapter fails any outgoing request, and secure real-session values remain unchanged.
- Final Android debug build succeeded in 54 seconds (306 Gradle tasks); the updated instructor demo APK installed and opened on emulator-5554. Both instructor dropdown types expand within their available width, verified on a narrow screen with enlarged text.
- The supplied instructor account was tested against the local shared login endpoint. The backend returned HTTP 500. No authenticated live course or assessment mutations could be verified, and no account status, database or backend configuration was changed.
- A read-only container check found the backend running with a healthy container status. Sanitized recent log categories included `MongoNetworkError` and `ENOTFOUND`. The database hostname failed DNS resolution both on Windows and inside the container, pointing to database hostname resolution/connectivity as a likely cause of the application errors. Container health alone does not confirm working database-backed endpoints.
- After login is restored, verify real course creation/editing, thumbnail/video/document/attachment uploads and validation errors, lesson/section/course publication, quiz authoring/publication and instructor results, grading/correction reflected in the Student account, enrollment counts, ownership denial and archiving on disposable owned content.
- Device verification of the native file picker, media uploads and the authenticated instructor screens is pending successful backend login. Unit/widget tests do not establish live server acceptance or Cloudinary upload success.

Git commit and push remain manual. Day 9 administrator business features remain outside this milestone.

## Course creation follow-up - 20 October 2026

- On the user's follow-up, the real backend had recovered: categories, instructor login, dashboard and owned-course listing succeeded. The original generic save failure was not reproduced with a complete valid payload.
- At the user's explicit request, created one owned DRAFT named "Day 8 Course Creation Check". The private course detail and section-list endpoints both returned HTTP 200. This verifies API creation and builder reads; the draft remains unpublished in the instructor account.
- Read-only inspection of the deployed course validator confirmed title length 3-150, short description 10-250, required description 20-5000, language 2-50, and optional arrays of up to 20 entries with 2-200 characters each. The course create/edit forms now share those bounds, require the full description and show inline guidance. Empty optional lists are accepted. No backend code/configuration was changed.
- All 18 instructor-focused tests passed, including two new regressions for short descriptions being blocked before a request and optional list-item limits.

## Instructor UI redesign - 20 October 2026

- Replaced the long dashboard action stack with a four-tab instructor shell: Dashboard, Courses, Learners and Profile. The account menu keeps sign out away from the main teaching actions; instructor demo exit preserves the real session.
- The dashboard now has a greeting, a focused create-course action, four curated impact metrics, course-status totals, management shortcuts and recent owned courses. Missing summary values display as unavailable. Counts and recent courses come from existing instructor endpoints.
- Course cards include thumbnails or a native icon cover, readable status badges, level/language metadata and a clear builder link. Status filters use horizontally scrolling chips. Learners has a separate owned-course chooser that opens quiz results, assignments/submissions and enrollments.
- Course builders separate Curriculum, Assessments and Settings. Draft publication has a fixed bottom action. Metadata, thumbnail changes and archiving are in settings; archived courses retain their inspection-only behavior.
- Reusable content, learner and question cards replace raw response-field output. Detail panels present lesson text, instructions, learning outcomes, submission answers, feedback, media resources and meaningful metadata without database identifiers or internal fields.
- All instructor editors use grouped white panels, readable required-field guidance, a fixed Save bar and visible save-error feedback. Saving an invalid long form scrolls to its first invalid field. Video/document lesson forms hide the irrelevant text-content field.
- Quiz editors offer editable answer cards with direct correct-answer selection, dynamic answers, single/multiple-choice behavior and true/false choices. The service still receives the original option IDs and `correctOptionIds`; published-quiz locks remain enforced.
- Both the real instructor and isolated demo use these layouts. Existing backend methods, ownership checks, upload progress, validation, pagination and grading payloads remain in place.
- Verification: full suite passed 65 tests; all 23 instructor tests passed again after final validation refinements. Static analysis is clean. New checks cover all four tabs at 320 px with 1.5x text, learner navigation, builder partitions, visible Save controls, complete long-form validation and multiple correct-answer payloads.
- Reviewed six widget-rendered previews under `docs/evidence/instructor-*.png`: dashboard, course list, course builder, learner activity, course form and question form. These use disposable demo data and are visual QA artifacts, not evidence of new live backend mutations.
- Final redesigned Android build succeeded in 50 seconds (306 Gradle tasks), installed successfully and opened on emulator-5554. Full live media/grading acceptance remains as documented above.
