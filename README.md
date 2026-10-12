# Flutter LMS

Flutter LMS is a mobile learning management application for **Students, Instructors and Administrators**. It is being developed against a supplied backend API, delivered as a Docker image, with a Postman collection and integration guides defining the API contract.

This README is the setup and development guide for the whole project. Implementation progress is recorded separately in [daily progress notes](docs/day_01.md).

## Project overview

| Role | Planned application capabilities |
| --- | --- |
| Student | Register and verify an account, browse and enroll in courses, access lessons, track learning progress, complete quizzes, submit assignments, review courses, read notifications and manage a profile. |
| Instructor | Build and publish courses, sections and lessons; upload learning materials; manage quizzes and assignments; review attempts and submissions; grade work and inspect enrollments. |
| Admin | Manage users and account status, maintain course categories, inspect platform courses and enrollments, moderate reviews and archive content. |
| Shared account features | Login, role-based navigation, session restoration, automatic token refresh, logout, password recovery and profile management. |

The backend is the source of truth for permissions, validation, quiz scores, assignment status and official learning progress. Flutter presents backend results and provides the mobile user interface.

## Current implementation status

The Android project and shared login interface are implemented. Email/password fields, password visibility and a login preview action are available. Backend requests, authentication, dashboards and other role workflows are **planned and not yet implemented**. The current login button displays a preview message and does not sign in.

The Android debug app has been built, installed and opened on a Pixel 9a emulator. Formatting, analysis and two UI tests passed during verification. See [development notes](docs/day_01.md) for evidence and known memory limitations.

## Technology and prerequisites

| Component | Usage |
| --- | --- |
| Flutter and Dart | Mobile application and Material UI; tested with Flutter 3.47.7 / Dart 3.13.5. |
| Android Studio and Android SDK | Android tooling and emulator; tested with API 36. |
| Git | Version control using the supplied Conventional Commits guide. |
| Docker Desktop | Runs the supplied LMS backend for API development. |
| Postman Desktop | Verifies backend requests before Flutter integration. |
| Dio, secure storage and Provider | Planned networking, session storage and state-management components; not installed or implemented in this version. |

The instructions below target a Windows PC running the app in an Android emulator. Only the Android platform is currently included in the repository.

## Quick start on this PC

Flutter, Android Studio, the Android SDK and the Pixel 9a emulator are already installed. Start with these steps; you do not need to reinstall them.

1. Open Android Studio → **Device Manager** and press the play button beside **Pixel 9a**. Wait until the Android home screen appears. If it is already running, leave it open.
2. Open PowerShell or a VS Code terminal.
3. Run the commands below **one at a time**:

```powershell
Set-Location 'D:\FlutterProjects\Onboarding Task Assignment\flutter_lms'
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
- Extract Flutter into a writable folder, for example `E:\Flutter\flutter`.
- Open Windows **Edit environment variables for your account** → select **Path** → **Edit** → **New**, and add the Flutter `bin` directory, for example `E:\Flutter\flutter\bin`.
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

Note the **Android SDK Location** shown in SDK Manager. On this PC it is `E:\sdk`. Configure Flutter with your actual location, then review the Android licenses:

```powershell
flutter config --android-sdk 'E:\sdk'
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

On another PC, replace the quick-start folder path with your own project location. Do not copy another developer's `android/local.properties`; it contains machine-specific SDK paths and is ignored by Git. A normal Flutter build/run generates the file when needed. If the helper reports it missing, generate Android configuration once before retrying:

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

On this workstation, the ordinary launcher encountered memory failures. The quick-start helper builds directly with Gradle using one worker, waits for that build to finish, then installs and opens the APK with Android's device tools. It does not provide hot reload or a debugger connection.

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
| PowerShell blocks the helper script | Use the normal Flutter command from an ordinary terminal, or use an execution policy approved for your PC. On managed PCs, ask your administrator. |
| Visual Studio warning in Flutter Doctor | This project targets Android. Missing Windows C++ desktop tools do not block the Android target. |
| Login does not open a dashboard | The current version provides a login preview. Authentication and dashboards are not implemented yet. |

## Backend setup with Docker

The supplied backend image is `dckuma/flutter-lms-backend:v1.0.0`. Docker and Postman are needed for API development and the planned integrated application. The current login preview does not call the backend.

Install [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) and [Postman](https://www.postman.com/downloads/). Start Docker Desktop and wait until the engine is ready. Sign in to Docker Hub when required for image access.

For a first-time backend setup, run:

```powershell
docker version
docker login
docker pull dckuma/flutter-lms-backend:v1.0.0
docker run -d --name flutter-lms-backend --restart unless-stopped -p 5000:5000 dckuma/flutter-lms-backend:v1.0.0
```

The assignment supplies a prepared backend image. It does not require running backend source code, configuring a separate database or adding an `--env-file`.

If `flutter-lms-backend` already exists, start that container instead of creating another one:

```powershell
docker start flutter-lms-backend
```

Verify its status and readiness:

```powershell
docker ps
docker inspect --format '{{.State.Health.Status}}' flutter-lms-backend
docker logs --tail 50 flutter-lms-backend
Invoke-RestMethod 'http://localhost:5000/api/v1/health/ready'
```

The container should be running, expose port 5000 and report healthy. The supplied setup conversation records `/api/v1/health/ready` as the readiness endpoint. For shutdown or a later restart:

```powershell
docker stop flutter-lms-backend
docker start flutter-lms-backend
```

This workstation already had the approved container running and healthy during the environment check. Backend commands here document the project setup; they do not mean API integration is already implemented in Flutter.

## Postman and API resources

Download the supplied materials:

- [Backend API Report](https://drive.google.com/file/d/1Ld_IvM_4GHhoaakGetEbuWAv5LH_aCf3/view?usp=sharing): endpoint paths, methods, roles, request fields and expected results.
- [Mobile API Integration Guide](https://drive.google.com/file/d/18kwcNqfnkxLb0TZER_TNbocSUFs4Acl2/view?usp=sharing): runtime setup, networking and recommended application architecture.
- [Postman collection JSON](https://drive.google.com/file/d/16DjEWlX0f889g6Njln-8Iy38kxUlBXKc/view?usp=sharing): executable request examples, variables and token-capture scripts.

Open Postman, choose **Import**, and select the downloaded collection JSON. Set the collection or active environment variable `baseUrl` to `http://localhost:5000`. Ensure an environment variable does not unintentionally override the collection value.

Verify readiness first. During API implementation, run authentication requests before protected requests, use returned IDs for dependent requests, and follow the collection's scripts for tokens. Keep credentials and tokens out of source control. The supplied API Report and collection define the exact endpoint contract.

## Android emulator networking

| Client | Backend base URL |
| --- | --- |
| Postman on Windows | `http://localhost:5000` |
| Flutter inside the Android emulator | `http://10.0.2.2:5000` |

The emulator uses `10.0.2.2` to reach the Windows host. Do not use `localhost` for the host backend from inside the emulator. Keep `/api/v1` out of the base URL because endpoint paths already include it; the planned login request URL is `http://10.0.2.2:5000/api/v1/auth/login`.

The current app has no API client or base URL configuration. When the network layer is implemented, configure the emulator address, Android Internet permission and development-only cleartext HTTP access as required by the integration guide. A deployed backend should use HTTPS. These are planned integration requirements, not completed application features.

## Project structure

```text
lib/
  main.dart                         Starts the Flutter application
  app.dart                          Material application and initial screen
  features/auth/presentation/
    login_screen.dart               Shared login preview
android/                            Android host and build configuration
test/widget_test.dart               Login behavior and keyboard layout checks
scripts/run_android.ps1             Build, install and open on an x64 emulator
docs/day_01.md                      Day 1 progress and Flutter learning notes
pubspec.yaml                        SDK requirements and dependencies
```

## Check code quality

Run these from the project folder, separately from the Android build:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --concurrency=1
```

During initial verification, formatting and analysis passed, both UI tests passed, and the Android debug APK built, installed and opened successfully on Pixel 9a. The direct build/install steps succeeded; the helper packages those steps for repeat use. The normal Flutter launcher still encountered system memory pressure in a follow-up check.

## Implementation roadmap

The assignment defines the following development sequence. This table describes planned scope; only the initial project and login UI are implemented.

| Stage | Scope | Status |
| --- | --- | --- |
| Day 1 | Environment verification, project initialization, shared login UI and fundamentals | Project/UI complete; GitHub handled manually |
| Day 2 | Navigation, forms, validation, assets and reusable styling | Planned |
| Day 3 | Splash, onboarding, role dashboard shells and shared UI states | Planned |
| Day 4 | Docker/Postman verification and the network/session foundation | Flutter integration planned; existing backend environment verified |
| Day 5 | Authentication, token handling, password recovery and profiles | Planned |
| Day 6 | Course browsing, enrollment, curriculum, lessons and progress | Planned |
| Day 7 | Student quizzes, assignments, reviews and notifications | Planned |
| Day 8 | Instructor course building and learner management | Planned |
| Day 9 | Admin management, shared state, role navigation and animations | Planned |
| Day 10 | Responsive polish, full workflow testing and handover | Planned |

As features are completed, update this README's status and maintain daily progress notes with integrated endpoints, testing evidence and unresolved issues.

## Development conventions

- Keep features organized under `lib/features/`; introduce shared networking and session code when integration begins.
- Use exact backend methods, paths, field names and status values from the supplied API resources.
- Use IDs returned by the backend rather than hardcoded test IDs.
- Planned API-driven screens should provide loading, empty, success and error states, with role-appropriate access and confirmation for destructive actions.
- Never commit tokens, passwords, private keys, database credentials or machine-specific SDK configuration.
- Use small, meaningful Conventional Commits, such as `feat(auth): add shared login UI`.

GitHub repository creation, commits and pushing are handled manually by the developer. The provided `.gitignore` excludes generated files and local SDK configuration.

## References and progress

- Assignment: `../Assignment Docs/Flutter_LMS_10_Days_Detailed_Task_Plan.pdf`.
- Commit guide: `../Assignment Docs/git_commit_standard.pdf`.
- [Initial progress and Flutter fundamentals](docs/day_01.md).
- [Flutter installation](https://docs.flutter.dev/install/manual).
- [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup).
- [Flutter layouts](https://docs.flutter.dev/ui/layout).

The assignment PDFs are supplied separately from the application source. The Google Drive API resources above are the handover references for backend implementation.

## Current application preview

![Shared login screen on the Pixel 9a emulator](docs/evidence/day-one-login.png)
