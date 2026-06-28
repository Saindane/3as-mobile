# 3As Complex — Flutter Mobile App

Cross-platform Flutter app (Android + iOS) for the 3As Complex Maintenance Management System.

## Tech Stack
- **Framework**: Flutter 3.x (Dart)
- **State management**: Riverpod 2.x
- **Navigation**: GoRouter
- **Networking**: Dio + interceptors
- **Storage**: Flutter Secure Storage (tokens) + SharedPreferences
- **Push**: Firebase Cloud Messaging
- **Architecture**: Feature-first, Clean Architecture

## Project Structure
```
lib/
├── core/
│   ├── constants/      # API URLs, app constants
│   ├── network/        # Dio client, interceptors, error handling
│   ├── router/         # GoRouter configuration
│   ├── theme/          # App theme, colours, text styles
│   └── utils/          # Validators, formatters, helpers
├── features/
│   ├── auth/           # Feature 1 ✅
│   │   ├── data/       # Models, repositories impl, remote datasource
│   │   ├── domain/     # Entities, repo interfaces, use cases
│   │   └── presentation/ # Riverpod providers, screens, widgets
│   ├── dashboard/      # Feature 2 (next)
│   ├── bills/          # Feature 3
│   ├── payments/       # Feature 4
│   ├── complaints/     # Feature 5
│   ├── notices/        # Feature 6
│   └── reports/        # Feature 7
└── shared/
    ├── widgets/        # Common UI components
    └── extensions/     # Dart extensions
```

## Feature Implementation Status
- [x] **Feature 1**: Authentication (login, OTP, password reset, token refresh)
- [ ] Feature 2: Dashboard + User Profile
- [ ] Feature 3: Bills
- [ ] Feature 4: Payments + QR
- [ ] Feature 5: Complaints
- [ ] Feature 6: Notices
- [ ] Feature 7: MIS Reports

## Quick Start
```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run tests
flutter test

# Build APK
flutter build apk --release
```

## Environment
Set your API base URL in `lib/core/constants/app_constants.dart`
