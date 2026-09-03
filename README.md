# Line Balance Platform

Industrial Engineering platform for Work Measurement, Line Balance, VSM, Downtime, Continuous Improvement and management reporting.

## Current status
V0.4.1 — Time Study cycle recording foundation.

## Local development
Use the Flutter version specified by the CI workflow. The Android directory is intentionally not required in the repository; CI generates it when absent.

## CI
GitHub Actions runs:
1. Flutter setup
2. Android platform generation when needed
3. `flutter pub get`
4. `flutter analyze`
5. `flutter test`
6. `flutter build apk --release`
7. APK artifact upload
