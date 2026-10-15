# Day 4: Backend and core API foundation

Implemented using the supplied updated mobile API integration guide, sections 4–8, and the supplied Postman collection. Day 5 authentication screens and session routing are not yet integrated; the existing UI remains a local preview.

## Verified on 14 October 2026

- Approved image `dckuma/flutter-lms-backend:v1.0.0` exists locally.
- Existing `flutter-lms-backend` container started with host/container port 5000. Docker reports healthy; readiness reports database connected.
- Windows `http://localhost:5000/api/v1/health/ready`: HTTP 200.
- Android emulator `emulator-5554` reached `http://10.0.2.2:5000/api/v1/health/ready`: HTTP 200 using an emulator-side HTTP request.
- Added dio, flutter_secure_storage, provider, image_picker, file_picker, mime and http_parser; resolved versions are in pubspec.lock.
- Main Android manifest grants Internet permission; debug manifest allows local HTTP. Release configuration does not enable cleartext traffic.
- AppConfig uses the emulator URL without `/api/v1`, with 20-second connection and 30-second receive timeouts; API_BASE_URL can override the host.
- TokenStorage saves access/refresh tokens and role using secure storage and deletes only its own keys.
- ApiClient is provided at application startup. AuthInterceptor attaches protected Bearer tokens, excludes public auth calls, shares concurrent refresh work, saves both rotated tokens, and retries at most once. Refresh failure clears stored session keys. No Refresh Token UI exists.
- ApiException maps connection, timeout, cancellation, certificate and backend failures to readable messages. Dio failures expose it through DioException.error.
- ApiResponse supports typed data decoding and pagination metadata.
- Final static analysis: no issues. Final test suite: all 16 tests passed, including six API tests covering refresh rotation, failure, public login exclusion, concurrent refresh sharing, the one-retry limit and response/error mapping.

## Live authentication results

The supplied test credentials were checked against the local container without persisting passwords or tokens:

| Role | Login status | Backend response |
| --- | --- | --- |
| Student | 403 | This account has been suspended |
| Instructor | 401 | The email address or password is incorrect |
| Admin | 401 | The email address or password is incorrect |

Successful login, protected access and live refresh could not proceed. Request an active student account and current instructor/admin credentials from the backend owner. No account permissions or backend data were changed.

## Postman steps still required

Postman was not found among installed/running applications or standard installation paths. API requests above were direct HTTP checks, not Postman runs.

1. Install/open Postman Desktop.
2. Import the supplied `Assignment Docs/Flutter LMS Backend API.json` collection.
3. Import `docs/postman/local.postman_environment.json` and select **Flutter LMS Local**. Its baseUrl is `http://localhost:5000`; all credentials and tokens are blank.
4. Enter corrected test credentials locally. Run only selected login, refresh and protected read requests; do not run the full collection, which includes data mutations and archive/delete actions.
5. Confirm successful login, role values, protected requests and rotated token capture using the supplied collection scripts. Keep exported environments free of passwords and tokens.

Docker Hub login was not repeated because the approved image was already present. Its prior login/pull history was not independently verified. The existing container has the required `unless-stopped` restart policy.

## Android build verification

The initial build attempt was stopped after a delay. A later `flutter run` exposed a Kotlin incremental-cache close failure in `android_file_picker`. Setting `kotlin.incremental=false` in `android/gradle.properties` resolved that failure. The single-worker helper then completed the updated debug APK build successfully, installed it on `emulator-5554`, and launched the app. The build tools also installed CMake 3.22.1 required by the JNI dependency. Java, SDK XML and plugin deprecation warnings remain non-blocking. On-device secure-storage round-trip behavior has not been separately tested.
