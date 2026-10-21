# Flutter LMS

Flutter LMS is a mobile learning management application for **Students, Instructors and Administrators**. It is being developed against a supplied backend API, delivered as a Docker image, with a Postman collection and integration guides defining the API contract.

This README describes the application, required software, Windows installation steps and commands for running and checking the project.

## Project overview

| Role | Planned application capabilities |
| --- | --- |
| Student | Register and verify an account, browse and enroll in courses, access lessons, track learning progress, complete quizzes, submit assignments, review courses, read notifications and manage a profile. |
| Instructor | Build and publish courses, sections and lessons; upload learning materials; manage quizzes and assignments; review attempts and submissions; grade work and inspect enrollments. |
| Admin | Manage users and account status, maintain course categories, inspect platform courses and enrollments, moderate reviews and archive content. |
| Shared account features | Login, role-based navigation, session restoration, automatic token refresh, logout, password recovery and profile management. |

The backend is the source of truth for permissions, validation, quiz scores, assignment status and official learning progress. Flutter presents backend results and provides the mobile user interface.

## Current implementation status

Day 4 core API foundation is added; backend health and emulator HTTP connectivity are verified. See `docs/day_04.md` for completed checks and the remaining Postman/account blockers. The login UI still uses the Day 3 local preview.

Day 3 is implemented: a splash screen, three-page onboarding with PageView, Student/Instructor/Admin dashboard shells, shared feedback states, and role-specific sample data separated from presentation.

Launch flow: Splash → Onboarding → Login → Home role preview → Dashboard. Skip and Get started clear the entry routes; Back on onboarding returns to the preceding page and cannot reopen the splash. Onboarding appears on every fresh launch for this preview; persistence and real session routing are later work. The existing UI structure follows the integration guide’s feature folders and shared core components.

Use any valid email address and a password of at least 8 characters containing uppercase, lowercase, a number and a special character to open the local preview. This validates input only and does not authenticate an account. Home exposes all three dashboard roles. Dashboard navigation and shortcuts open explicit coming-soon states.

Formatting, analysis and 10 widget tests pass. See `docs/day_03.md` for scope and verification.
## Technology and prerequisites

| Component | Usage |
| --- | --- |
| Flutter and Dart | Mobile application and Material UI; tested with Flutter 3.47.7 / Dart 3.13.5. |
| Android Studio and Android SDK | Android tooling and emulator; tested with API 36. |
| Git | Version control using the supplied Conventional Commits guide. |
| Docker Desktop | Runs the supplied LMS backend for API development. |
| Postman Desktop | Verifies backend requests before Flutter integration. |
| Dio, secure storage and Provider | Installed for the Day 4 core network and secure-storage foundation. |

The instructions below target a Windows PC running the app in an Android emulator. Only the Android platform is currently included in the repository.

## Run the application

If Flutter and Android Studio are already installed, use these steps. Otherwise, complete the installation guide below first. Paths and device names in commands are examples; replace them with your own installation and project locations.

1. Open Android Studio → **Device Manager** and press the play button beside your configured emulator. Wait until the Android home screen appears. If it is already running, leave it open.
2. Open PowerShell or a VS Code terminal.
3. Run the commands below **one at a time**:

```powershell
Set-Location 'C:\Development\flutter_lms'
flutter pub get
flutter devices
./scripts/run_android.ps1
```

`flutter devices` should show an Android device such as `emulator-5554`. The helper builds the app, installs it and opens **Flutter LMS**. The first build may take several minutes; wait for it to finish.

**Expected result:** the green-and-white login screen shown at the end of this guide. The current login preview works without the backend after dependencies are downloaded. Future API-driven features require the backend to be running.

If the device ID is different, use the ID from `flutter devices`:

```powershell
./scripts/run_android.ps1 -Device emulator-5556
```

The helper targets an **Android x64 emulator**. After closing the app, you can reopen **Flutter LMS** from the emulator's app drawer. After changing source code, run the helper again to rebuild and install your changes.

## Set up a new Windows PC

Skip this section if the quick start works. Internet access is needed to download Flutter, Android tools and project dependencies.

### 1. Install Git and Flutter

- Install [Git for Windows](https://git-scm.com/downloads/win).
- Download the Flutter SDK using the [official Windows installation guide](https://docs.flutter.dev/install/manual). Use Flutter **3.47.7** to match the version used for this project. Its Dart SDK is **3.13.5**; Dart is included with Flutter and does not need a separate installation.
- Extract Flutter into a writable folder, for example `C:\Development\flutter`.
- Open Windows **Edit environment variables for your account** → select **Path** → **Edit** → **New**, and add the Flutter `bin` directory, for example `C:\Development\flutter\bin`.
- Close and reopen PowerShell and VS Code so they pick up the new Path.

Check the installation:

```powershell
git --version
flutter --version
dart --version
```

The project's `pubspec.yaml` requires Dart **3.13.5 or a compatible newer 3.x version**. Matching the tested Flutter version avoids unexpected toolchain changes.

### 2. Install Android Studio and Android tools

Install [Android Studio](https://developer.android.com/studio) and complete its setup wizard. Open **Tools → SDK Manager**, or **More Actions → SDK Manager** on its welcome screen.

In **SDK Platforms**, install **Android API 36**.

In **SDK Tools**, install:

- Android SDK Build-Tools **36.0.0**.
- Android SDK Platform-Tools.
- Android SDK Command-line Tools.
- Android Emulator.
- NDK (Side by side) **28.2.13676358**, used by the tested Flutter SDK.
- CMake **4.1.2**, explicitly selected by this project's Android build.

Enable **Show Package Details** to select specific versions of NDK, CMake or Build-Tools. Flutter determines the NDK version through `flutter.ndkVersion`; using a different Flutter SDK may change that requirement.

Note the **Android SDK Location** shown in SDK Manager. Configure Flutter with that location. The following commands use an example SDK location, then open the Android license check:

```powershell
flutter config --android-sdk 'C:\Android\Sdk'
flutter doctor --android-licenses
flutter doctor -v
```

Read each license and accept it if you agree. The Android toolchain should pass its checks. Flutter normally uses Android Studio's bundled Java runtime. If Doctor points to an unsuitable Java installation, configure the bundled runtime using its actual path:

```powershell
flutter config --jdk-dir 'C:\Program Files\Android\Android Studio\jbr'
```

The launch helper also uses that standard Android Studio Java location when it exists. If Android Studio is installed elsewhere, set `JAVA_HOME` to its `jbr` directory in your terminal before using the helper.

See the [official Flutter Android setup guide](https://docs.flutter.dev/platform-integration/android/setup) and [Android NDK/CMake installation guide](https://developer.android.com/studio/projects/install-ndk) for full installation details.

### 3. Create and start an emulator

In Android Studio, open **Tools → Device Manager**:

1. Choose **Create Virtual Device**.
2. Select a phone, such as **Pixel 9a**.
3. Download and choose an **API 36 x86_64** system image for an Intel/AMD Windows PC.
4. Finish the wizard and start the device with its play button.
5. Wait for the Android home screen.

Verify detection in PowerShell:

```powershell
flutter emulators
flutter devices
```

An emulator's configuration name (such as `Pixel_9a`) is different from its running device ID (such as `emulator-5554`). You can also launch the configured device from a terminal:

```powershell
flutter emulators --launch Pixel_9a
```

Use the name returned by `flutter emulators` if yours differs. If the emulator reports a virtualization problem, follow the [Android emulator acceleration instructions](https://developer.android.com/studio/run/emulator-acceleration).

### 4. Open the project and fetch dependencies

Copy or clone the project, then open the **flutter_lms** folder in VS Code or Android Studio. For VS Code, install the Flutter extension, which also provides Dart support.

Open a terminal in the folder containing `pubspec.yaml`:

```powershell
flutter pub get
flutter doctor -v
flutter devices
```

Replace the example project path with your own project location. Do not copy another developer's `android/local.properties`; it contains machine-specific SDK paths and is ignored by Git. A normal Flutter build/run generates the file when needed. If the helper reports it missing, generate Android configuration once before retrying:

```powershell
flutter build apk --debug --config-only
```

Then run:

```powershell
./scripts/run_android.ps1
```

## Normal Flutter development and hot reload

When sufficient memory is available, you can use Flutter's normal development session:

```powershell
flutter run -d emulator-5554
```

While it is running, press **r** for hot reload, **R** for hot restart or **q** to end the session. In VS Code, you can instead choose the Android emulator and press **F5**.

If the ordinary launcher encounters memory failures, use the provided helper. The quick-start helper builds directly with Gradle using one worker, waits for that build to finish, then installs and opens the APK with Android's device tools. It does not provide hot reload or a debugger connection.

The helper temporarily uses `.build-tmp` for Java's temporary files to avoid the loopback-path error observed in the desktop app environment. It restores its environment variables afterward. Gradle heap, worker and Kotlin compiler settings are limited in `android/gradle.properties` to reduce memory use. Close unnecessary applications and run builds and tests separately.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| `flutter` is not recognized | Add the Flutter SDK's `bin` folder to your user Path, then reopen the terminal. |
| No `pubspec.yaml` found | Open the terminal in the `flutter_lms` folder, not its parent. |
| No Android device appears | Start the emulator, wait for its home screen, then run `flutter devices` again. Use its actual device ID. |
| Android licenses or command-line tools missing | Install Command-line Tools through SDK Manager, then run `flutter doctor --android-licenses`. |
| CMake 4.1.2 or the NDK is missing | Install the requested version through SDK Manager with Show Package Details enabled. |
| Java loopback connection error | Use `./scripts/run_android.ps1`, which selects a project-local temporary folder. |
| Paging file too small / Java or Dart out of memory | Close unnecessary applications. Use the helper and run tests after the build finishes. These errors indicate PC memory pressure; the helper cannot guarantee a build if the system has no memory available. |
| Kotlin `Could not close incremental caches` while compiling an Android plugin | This Windows setup disables Kotlin incremental compilation with `kotlin.incremental=false` in `android/gradle.properties`. Keep this setting when running `flutter run`; Kotlin compilation may take longer. |
| PowerShell blocks the helper script | Use the normal Flutter command from an ordinary terminal, or use an execution policy approved for your PC. On managed PCs, ask your administrator. |
| Visual Studio warning in Flutter Doctor | This project targets Android. Missing Windows C++ desktop tools do not block the Android target. |
| Login does not open a dashboard | Use a valid email and 8 or more password characters to open Home. Dashboard routes are placeholders; API authentication is scheduled later. |

## Backend installation and startup

The integrated application will require the authorized LMS backend. The current login preview works without it. Obtain the approved container image name, version, API documentation and Postman collection through your organization's authorized access process. Private resource links, registry identifiers, account details and access credentials are intentionally omitted from this README.

Install [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) and [Postman Desktop](https://www.postman.com/downloads/). Start Docker Desktop and wait for its engine to be ready.

For first-time setup, run these commands in PowerShell. At the prompt, enter the approved image name including its version tag. The value stays in the current terminal session:

```powershell
docker version
docker login
$backendImage = Read-Host 'Enter the authorized backend image and version tag'
docker pull $backendImage
docker run -d --name flutter-lms-backend --restart unless-stopped -p 127.0.0.1:5000:5000 $backendImage
```

This port mapping exposes the backend on the local Windows host for development. It does not intentionally publish it to other devices on the network. The image must match the project's approved backend contract. Follow the privately supplied runtime instructions for any additional configuration; never place runtime secrets in this README or in source control.

If a container with this name already exists, start it instead of running the creation command again:

```powershell
docker start flutter-lms-backend
```

Check container status:

```powershell
docker ps --filter name=flutter-lms-backend
docker inspect --format '{{.State.Status}}' flutter-lms-backend
```

If the approved image provides a health check, inspect it with:

```powershell
docker inspect --format '{{.State.Health.Status}}' flutter-lms-backend
```

To stop, start or restart the local backend:

```powershell
docker stop flutter-lms-backend
docker start flutter-lms-backend
docker restart flutter-lms-backend
```

## Postman setup

1. Obtain the approved collection through an authorized channel.
2. Open Postman, select **Import**, and choose the collection JSON file.
3. Set its `baseUrl` variable to `http://localhost:5000` for local Windows testing.
4. Check that an active environment does not override the collection with an unintended value.
5. Follow the private API contract to test connectivity and authentication before dependent requests.
6. Use returned record IDs and the collection's token-handling scripts rather than hardcoding values.

Store passwords and tokens in your approved local secret storage. Do not publish populated environments, collection exports containing credentials, API responses with user information or backend logs.

## Android emulator networking

| Client | Backend base URL |
| --- | --- |
| Postman on Windows | `http://localhost:5000` |
| Flutter inside the Android emulator | `http://10.0.2.2:5000` |

The emulator uses `10.0.2.2` to reach the Windows host. Do not use `localhost` for the host backend from inside the emulator. Keep `/api/v1` out of the base URL because endpoint paths already include it; append only the endpoint paths defined in the authorized API contract.

The current app has no API client or base URL configuration. When the network layer is implemented, configure the emulator address, Android Internet permission and development-only cleartext HTTP access as required by the integration guide. A deployed backend should use HTTPS. These are planned integration requirements, not completed application features.

## Project structure

```text
lib/
  main.dart / app.dart               Application entry and Material app
  core/
    routing/                        app_router.dart and route_names.dart
    theme/                          Shared theme
    utils/                          Existing validators and UI message
    widgets/                        Inputs, buttons and standard feedback states
  shared/
    models/                         Shared dashboard preview model definitions
    widgets/                        Reusable dashboard shell and cards
  features/
    auth/screens/                   Local login form (Day 2 preview)
    home/screens/                   Development role preview
    onboarding/screens/             Splash and three onboarding pages
    student/dashboard/
      models/                       Student sample dashboard data
      screens/                      StudentHomeScreen
    student/courses/widgets/        Course detail widgets
    student/learning/
      services/                     Student catalogue, enrollment and lesson API
      screens/                      Student learning and course flows
      widgets/                      Lesson player, progress and learning summary
    student/assignments/screens/    Student assignment submissions
    student/quizzes/screens/        Student quiz attempts
    student/reviews/screens/        Student course reviews
    student/notifications/screens/  Student notification inbox
    student/services/              Student activity API operations
    student/widgets/               Shared student activity widgets
    instructor/
      screens/                      Instructor home, workspace and editors
      services/                     Authenticated instructor API operations
      widgets/                      Dashboard, detail views and shared studio UI
    admin/dashboard/
      models/                       Admin sample dashboard data
      screens/                      AdminHomeScreen
assets/                             Bundled illustrations, images and fonts
android/                            Existing Android host and splash resources
test/                               Login, entry flow, dashboard and state tests
docs/day_03.md                      Current milestone scope and verification
```

Current milestone is Day 3. The guide's network, storage, API constants, services, providers, session models and later feature folders are deferred until their scheduled days are explicitly authorized. Only folders containing implemented Day 1-3 code are created.

## Check code quality

Run these from the project folder, separately from the Android build:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --concurrency=1
```

During initial verification, formatting and analysis passed, both UI tests passed, and the Android debug APK built, installed and opened successfully on an emulator. The direct build/install steps succeeded; the helper packages those steps for repeat use. The normal Flutter launcher still encountered system memory pressure in a follow-up check.

## Planned development

The remaining application work includes API-backed role dashboards, secure API/session handling, account recovery, student learning and assessment workflows, instructor content management, administrator tools and full workflow testing.

These are planned capabilities. Update the current implementation status as features are completed, and keep internal progress evidence in the appropriate authorized location.

## Development conventions

- Keep features organized under `lib/features/`; introduce shared networking and session code when integration begins.
- Use exact backend methods, paths, field names and status values from the supplied API resources.
- Use IDs returned by the backend rather than hardcoded test IDs.
- Planned API-driven screens should provide loading, empty, success and error states, with role-appropriate access and confirmation for destructive actions.
- Never commit tokens, passwords, private keys, database credentials or machine-specific SDK configuration.
- Use small, meaningful Conventional Commits, such as `feat(auth): add shared login UI`.

GitHub repository creation, commits and pushing are handled manually by the developer. The provided `.gitignore` excludes generated files and local SDK configuration.

## Data protection

- Keep internal API documents, shared-drive resources, backend registry details and access instructions in authorized private channels.
- Never commit passwords, tokens, private keys, signing keystores, populated environment files or user data.
- Keep machine-specific SDK configuration out of source control.
- Use authenticated, role-authorized access for integrated features; the current preview does not implement those controls yet.
- Use HTTPS for deployed API connections. Local HTTP addresses in this guide are development examples only.

The installation links in this README point only to public software vendors and public tooling documentation. No internal data-resource links or shared conversation links are included.

## Current milestone: Day 5

Authentication, sessions, password recovery and profile forms now use the real backend. See [Day 5 verification and remaining acceptance checks](docs/day_05.md). Earlier Day 1-4 preview descriptions are historical.

## Current milestone: Day 6

Student course browsing, search, category filtering, pagination, enrollment, My Courses, curriculum, lesson viewing and server-returned progress are implemented. Debug demo sessions use the same screens with isolated in-memory learning data. See [Day 6 verification and remaining acceptance checks](docs/day_06.md). Day 1-5 milestone descriptions above are historical.

## Current milestone: Day 7

Student quizzes, assignment submissions/corrections, course reviews, notifications with unread counts, and profile learning summaries are implemented. See [Day 7 implementation and acceptance checks](docs/day_07.md). Real grading and statuses remain backend-controlled; debug demo data stays isolated. Earlier milestone descriptions are historical.

## Current milestone: Day 8

Instructor dashboard, owned-course building, sections and lessons, media uploads, quiz/question authoring, assignment publication, learner attempts/submissions, grading/corrections, enrollments and archiving are implemented. The debug Instructor demo supports these workflows with session-local sample data and simulated uploads. Open **Explore viva demo → Instructor demo** from login. Real instructor login, dashboard and draft creation were verified after the earlier backend connectivity failure; further live acceptance remains pending. See [Day 8 verification and remaining live acceptance](docs/day_08.md). Earlier milestone descriptions are historical.

### Rebuilding after native package changes

After adding or changing packages such as `video_player` or `url_launcher`, stop the running app and perform a full Android build/install with `./scripts/run_android.ps1`. Hot reload/restart cannot install native plugins into an older APK. If video playback reports a platform-channel connection error, rebuild/reinstall before investigating the media URL. The helper retains the installed app's local data.
