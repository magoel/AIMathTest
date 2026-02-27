# AIMathTest — Project Instructions

## Project Overview
AIMathTest is an AI-powered math test generator for kids (K-12). It supports web and Android platforms with Google authentication.

## Key Documents
- `.claude/FEATURES.md` — Complete feature specification
- `.claude/SCREENS.md` — Screen/page specifications with wireframes
- `.claude/ARCHITECTURE.md` — Technical architecture

## Tech Stack
- **Frontend**: Flutter (Dart) — single codebase for Android + Web
- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore, Cloud Functions, Hosting)
- **AI**: Google Gemini 2.0 Flash (Paid Tier 1, 2000 RPM)
- **Math Rendering**: flutter_math_fork (LaTeX)
- **Payments**: Google Play Billing (in_app_purchase)
- **Analytics**: Firebase Analytics + Crashlytics (free)

## Development Guidelines
- Keep hosting costs low (target: 10-100 users initially)
- Mobile-first responsive design
- Kid-friendly UI with large touch targets
- No local fallback for AI — Cloud Function only, show errors clearly

## AI Integration
- Use AI for real-time test generation with retry logic (4 attempts, 5s/15s/30s backoff)
- Board-aware prompts (CBSE/IB/Cambridge) for curriculum-appropriate questions
- MCQ (~40%) + fill-in-blank (~60%) question mix
- LaTeX notation mandatory for all math expressions
- Exponential difficulty scaling (each level twice as hard, 1-10)
- Sub-topic diversity enforced per topic
- Personalize based on child's performance history

## Curriculum Support
- Boards: CBSE, IB, Cambridge — defined in `lib/config/board_curriculum.dart`
- 17 topics, filtered by board+grade window (grade-2 to grade+1, min 4 topics)
- Curriculum mapping based on official syllabi research

## Subscription
- Free: 10 tests/month (retakes don't count)
- Premium: ₹50/month or ₹500/year (save 17%)
- Pricing displayed transparently on settings screen

## Important Patterns
- Tests expire after 3 months (cleanup Cloud Function)
- Shared tests use public links with unique IDs
- Re-takes shuffle question order but keep same questions
- LaTeX escape: double-escape ALL \letter before JSON.parse()
- Feedback button on every screen (Firestore `feedback` collection)
