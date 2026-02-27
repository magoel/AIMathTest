# AIMathTest — Project Status

> Last updated: 2026-02-27

## Quick Summary

| Area | Status |
|------|--------|
| **Phase 1: MVP** | Complete |
| **Phase 2: Polish** | Complete (except offline — by design) |
| **Phase 3: Launch** | Web deployed, Play Store blocked on identity verification |
| **Phase 4: Growth** | Subscription code done, Play Console setup pending |

**Live Web App:** https://aimathtest-kids-3ca24.web.app
**GitHub:** https://github.com/magoel/AIMathTest

---

## Features Done

### Core App
- [x] Google OAuth 2.0 authentication (web + Android)
- [x] Onboarding flow (3-step: profile → config → complete)
- [x] Child profile management (create, edit, delete, switch)
- [x] Board selection (CBSE, IB, Cambridge) with grade-based topic filtering
- [x] 17 math topics with curriculum-appropriate windowing (grade-2 to grade+1)
- [x] Profile avatars (emoji picker)

### Test Generation
- [x] AI-powered generation via Gemini 2.0 Flash (Cloud Function)
- [x] Board-aware prompts matching curriculum style
- [x] Personalization based on child's performance history
- [x] MCQ (~40%) + fill-in-blank (~60%) question mix
- [x] LaTeX math rendering (flutter_math_fork)
- [x] Exponential difficulty scaling (Level 1-10)
- [x] Sub-topic diversity enforcement
- [x] Retry with backoff (4 attempts: 5s/15s/30s) for rate limits
- [x] Friendly error messages ("AI service is busy")

### Test Experience
- [x] Test configuration screen (topics, difficulty, count, timed toggle)
- [x] Test taking screen with question navigation
- [x] Number pad + text input for fill-in-blank
- [x] A/B/C/D buttons for multiple choice
- [x] Timer display (MM:SS elapsed)
- [x] Submit with unanswered question warning
- [x] Leave confirmation dialog

### Results & Progress
- [x] Score display with animated counter + confetti (score >= 80%)
- [x] Correct/incorrect answer review with correct answers shown
- [x] Score trend chart (LineChart via fl_chart)
- [x] Performance by topic (bar visualization with icons)
- [x] Weakest topic recommendation with tap-to-practice
- [x] Test history list with color-coded scores
- [x] Overall stats (average, total tests, streak)

### Sharing & Retakes
- [x] Share code generation (MATH-XXXXX format)
- [x] Public share links (`/shared/:shareCode`)
- [x] Share button on results (via share_plus)
- [x] Re-take with shuffled question order
- [x] Attempt tracking (isRetake, previousAttemptId)

### Engagement
- [x] Streak tracking (day-based logic with display on home + progress)
- [x] Confetti animation on high scores
- [x] Animated score counter with progress circle
- [x] Feedback system (star rating + message on every screen)

### Subscription & Billing
- [x] Free tier enforcement (10 tests/month, retakes don't count)
- [x] in_app_purchase integration (Android)
- [x] Product IDs: `premium_monthly` (Rs 50/month), `premium_annual` (Rs 500/year)
- [x] `verifyPurchase` Cloud Function (Google Play Developer API)
- [x] Subscription status tracking (active/expired/cancelled/grace_period)
- [x] Transparent pricing display on settings screen
- [x] Upgrade dialog when free limit reached

### Infrastructure
- [x] Firebase: Auth, Firestore, Cloud Functions, Hosting, Analytics
- [x] Firestore security rules (owner-only access per collection)
- [x] `cleanupExpiredTests` scheduled Cloud Function (daily, 90-day expiry)
- [x] CI/CD via GitHub Actions (auto-deploy on push to master)
- [x] Privacy policy (COPPA-compliant, `web/privacy.html`)
- [x] Firebase Analytics (10+ event types)
- [x] Dual-mode config (Firebase prod vs local dev)
- [x] App icon (custom AI Math Bot on purple gradient)
- [x] Android release signing configured

---

## Features Not Done / Pending

### Play Store Launch (blocked externally)
- [ ] Google identity verification (in progress — waiting on Google)
- [ ] Upload app to internal testing track (blocked by verification)
- [ ] Create subscription products in Play Console (blocked by upload)
- [ ] End-to-end billing test on real device

### Known Improvements (not in original MVP spec)
- [ ] Timed test auto-submit (timer displays but doesn't enforce time limit)
- [ ] Auto-save test progress mid-test (progress lost on close)
- [ ] Dark mode
- [ ] Push notifications (streak reminders, new feature alerts)
- [ ] Localization / i18n (currently English only — spec says English only)

### Technical Debt
- [ ] API keys exposed in public repo (keys restricted in Cloud Console)
- [ ] Service worker aggressive caching (users may need to clear manually)
- [ ] No automated tests (unit/widget/integration)

---

## Architecture Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| AI fallback | No local fallback | Cloud Function only; show clear errors. Keeps app simple. |
| Offline support | Not implemented | By design — test generation requires internet. Error shown clearly. |
| Billing platform | Android only (Google Play) | Web billing adds complexity; start with Play Store. |
| State management | Riverpod | Modern, testable, recommended for Flutter |
| Math rendering | flutter_math_fork (LaTeX) | Best Flutter LaTeX library; supports fractions, roots, exponents |
| Subscription validation | Server-side (Cloud Function) | Prevents client-side tampering; industry standard |
| Test expiry | 90 days + scheduled cleanup | Keeps Firestore lean; daily batch delete at 02:00 UTC |
| URL strategy | Path-based (no hash) | Clean URLs for sharing; conditional import for web/stub |

---

## Deployment Checklist

### Web (Done)
- [x] Firebase Hosting configured
- [x] CI/CD auto-deploys on push to master
- [x] Google OAuth published to production
- [x] Privacy policy accessible at `/privacy.html`
- [x] People API enabled for Google Sign-In

### Android (In Progress)
- [x] Debug build working on emulator (API 34)
- [x] Release signing configured (upload-keystore.jks)
- [x] Debug + Release SHA-1 added to Firebase Console
- [ ] Google identity verification approved
- [ ] App uploaded to Play Console (internal track)
- [ ] Subscription products created in Play Console
- [ ] Closed testing → Open testing → Production rollout
