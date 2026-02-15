# AIMathTest — Feature Specification

## Overview
AI-powered math test generator for kids (K-12), available as web app and Android app with Google authentication.

## User Model

```
Parent (Google Login)
    └── Child Profile 1 (Avatar, Name, Grade)
    └── Child Profile 2 (Avatar, Name, Grade)
    └── Child Profile 3 ...
```

- **Parent Account**: Google Sign-In, manages all child profiles
- **Child Profiles**: Name, avatar, grade (K-12) — no separate login required
- **Profile Switcher**: "Who's practicing today?" screen on app launch
- **Multi-Child Support**: Unlimited child profiles per parent

---

## Core Features

### 1. Authentication
- Google OAuth 2.0 (parent only)
- Session management
- Secure token storage

### 2. Child Profiles
- Create/edit/delete profiles
- Fields: Name, Avatar, Grade (K-12)
- Per-profile progress tracking

### 3. Test Configuration
- **Topics** (multi-select): Addition, Subtraction, Multiplication, Division, Fractions, Decimals, Percentages, Geometry, Algebra, Word Problems
- **Difficulty**: 1-10 slider
- **Length**: 5 / 10 / 15 / 20 questions
- **Mode**: Timed or Untimed

### 4. AI-Powered Test Generation
- Real-time generation via AI (e.g., GPT-4 / Gemini)
- Personalized based on child's past performance
- Targets weak areas (~30% reinforcement problems)
- Avoids recently seen problem patterns

### 5. Test Persistence & Sharing
- Every test saved with unique ID (e.g., `MATH-7X9K2`)
- **Shareable link**: `app.aimathtest.com/test/MATH-7X9K2`
- Login required to access shared test → then select child profile to take test
- **Test expiry**: Auto-delete after 3 months

### 6. Re-take Tests
- Child can re-attempt any past test
- Same questions, shuffled order
- Compare previous vs new score

### 7. Test Taking Experience
- Clean, kid-friendly UI
- Timer display (if timed mode)
- Submit and instant grading

### 8. Results & Progress
- Score + correct/incorrect breakdown
- View correct answers after submission
- Historical progress charts per topic per child
- Weak area identification

### 9. Parent Dashboard
- View all children's progress
- Test history with scores
- Identify struggling topics per child
- (Future) Export reports

---

## Subscription Model (Future)

| Tier | Features |
|------|----------|
| **Free** | 5 tests/day, basic progress tracking |
| **Premium** | Unlimited tests, detailed analytics, no ads, export reports |

---

## Technical Constraints
- Target users: 10-100 initially
- Low hosting cost priority
- Platforms: Web + Android
- Language: English only

---

## Decisions Log

| Decision | Choice |
|----------|--------|
| Shared test access | Login required to access shared tests |
| Re-take behavior | Same questions, shuffled order |
| Test expiry | 3 months |
| User model | Parent login only, child profiles underneath |
