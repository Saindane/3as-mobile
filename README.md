# 3As Complex — Flutter Mobile & Web App

Cross-platform Flutter app (Android + iOS + Web) for the 3As Complex Maintenance Management System.

## Tech Stack
- **Framework**: Flutter 3.x (Dart)
- **State management**: Riverpod 2.x (StateNotifier + FutureProvider)
- **Navigation**: GoRouter (path-based, auth redirect guard)
- **Networking**: Dio + JWT auth interceptor + auto token refresh on 401
- **Storage**: Flutter Secure Storage (tokens) + SharedPreferences
- **Push**: Firebase Cloud Messaging (FCM)
- **Architecture**: Feature-first, Clean Architecture (data / domain / presentation)

## Project Structure
```
lib/
├── core/
│   ├── constants/      # API URLs, storage keys
│   ├── network/        # Dio client, interceptors, error handling
│   ├── router/         # GoRouter with auth guard
│   ├── theme/          # AppTheme, AppColors, AppTextStyles
│   ├── layout/         # AppShell, responsive breakpoints, grid helpers
│   └── utils/          # Validators, formatters
├── features/
│   ├── auth/           # ✅ Feature 1
│   ├── dashboard/      # ✅ Feature 2
│   ├── bills/          # ✅ Feature 3
│   ├── payments/       # ⏳ Feature 4
│   ├── complaints/     # ⏳ Feature 5
│   ├── notices/        # ⏳ Feature 6
│   └── reports/        # ⏳ Feature 7
└── shared/
    └── widgets/        # StatCard, AppCard, AppBadge, EmptyState, SectionHeader
```

## Quick Start

```bash
# 1. Clone
git clone https://github.com/Saindane/3as-mobile.git
cd 3as-mobile

# 2. Install dependencies
flutter pub get

# 3. Set backend URL — open lib/core/constants/app_constants.dart
#    For web/Chrome:         http://localhost:8000/api/v1
#    For Android emulator:   http://10.0.2.2:8000/api/v1

# 4. Run on web
flutter run -d chrome

# 5. Run tests
flutter test
```

## Running on Web
```bash
flutter run -d chrome
# Production build:
flutter build web --release
```

## Responsive Layout (AppShell)
| Screen width | Layout |
|---|---|
| < 900px (mobile) | AppBar + BottomNavigationBar |
| ≥ 900px (desktop/web) | 240px persistent sidebar + topbar |

Role switcher visible in desktop topbar for demo/testing.

## Feature Implementation Status
- [x] **Feature 1** — Authentication: LoginScreen, OtpScreen, NewPasswordScreen, JWT storage, auto-refresh on 401, GoRouter auth guard
- [x] **Feature 2** — Dashboard + Users + Properties: ResidentDashboardScreen, AdminDashboardScreen, users list, properties list, ProfileScreen
- [x] **Feature 3** — Web + Responsive layout: AppShell (sidebar/bottom nav), responsive breakpoints, PWA manifest, desktop role switcher
- [x] **Feature 4** — Bills screens: BillsScreen (tabbed), BillCard, BillDetailScreen, GenerateBillsScreen, collection summary, penalty formula display
- [ ] **Feature 5** — Payments: QR display, UTR + screenshot upload, submission flow, management verification screen
- [ ] **Feature 6** — Complaints: raise form, lifecycle tracker, assignment, resolution
- [ ] **Feature 7** — Notices: notice feed, publish form, FCM push indicator
- [ ] **Feature 8** — MIS Reports: collection chart, defaulter list, complaint analytics

## Demo Accounts
| Name | Mobile | Password | Role |
|---|---|---|---|
| Rajesh Kumar | 9876543210 | demo1234 | Resident |
| Priya Menon  | 8765432109 | demo1234 | Management |
| Suresh Admin | 7654321098 | demo1234 | Admin |

Tap any demo card on the login screen — no typing needed.

## Web Deployment
```bash
flutter build web --release
# Output: build/web/ → deploy to Firebase Hosting, Netlify, or Nginx
```

## Backend repo
https://github.com/Saindane/3as-backend
