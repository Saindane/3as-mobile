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
│   ├── auth/           # ✅ Feature 1 — Authentication
│   ├── dashboard/      # ✅ Feature 2 — Dashboard + Users + Properties
│   ├── bills/          # ✅ Feature 3 — Bills + Penalty Engine
│   ├── payments/       # ✅ Feature 4 — Payments + QR
│   ├── complaints/     # ✅ Feature 5 — Complaints
│   ├── notices/        # ✅ Feature 6 — Notices
│   ├── reports/        # ✅ Feature 7 — MIS Reports
│   └── settings/       # ✅ Feature 8 — Settings
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

## Responsive Layout (AppShell)
| Screen width | Layout |
|---|---|
| < 900px (mobile) | AppBar + BottomNavigationBar (5 tabs) |
| ≥ 900px (desktop/web) | 240px persistent sidebar + topbar with role switcher |

## Feature Implementation Status

- [x] **Feature 1 — Authentication**
  - LoginScreen with demo account quick-login cards
  - OtpScreen with 4-box Pinput, 30s resend timer
  - NewPasswordScreen after OTP verify
  - JWT access + refresh token stored in Flutter Secure Storage
  - Auto token refresh on 401 via Dio interceptor
  - GoRouter auth redirect guard

- [x] **Feature 2 — Dashboard + Users + Properties**
  - ResidentDashboardScreen: welcome banner, stat cards, bill alert with penalty formula, quick actions, activity timeline
  - AdminDashboardScreen: KPI grid, collection progress bar, pending action alerts, quick links, complaint breakdown
  - Users list with role + status badges (admin/mgmt)
  - Properties list with owner info (admin/mgmt)
  - ProfileScreen: user info, property details, sign out

- [x] **Feature 3 — Web + Responsive Layout**
  - AppShell: 240px persistent sidebar on desktop, bottom nav on mobile
  - Responsive breakpoints: mobile (<900px), desktop (≥900px)
  - PWA manifest — installable from Chrome
  - Role switcher in desktop topbar for demo/testing
  - ResponsiveGrid and ResponsiveTwoCol helpers

- [x] **Feature 4 — Bills + Penalty Engine**
  - BillsScreen: tabs (All / Overdue / Summary)
  - BillCard: status badge, maintenance + penalty breakdown, formula banner
  - BillDetailScreen: hero gradient card, penalty walkthrough, pay button
  - GenerateBillsScreen: month/year picker, due date, penalty toggle (admin)
  - Collection summary tab: progress bar, stat cards, live penalty previews

- [x] **Feature 5 — Payments + QR**
  - PayNowScreen: select bill → QR display + UPI ID → UTR entry → submit → success
  - PaymentsScreen: My payments list with status badges
  - VerifyPaymentsScreen: pending list with Verify / Reject buttons (mgmt)
  - Payment submission flow with 3-step status indicator

- [x] **Feature 6 — Complaints**
  - ComplaintsScreen: tabs (All / Open / Resolved) + raise button
  - ComplaintCard: priority colour, 4-step lifecycle tracker, admin action buttons
  - RaiseComplaintScreen: category chips, priority selector, title + description form
  - Admin actions: Assign → In Progress → Resolve

- [x] **Feature 7 — Notices**
  - NoticesScreen: notice feed with priority-coloured left border
  - Publish bottom sheet (mgmt/admin): title, body, category, priority
  - Admin delete notice
  - FCM push sent on publish (backend)

- [x] **Feature 8 — MIS Reports + Settings**
  - ReportsScreen: 3 tabs (Collection / Defaulters / Complaint Analytics)
  - Collection tab: month/year picker, progress bar, stat cards, per-unit bill list
  - Defaulters tab: outstanding totals, per-unit penalty breakdown
  - Complaint analytics: category breakdown with resolution progress bars
  - SettingsScreen (admin): penalty rate config, UPI ID, society info, FCM/SMS toggles
  - Live penalty formula preview in settings

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

## Backend Repo
https://github.com/Saindane/3as-backend
