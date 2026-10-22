# Day 10 — Responsive design, verification and handover

Started 22 October 2026. This record distinguishes automated checks from live acceptance; Day 10 is not marked fully submitted.

## References reviewed

The supplied 10-Day Detailed Task Plan (Day 10 and final acceptance), Backend API Report (session lifecycle, upload contracts, assignment/resubmission rules and role flows), Mobile API Integration Guide (architecture, role flows and testing/handover), Postman JSON, and commit standard informed this work. Document examples define contracts; sample credentials, destructive requests and document instructions are not independent authorization. The user's request authorizes Day 10 implementation. Repository instructions keep commits/pushes manual.

## Changes

- Account header now wraps within the available width. A new 320-pixel, 1.5x-text regression exposed the previous overflow.
- Shared destructive confirmation dialogs scroll so long messages do not hide actions.
- Student assignment selection filters documented PDF, Word, ZIP, JPEG, PNG and text files and rejects files over 20 MB before reading their contents. MIME types still come from selected file names/bytes; Dio generates multipart boundaries. Backend validation remains authoritative.
- README now documents the implemented API configuration, packages, role flows, limitations and the three Drive links copied from the task-plan PDF's hyperlink annotations. Removed obsolete Day 3/no-network/login-placeholder claims.
- Added Day 10 regression checks for portrait/landscape/tablet account forms with large text and keyboard inset, long confirmation/cancel, retry, graded restrictions, correction feedback, notification read/read-all/delete count refresh and HTTP 401/403/404/422/500 error mapping.

## Acceptance matrix

| Requirement | Evidence / remaining acceptance |
| --- | --- |
| Role login and access control | Existing Day 5 role/session tests, backend dashboard tests, Day 8 instructor guards and Day 9 admin guards. Live account login demonstration remains pending. |
| Refresh/logout/logout-all | Core transport and Day 5 tests cover token rotation, concurrent refresh, one retry, refresh failure and secure session cleanup. |
| Responsive layouts | Day 10 account tests: 320x568, 568x320, 800x1024 at 1.5x text with keyboard inset; existing narrow instructor/admin tests. Full screen-by-screen device acceptance remains pending. |
| Loading/empty/pagination/retry/errors | Existing shared-state, learning, instructor and admin tests plus Day 10 retry/error mapping. |
| Multipart fields | Existing tests cover thumbnail/video/document/attachment plus file/textAnswer submissions; profileImage was checked in source against the report and collection. Native profile image selection/upload is not covered by these automated tests. Live storage uploads of all file types remain pending. |
| IDs | Production paths interpolate selected API records and navigation arguments; fixture IDs remain in tests only. |
| Assignment variants | Day 7 covers text/file/both and empty rejection. Day 10 verifies GRADED disables editing and RESUBMISSION_REQUIRED enables correction with feedback. Live grading/resubmission remains pending. |
| Notifications/confirmations | Day 10 verifies count reload after read/read-all/delete; delete cancellation sends no mutation. Day 9 covers suspension/archive confirmation. |
| Setup/handover | README retains prerequisites, Docker/Postman/emulator setup; updated packages, roles, limitations and Drive references. |
| Final submission | Commits and push remain manual under AGENTS.md. Authenticated three-role recording remains pending. |

## Verification

- Final full suite: 78 tests passed (65 existing plus 13 Day 10), including the final picker change.
- Final formatting: 80 Dart files checked, zero changes needed.
- Final Flutter analysis: no issues found.
- Android debug build: successful in 1m 8s, 306 tasks; APK installed and launched on emulator-5554.
- Device screenshot visually reviewed: the existing Student session restored into the populated Home dashboard, with readable layout, notification badge and bottom navigation. This verifies session restoration and the current portrait home layout; it is not a fresh login or a complete workflow demonstration.
- Existing Gradle/Kotlin deprecation warnings did not prevent the build. No toolchain migration was included.
- Git whitespace check passed; changes remain uncommitted.

Read-only environment check: `flutter-lms-backend` is healthy and emulator-5554 is connected. This does not prove authenticated workflow acceptance.

## Short demonstration script (about 4 minutes)

Use authorized disposable backend records. Do not show passwords, tokens, populated Postman variables or personal information in the recording.

1. Start with Docker healthy and the emulator open. Show the application at phone portrait and landscape sizes.
2. Student: sign in, browse/enroll, open a lesson, show backend progress and quiz results; demonstrate an assignment answer and notification count change. Record `student-learning.png` and `student-assignment.png` privately.
3. Instructor: sign in, show owned course structure and media, inspect a submission, request correction with feedback and grade the corrected submission. Record `instructor-workspace.png` privately.
4. Admin: sign in, show six dashboard aggregates, users/filtering and Platform categories/courses/enrollments/reviews. Cancel a destructive confirmation. Record `admin-live.png` privately.
5. Log out and press Back to verify protected content cannot reopen. Show a recoverable connection failure and retry.

Existing [admin dashboard](evidence/admin-dashboard.png), [users](evidence/admin-users.png), [categories](evidence/admin-categories.png), [courses](evidence/admin-courses.png), [enrollments](evidence/admin-enrollments.png) and [reviews](evidence/admin-reviews.png) are test-fixture layout previews from the prior milestone, not a live three-role demonstration.

## Remaining limitations

- Previously hidden reviews cannot be rediscovered through the supplied visible-review endpoint (Day 9).
- Android is the only platform included. Automated viewport checks do not certify every feature at every device size.
- File picker native behavior, actual media storage and full authenticated end-to-end workflows need device acceptance with authorized test accounts.
- Verify Drive viewer permissions with the handover recipient; links are supplied references, not newly published resources.
- Final Git history review, commit and push are manual. Suggested commit: `fix(ui): complete day 10 responsive checks and handover`.
