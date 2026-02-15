# AIMathTest

AI-powered math test generator for kids K-12. Available as a web app and Android app.

**Live:** https://aimathtest-kids-3ca24.web.app

## Features

- **AI-Generated Tests** — Gemini 2.0 Flash creates personalized, grade-appropriate math problems
- **10 Math Topics** — Addition, Subtraction, Multiplication, Division, Fractions, Decimals, Percentages, Geometry, Algebra, Word Problems
- **Child Profiles** — Multiple children per parent account, each with their own avatar and progress
- **Progress Tracking** — Per-topic performance bars, test history, streak counter
- **Onboarding Flow** — Guided first-time setup: create profile, configure test, take first test
- **Test Sharing** — Share tests via link (`/shared/MATH-XXXXX`), login required to take
- **Kid-Friendly UI** — Large touch targets, number pad input, encouraging score messages

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) — single codebase for Android + Web |
| State Management | Riverpod |
| Routing | GoRouter |
| Backend | Firebase (Auth, Firestore, Cloud Functions, Hosting) |
| AI | Google Gemini 2.0 Flash (via Cloud Functions) |
| Auth | Google Sign-In |
| CI/CD | GitHub Actions |

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp setup
├── config/                      # Theme, routes, constants, app config
├── models/                      # User, Profile, Test, Question, Attempt
├── services/                    # Auth, Database, AI, Analytics (local + Firebase)
├── providers/                   # Riverpod state management
├── screens/                     # 11 screens (landing, onboarding, home, test, results, etc.)
└── widgets/                     # Reusable UI (number pad, avatar picker, topic chips, etc.)

functions/                       # Firebase Cloud Functions (TypeScript)
├── src/generateTest.ts          # Gemini AI test generation
└── src/cleanupExpiredTests.ts   # Daily expired test cleanup
```

## Getting Started

### Prerequisites

- Flutter SDK 3.16+
- Node.js 22+ (for Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)

### Local Development

```bash
# Install dependencies
flutter pub get

# Run on web (local mode — no Firebase needed)
# Set useFirebase = false in lib/config/app_config.dart
flutter run -d chrome

# Run on web-server mode
flutter run -d web-server --web-port=8080
```

### Firebase Setup

```bash
# Login to Firebase
firebase login

# Configure FlutterFire (generates firebase_options.dart)
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,web

# Set Gemini API key (get from https://aistudio.google.com/apikey)
firebase functions:secrets:set GEMINI_API_KEY

# Deploy everything
firebase deploy
```

### Firebase Console Setup

1. **Authentication** — Enable Google Sign-In provider
2. **Firestore** — Create database (rules deploy automatically)
3. **People API** — Enable at Google Cloud Console (required for Google Sign-In on web)
4. **OAuth Client** — Add authorized origins/redirects for your domains

## Local Demo Mode

Set `useFirebase = false` in `lib/config/app_config.dart` to run without any backend:

- Mock Google Sign-In (instant, no real auth)
- In-memory database (data resets on refresh)
- Local math problem generator (no AI, but grade-appropriate)

## CI/CD

GitHub Actions workflow (`.github/workflows/deploy.yml`) runs on every push to `master`:

1. Install Flutter + dependencies
2. Run `flutter analyze`
3. Build web release
4. Deploy to Firebase Hosting
5. Build and deploy Cloud Functions

**Required GitHub secret:** `FIREBASE_SERVICE_ACCOUNT` — Firebase service account JSON key.

## Architecture

```
Client (Flutter Web/Android)
    │
    ├── Google Sign-In → Firebase Auth
    ├── Read/Write → Firestore (profiles, tests, attempts)
    └── Generate Test → Cloud Function → Gemini 2.0 Flash
```

See [.claude/ARCHITECTURE.md](.claude/ARCHITECTURE.md) for full technical architecture,
[.claude/FEATURES.md](.claude/FEATURES.md) for feature specs, and
[.claude/SCREENS.md](.claude/SCREENS.md) for screen wireframes.

## Cost

At 10-100 users, everything runs within free tiers:

| Service | Monthly Cost |
|---------|-------------|
| Firebase Auth, Firestore, Hosting | $0 |
| Cloud Functions | $0 |
| Gemini 2.0 Flash | ~$0-3 |

## License

MIT
