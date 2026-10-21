> Historical milestone record: all application demo modes and sample dashboards were removed on 21 October 2026. See [current backend-only status](backend_only.md).

# Day 5: Authentication, sessions, password recovery and profiles

Implemented against the supplied task plan (Day 5), updated LMS Mobile API Integration Guide (sections 8, 10, 12.1-12.7), Backend API Report and corresponding Postman folders. Reviewed the supplied commit standard; commits and pushes remain manual.

## Implementation

- Shared login calls the real backend and routes only by the returned STUDENT, INSTRUCTOR or ADMIN role. Preview role selection is no longer accessible through protected navigation.
- Student and Instructor registration, email OTP verification and resend are connected. Resend has a 60-second UI cooldown; backend cooldown rules remain authoritative.
- AuthProvider handles session state, secure token persistence and full-profile restoration at startup. Offline restoration offers Retry or Sign in again.
- Protected routes redirect unauthenticated or wrong-role access and remove prior routes. Refresh failure clears the account state and redirects protected screens to Login.
- The existing interceptor rotates both tokens, shares concurrent refresh work and retries once. Logout endpoints now receive the Bearer token; public authentication requests remain unauthenticated.
- Current-session logout and logout-all require confirmation, revoke the backend session and clear local credentials and profile state after success.
- Forgot password, reset OTP verification and setting a new password use the exact endpoints and fields. Temporary reset tokens stay in screen memory and are cleared on success/disposal.
- Profile tab loads the full profile, edits shared account fields and Student/Instructor fields, and sends only changes. Missing role profiles can be recreated with POST.
- Profile images use multipart field `profileImage`, explicit MIME type, upload progress and JPEG/PNG/WebP validation with a 5 MB limit. Removal uses DELETE. Display reads `profileImageUrl`.
- Forms show loading, success and readable failure messages. Validation responses identify the fields to check; server failures do not expose technical server messages.

## Verification on 15 October 2026

- Final Flutter analysis: no issues.
- All 24 automated tests passed. Coverage includes token rotation, concurrent refresh, one retry, refresh failure notification, role routing, secure session persistence through mocked storage, restoration, offline retry, both authenticated logout endpoints and entry/form UI.
- Android debug APK built successfully, installed on emulator-5554 and launched. Existing Gradle/SDK deprecation warnings remain non-blocking.
- Local backend readiness: HTTP 200, database connected.
- Protected full-profile request without a token: HTTP 401. Empty Student/Instructor registration requests: HTTP 422; no accounts created by those validation checks.
- With explicit user authorization, created a new Student account using user-provided details. Registration returned HTTP 201; email OTP verification succeeded.
- Live Student login, full-profile access, access/refresh token rotation, protected access using the rotated session, current-session logout and logout-all succeeded.
- Live password recovery succeeded: forgot-password, reset OTP verification, password reset to a user-selected different password, and login with that new password. Backend correctly rejected reusing the existing password (409).
- Shared account and Student profile PATCH operations succeeded using the existing user-supplied values. Temporary HTTP test sessions were logged out.
- No passwords, OTPs or tokens are stored in source, tests or this document.

## Remaining live acceptance checks

- Instructor registration/verification/login needs an independently registered Instructor account and accessible inbox. Existing supplied Student/Instructor accounts are suspended, as confirmed by the user; those accounts were not altered.
- Admin uses the shared login and returned role; successful live Admin login was reported by the user, not independently retested with Admin credentials in this session.
- Profile image upload/delete needs a selected test image and available backend media storage.
- Secure-storage round trip and process-restart restoration on the emulator, and a naturally expired access-token retry through the UI, remain manual acceptance checks. Automated tests cover the corresponding client behavior; direct HTTP tests verified backend refresh rotation.
- Course/dashboard data remains the Day 3 preview. Day 6 business integration was not started.

## Manual acceptance path

1. Sign in on the emulator with the newly verified Student account and its latest password.
2. Open Profile; verify account data, edit one field and save; optionally select a test profile photo and remove it.
3. Close/reopen the app and confirm that it restores the Student session.
4. Test Logout and Logout all devices; Back must not reopen protected screens.
5. Use Create an account to register a separate Instructor email, verify the received OTP, and confirm the Instructor dashboard.
6. Sign in with the working seeded Admin account and confirm the Admin dashboard.

## Updated readiness — 16 October 2026

See [Days 1–5 readiness audit](days_01_to_05_readiness.md) for the current 27-test result, backend health, outstanding live checks and demo removal plan. Demo now remains until supervisors restore backend account access; the earlier viva removal deadline is superseded.

