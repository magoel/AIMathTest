# AIMathTest — Project Instructions

## Project Overview
AIMathTest is an AI-powered math test generator for kids (K-12). It supports web and Android platforms with Google authentication.

## Key Documents
- `.claude/FEATURES.md` — Complete feature specification
- `.claude/SCREENS.md` — Screen/page specifications with wireframes
- `.claude/ARCHITECTURE.md` — Technical architecture (to be created)

## Tech Stack
- **Frontend**: Flutter (Dart) — single codebase for Android + Web
- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore, Cloud Functions, Hosting)
- **AI**: Google Gemini 2.0 Flash
- **Analytics**: Firebase Analytics + Crashlytics (free)

## Development Guidelines
- Keep hosting costs low (target: 10-100 users initially)
- Mobile-first responsive design
- Kid-friendly UI with large touch targets
- Parent dashboard for progress monitoring

## AI Integration
- Use AI for real-time test generation
- Board-aware prompts (CBSE/IB/Cambridge) for curriculum-appropriate questions
- Personalize based on child's performance history
- Optimize prompts to minimize token usage

## Curriculum Support
- Boards: CBSE, IB, Cambridge — defined in `lib/config/board_curriculum.dart`
- 17 topics, filtered by board+grade (see `getAvailableTopics()`)
- Curriculum mapping based on official syllabi research

## Important Patterns
- Tests expire after 3 months (implement cleanup job)
- Shared tests use public links with unique IDs
- Re-takes shuffle question order but keep same questions

## Commands
(To be added as project develops)
