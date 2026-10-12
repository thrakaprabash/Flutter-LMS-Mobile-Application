# Day 2: Navigation, Forms, Validation, Assets and Theme

Scope follows Day 2 of the supplied Flutter LMS task plan. Day 3 dashboard shells, splash, PageView onboarding and API integration are excluded. Git commits and pushing remain manual.

## Completed

- Named routes: `/`, `/home`, `/onboarding`, `/student`, `/instructor`, `/admin`.
- Login uses Form, TextFormField, controllers, validators and keyboard submission. Controllers are disposed correctly.
- Empty/invalid email and empty/short password show inline messages. Any valid email and at least 8 password characters with uppercase, lowercase, a number and a special character open Home. This temporary rule is for UI practice, not a backend password policy or account authentication.
- Home links to simple onboarding and role route placeholders. AppBar Back and explicit Back buttons return through the navigation stack.
- Preview password is cleared before navigation and never passed as a route argument.
- Shared ThemeData configures colors, typography, inputs, buttons and cards.
- Reusable AppInputField, PrimaryButton, SectionHeader and AppMessage components are used across screens.
- A locally drawn book image is declared in pubspec.yaml and displayed with an accessible label. Material icons remain enabled.
- Roboto regular/medium fonts are bundled from the installed Flutter SDK and registered in pubspec.yaml. License and copyright notices are included in assets/fonts. No project-specific brand font was supplied; Roboto is the current local default, subject to brand approval.

## Verification

- `dart format lib test`: passed.
- `flutter analyze`: no issues found.
- `flutter test --concurrency=1`: all three tests passed.
- Tests cover empty/malformed inputs, password visibility, valid local navigation, all four placeholder routes, Back navigation, cleared password, theme font selection, image loading, and a 320 x 568 screen with keyboard inset.

## Manual walkthrough

1. Submit empty inputs and inspect both inline errors.
2. Enter an invalid email and a short password; inspect the specific errors.
3. Enter `learner@example.com` and `Preview123!`, toggle visibility, then press Log in or the keyboard Done action.
4. Confirm Home explains local preview status. Open each route and return using Back.
5. Return to login and confirm the password is cleared.

## Learning notes

Navigator.pushNamed adds a screen to the stack; Navigator.pop returns to the previous screen. FormState.validate runs each field validator. Controllers expose current input and must be disposed when their State ends. ThemeData supplies consistent component defaults. pubspec.yaml asset/font paths are relative to the project root.

No backend endpoints were integrated. No sessions or role permissions are claimed by these development previews.

## Login visual refresh

Added an AI-generated campus photograph of university students, a rounded photo banner, tighter spacing, a softly elevated login card, and refreshed supporting text. Local validation and navigation remain unchanged.

Image generated with the built-in imagegen tool. Prompt: Natural editorial photograph of four adult university students collaborating around a laptop and notebooks on a leafy modern campus; warm morning light, forest green and cream accents, landscape composition, no text or logos. Asset: assets/images/university-students.png.
