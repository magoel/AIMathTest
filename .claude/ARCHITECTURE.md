# AIMathTest — Technical Architecture

## Overview

AI-powered math test generator for kids (K-12) with native Android app and web app from a single codebase.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTS                               │
│  ┌─────────────────┐          ┌─────────────────┐           │
│  │  Android App    │          │    Web App      │           │
│  │  (Flutter)      │          │   (Flutter Web) │           │
│  └────────┬────────┘          └────────┬────────┘           │
│           │         Same Codebase       │                    │
│           └──────────────┬──────────────┘                    │
└──────────────────────────┼──────────────────────────────────┘
                           │ HTTPS
┌──────────────────────────┼──────────────────────────────────┐
│                     FIREBASE                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │    Auth     │  │  Firestore  │  │  Functions  │          │
│  │  (Google)   │  │  (Database) │  │   (AI API)  │          │
│  └─────────────┘  └─────────────┘  └──────┬──────┘          │
│                                           │                  │
│  ┌─────────────┐  ┌─────────────┐  ┌──────┴──────┐          │
│  │  Hosting    │  │  Analytics  │  │ Crashlytics │          │
│  │   (Web)     │  │   (Free)    │  │   (Free)    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└──────────────────────────┬──────────────────────────────────┘
                           │ API Call
┌──────────────────────────┼──────────────────────────────────┐
│                     AI PROVIDER                              │
│            ┌─────────────┴─────────────┐                    │
│            │  Google Gemini 1.5 Flash  │                    │
│            │    (Test Generation)      │                    │
│            └───────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Frontend** | Flutter (Dart) | Single codebase for Android + Web |
| **State Management** | Riverpod | Modern, testable, recommended for Flutter |
| **Backend** | Firebase | All-in-one: Auth, DB, Functions, Hosting |
| **Database** | Firestore (NoSQL) | Real-time sync, offline support, free tier |
| **Auth** | Firebase Auth | Google Sign-In built-in |
| **AI** | Google Gemini 2.0 Flash | Cheapest, Firebase-friendly |
| **Payments** | Google Play Billing (in_app_purchase) | Android subscriptions |
| **Hosting (Web)** | Firebase Hosting | CDN, SSL, included |
| **Analytics** | Firebase Analytics | Free, integrated |
| **Crash Reporting** | Firebase Crashlytics | Free, integrated |
| **Android Distribution** | Google Play Store | Standard distribution |

---

## Database Schema (Firestore)

### Collection: `users`
Parent account information.

```
users/{parentId}
├── email: string
├── displayName: string
├── photoUrl: string (from Google)
├── createdAt: timestamp
├── lastLoginAt: timestamp
├── onboardingCompleted: boolean
├── lastActiveProfileId: string (remembers last child)
└── subscription: {
      plan: "free" | "premium_monthly" | "premium_annual",
      status: "none" | "active" | "expired" | "cancelled" | "grace_period",
      purchaseToken: string,
      productId: string,
      expiresAt: timestamp | null,
      lastVerifiedAt: timestamp | null
    }
```

### Collection: `profiles`
Child profiles (subcollection under users).

```
users/{parentId}/profiles/{profileId}
├── name: string
├── avatar: string (emoji or asset path)
├── grade: number (0=K, 1-12)
├── board: string ("cbse" | "ib" | "cambridge")
├── createdAt: timestamp
└── stats: {
      totalTests: number,
      averageScore: number,
      currentStreak: number,
      lastTestAt: timestamp
    }
```

### Collection: `tests`
Generated tests (top-level for sharing).

```
tests/{testId}
├── shareCode: string (e.g., "MATH-7X9K2")
├── createdBy: {
│     parentId: string,
│     profileId: string,
│     profileName: string
│   }
├── config: {
│     topics: array<string>,
│     difficulty: number (1-10),
│     questionCount: number,
│     timed: boolean,
│     timeLimitSeconds: number | null
│   }
├── questions: array<{
│     id: string,
│     type: "fill_in_blank",
│     question: string,
│     correctAnswer: string,
│     topic: string
│   }>
├── createdAt: timestamp
└── expiresAt: timestamp (+3 months)
```

### Collection: `attempts`
Test attempts (records each time a test is taken).

```
attempts/{attemptId}
├── testId: string
├── parentId: string
├── profileId: string
├── answers: array<{
│     questionId: string,
│     userAnswer: string,
│     isCorrect: boolean
│   }>
├── score: number
├── totalQuestions: number
├── percentage: number
├── timeTaken: number (seconds)
├── shuffleOrder: array<number> (question order for this attempt)
├── isRetake: boolean
├── previousAttemptId: string | null
└── completedAt: timestamp
```

### Indexes Required

```
# For test expiry cleanup
tests: expiresAt ASC

# For user's test history
attempts: (parentId, profileId, completedAt DESC)

# For shared test lookup
tests: shareCode ASC
```

---

## API Design (Cloud Functions)

### Function: `generateTest`
Generates a personalized test using AI.

```typescript
// Request
{
  profileId: string,
  grade: number,
  board: string,       // "cbse" | "ib" | "cambridge"
  topics: string[],
  difficulty: number,
  questionCount: number,
  timed: boolean
}

// Response
{
  testId: string,
  shareCode: string,
  questions: Question[]
}
```

**Logic:**
1. Fetch child's recent attempts (last 20)
2. Analyze weak topics and common mistakes
3. Build AI prompt with personalization
4. Call Gemini API
5. Parse and validate response
6. Save test to Firestore
7. Return test data

### Function: `verifyPurchase`
Validates Google Play subscription purchases server-side.

```typescript
// Request
{
  purchaseToken: string,
  productId: string,      // "premium_monthly" | "premium_annual"
  source: string           // "google_play"
}

// Response
{
  status: string,          // "active" | "expired" | "cancelled" | "grace_period"
  plan: string,
  expiresAt: number
}
```

**Logic:**
1. Validate auth
2. Call Google Play Developer API (subscriptionsv2) via REST
3. Determine subscription status from response
4. Write subscription data to Firestore `users/{userId}/subscription`

### Function: `cleanupExpiredTests`
Scheduled function to delete old tests.

```typescript
// Runs daily via Cloud Scheduler
// Deletes tests where expiresAt < now
```

---

## AI Prompt Strategy

### Test Generation Prompt Template

```
You are a math test generator for a {grade} grade student following the {board} curriculum.

Generate {questionCount} math problems with these requirements:
- Topics: {topics}
- Difficulty level: {difficulty}/10
- Format: Fill-in-the-blank with numeric answers

Student's recent performance:
- Weak areas: {weakTopics}
- Strong areas: {strongTopics}
- Recent mistakes: {recentMistakes}

Include:
- 30% problems targeting weak areas
- 50% problems at requested difficulty
- 20% slightly challenging problems

Avoid these recently seen problem patterns:
{recentPatterns}

Return JSON array:
[
  {
    "question": "24 × 15 = ?",
    "answer": "360",
    "topic": "multiplication"
  }
]
```

### Token Optimization
- Estimated tokens per test: ~500-800
- Use structured JSON output to minimize parsing errors
- Cache common problem types for instant fallback

---

## Project Structure

```
aimathtest/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # MaterialApp setup
│   │
│   ├── config/
│   │   ├── routes.dart           # Route definitions
│   │   ├── theme.dart            # App theme (colors, fonts)
│   │   ├── constants.dart        # App constants & topic definitions
│   │   ├── board_curriculum.dart  # Board enum & grade→topics mapping
│   │   └── app_config.dart       # Firebase vs local mode toggle
│   │
│   ├── models/
│   │   ├── user_model.dart       # Parent user
│   │   ├── profile_model.dart    # Child profile
│   │   ├── test_model.dart       # Test with questions
│   │   ├── attempt_model.dart    # Test attempt
│   │   └── question_model.dart   # Individual question
│   │
│   ├── services/
│   │   ├── auth_service.dart     # Firebase Auth wrapper
│   │   ├── database_service.dart # Firestore operations
│   │   ├── ai_service.dart       # Cloud Function calls + local fallback
│   │   ├── subscription_service.dart # Google Play Billing wrapper
│   │   └── analytics_service.dart# Event tracking
│   │
│   ├── providers/
│   │   ├── auth_provider.dart    # Auth state
│   │   ├── user_provider.dart    # Current user data + DB wrappers
│   │   ├── profile_provider.dart # Profiles & active profile
│   │   ├── test_provider.dart    # Test state
│   │   └── subscription_provider.dart # Billing state & isPremium
│   │
│   ├── screens/
│   │   ├── landing/
│   │   │   └── landing_screen.dart
│   │   ├── onboarding/
│   │   │   ├── onboarding_profile_screen.dart
│   │   │   ├── onboarding_config_screen.dart
│   │   │   └── onboarding_complete_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── test_config/
│   │   │   └── test_config_screen.dart
│   │   ├── test_taking/
│   │   │   └── test_taking_screen.dart
│   │   ├── results/
│   │   │   └── results_screen.dart
│   │   ├── progress/
│   │   │   └── progress_screen.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       └── profile_selector_screen.dart
│   │
│   └── widgets/
│       ├── common/
│       │   ├── app_button.dart
│       │   ├── app_card.dart
│       │   └── loading_overlay.dart
│       ├── avatar_picker.dart
│       ├── topic_chip.dart
│       ├── difficulty_slider.dart
│       ├── number_pad.dart
│       ├── question_card.dart
│       ├── progress_bar.dart
│       ├── score_display.dart
│       └── profile_avatar.dart
│
├── functions/                    # Firebase Cloud Functions
│   ├── src/
│   │   ├── index.ts
│   │   ├── generateTest.ts
│   │   ├── verifyPurchase.ts
│   │   └── cleanupExpiredTests.ts
│   ├── package.json
│   └── tsconfig.json
│
├── android/                      # Android-specific config
├── web/                          # Web-specific config
├── test/                         # Unit & widget tests
│
├── pubspec.yaml                  # Flutter dependencies
├── firebase.json                 # Firebase config
├── firestore.rules              # Security rules
├── firestore.indexes.json       # Firestore indexes
└── .firebaserc                  # Firebase project config
```

---

## Analytics Events

### User Journey

| Event | When | Properties |
|-------|------|------------|
| `sign_up` | First login | — |
| `login` | Each login | — |
| `profile_created` | New child profile | `grade` |
| `onboarding_completed` | Finish onboarding | `time_spent` |

### Test Events

| Event | When | Properties |
|-------|------|------------|
| `test_started` | Start test | `topics`, `difficulty`, `question_count`, `timed` |
| `test_completed` | Submit test | `score`, `time_taken`, `topics` |
| `test_abandoned` | Leave without finishing | `questions_answered`, `topics` |
| `test_shared` | Share test link | `test_id` |
| `shared_test_opened` | Open shared link | `test_id`, `is_owner` |
| `test_retaken` | Re-take test | `test_id`, `previous_score` |

### Engagement

| Event | When | Properties |
|-------|------|------------|
| `profile_switched` | Change child profile | — |
| `progress_viewed` | Open Progress tab | `profile_id` |

---

## Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Profiles subcollection
      match /profiles/{profileId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Tests - creator has full access, others can read (for sharing)
    match /tests/{testId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null 
        && request.auth.uid == resource.data.createdBy.parentId;
    }
    
    // Attempts - users can only access their own
    match /attempts/{attemptId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.parentId;
      allow create: if request.auth != null;
    }
  }
}
```

---

## Cost Estimate

| Service | Free Tier | Expected Usage (10-100 users) | Monthly Cost |
|---------|-----------|-------------------------------|--------------|
| Firebase Auth | 50K MAU | ~100 | **$0** |
| Firestore | 1GB storage, 50K reads/day | Well under | **$0** |
| Cloud Functions | 2M invocations/month | ~5K | **$0** |
| Firebase Hosting | 10GB transfer/month | ~1GB | **$0** |
| Firebase Analytics | Unlimited | — | **$0** |
| Firebase Crashlytics | Unlimited | — | **$0** |
| Gemini API | Free tier + pay-as-go | ~$2-5 | **~$3** |
| **Total Monthly** | | | **~$0-5** |

**One-time costs:**
- Google Play Store: $25

---

## Development Phases

### Phase 1: MVP (4-6 weeks)
- [ ] Project setup (Flutter + Firebase)
- [ ] Auth flow (Google Sign-In)
- [ ] Onboarding flow
- [ ] Profile management (CRUD)
- [ ] Test configuration screen
- [ ] AI test generation (Cloud Function)
- [ ] Test taking screen
- [ ] Results screen
- [ ] Basic progress (test history)

### Phase 2: Polish (2-3 weeks)
- [ ] Progress charts and analytics
- [ ] Test sharing flow
- [ ] Re-take functionality
- [ ] Streak tracking
- [ ] Kid-friendly animations
- [ ] Offline support (Firestore)

### Phase 3: Launch (1-2 weeks)
- [ ] Play Store submission
- [ ] Web deployment
- [ ] Privacy policy
- [ ] Analytics dashboard review

### Phase 4: Growth (Post-launch)
- [ ] Subscription system
- [ ] More question types
- [ ] Additional topics
- [ ] Performance optimizations

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  cloud_functions: ^4.6.0
  firebase_analytics: ^10.7.0
  firebase_crashlytics: ^3.4.0
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  fl_chart: ^0.66.0        # Progress charts
  
  # Auth
  google_sign_in: ^6.2.1
  
  # Utils
  uuid: ^4.2.2
  intl: ^0.19.0
  share_plus: ^7.2.1       # Share test links
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  mockito: ^5.4.4
```

---

## Environment Setup

### Prerequisites
- Flutter SDK 3.16+
- Dart 3.2+
- Firebase CLI
- Android Studio / VS Code
- Google Cloud account (for Gemini API)

### Firebase Setup
1. Create Firebase project
2. Enable Authentication (Google provider)
3. Create Firestore database
4. Deploy Cloud Functions
5. Configure Firebase Hosting

### Local Development
```bash
# Clone and setup
flutter pub get
flutterfire configure

# Run on Android
flutter run

# Run on Web
flutter run -d chrome

# Run tests
flutter test
```
