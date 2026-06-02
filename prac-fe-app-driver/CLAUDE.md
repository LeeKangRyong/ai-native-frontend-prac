# Driver App Guide (prac-fe-app-driver)

## Build & Dev Commands
- **Install Dependencies:** `flutter pub get`
- **Run Development Server (Clean & Run):** `flutter clean && flutter pub get && flutter run`
- **Build Project (Android APK):** `flutter build apk --release`
- **Build Project (iOS):** `flutter build ios --release --no-codesign`
- **Lint / Code Style Check:** `flutter analyze`
- **Format Code:** `flutter format .`

## Tech Stack & Rules
- Language: Dart
- Framework: Flutter
- Rule: Do not import any files from outside this `prac-fe-app-driver` directory.