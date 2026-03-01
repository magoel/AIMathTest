# Web Subscriptions via Razorpay — Design

**Date:** 2026-03-02
**Goal:** Add web subscription support using Razorpay alongside existing Android Google Play Billing.

## Context

The app already has a fully functional Android subscription system (Google Play Billing + `verifyPurchase` Cloud Function). Web users currently cannot subscribe. This design adds Razorpay as the web payment provider, converging both platforms on the same Firestore subscription model.

## Architecture

Dual payment system:
- **Android** → Google Play Billing (existing, no changes)
- **Web** → Razorpay Subscriptions API (new)

Both paths update the same Firestore `subscription` fields on the user document. The `isPremiumProvider` reads from Firestore and works regardless of purchase platform.

## Flow

```
Web User clicks "Upgrade"
  → Frontend opens Razorpay Checkout with subscription plan ID
  → Razorpay handles payment (UPI / card / netbanking)
  → Razorpay sends webhook to verifyRazorpay Cloud Function
  → Cloud Function verifies webhook signature
  → Cloud Function updates Firestore subscription fields
  → isPremiumProvider picks up the change → UI updates
```

## Components

### New Files
1. **`functions/src/verifyRazorpay.ts`** — Cloud Function webhook handler
   - Receives Razorpay webhook events (payment.authorized, subscription.cancelled, etc.)
   - Verifies webhook signature using Razorpay secret
   - Updates Firestore user document with subscription status
   - Maps Razorpay states → app states (active, cancelled, expired)

2. **`lib/services/razorpay_web_service.dart`** — Web-only subscription service
   - Opens Razorpay Checkout.js via JS interop
   - Passes subscription plan ID, user info, prefill data
   - Handles success/failure callbacks

3. **`web/index.html`** — Add Razorpay Checkout.js script tag

### Modified Files
4. **`lib/providers/subscription_provider.dart`** — Platform-aware provider
   - Web: use Razorpay service
   - Android: use existing Google Play service (unchanged)
   - `billingAvailableProvider` returns `true` on web (currently returns `false`)

5. **`lib/widgets/upgrade_dialog.dart`** — Platform-aware upgrade flow
   - Web: trigger Razorpay checkout
   - Android: existing Google Play flow (unchanged)

6. **`lib/screens/settings/settings_screen.dart`** — Manage subscription link
   - Web: link to Razorpay customer portal or show cancel instructions
   - Android: existing Play Store link (unchanged)

7. **`lib/config/constants.dart`** — Add Razorpay plan IDs
   - `razorpayMonthlyPlanId` = `'plan_premium_monthly'`
   - `razorpayAnnualPlanId` = `'plan_premium_annual'`

### Unchanged
- Firestore user model (`subscription.plan`, `subscription.status`, `isPremium`)
- `isPremiumProvider` core logic (reads from Firestore)
- Free tier quota enforcement
- Admin bypass
- Android billing flow
- `verifyPurchase` Cloud Function (Android-only)

## Razorpay Setup (Manual)
1. Create Razorpay account at https://razorpay.com
2. Get API Key ID + Key Secret from Dashboard → Settings → API Keys
3. Create two subscription Plans:
   - `plan_premium_monthly`: ₹50/month, monthly billing
   - `plan_premium_annual`: ₹500/year, yearly billing
4. Set up webhook endpoint: `https://us-central1-aimathtest-kids-3ca24.cloudfunctions.net/verifyRazorpay`
5. Subscribe to events: `payment.authorized`, `subscription.activated`, `subscription.cancelled`, `subscription.completed`, `subscription.expired`
6. Store API keys as Firebase Secrets: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`

## Pricing
- Monthly: ₹50/month (same as Android)
- Annual: ₹500/year (same as Android, save 17%)

## Security
- Webhook signature verification using HMAC SHA256
- API keys stored as Firebase Secrets (never in client code)
- Razorpay Key ID (public) can be in client code — Key Secret stays server-side only
- Server-side Firestore updates only (client cannot write subscription fields)

## Error Handling
- Razorpay checkout failure → show friendly error message
- Webhook delivery failure → Razorpay auto-retries for 24 hours
- Signature verification failure → reject webhook, log for investigation
- Subscription expired → Firestore status updated, `isPremiumProvider` returns false
