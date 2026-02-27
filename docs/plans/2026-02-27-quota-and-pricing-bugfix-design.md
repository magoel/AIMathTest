# Design: Quota Counting & Pricing Alignment Bugfixes

> Date: 2026-02-27
> Status: Approved

## Problem

### Bug A: Free tier quota doesn't count unsubmitted tests
`getMonthTestCount()` queries the `attempts` collection, meaning only submitted tests count toward the 10/month free tier limit. Users can generate unlimited tests (each costing a Gemini API call) without submitting, bypassing the quota.

### Bug B: Pricing text misaligned on Settings screen
The subscription card's pricing bullets (`Monthly: Rs 50/month`, `Annual: Rs 500/year`) are not left-aligned with the `Free Plan` title. Manual spaces before bullet characters and separate `Padding` blocks cause visual inconsistency.

## Solution

### Bug A: Count test generations, not completions

**Change `getMonthTestCount()` to query the `tests` collection** instead of `attempts`.

- Query: `tests` where `createdBy.parentId == parentId` AND `createdAt >= startOfMonth`
- No per-profile filter — billing is per parent account (one generation = one Gemini API cost)
- Settings screen displays: "X of 10 generations remaining this month"
- Same query enforces the limit in `test_config_screen.dart`

**Files:**
- `lib/services/database_service.dart` — rewrite `getMonthTestCount()` to query `tests`
- `lib/services/local_database_service.dart` — update local version to match
- `lib/providers/user_provider.dart` — update method signature (drop `profileId`)
- `lib/screens/test_config/test_config_screen.dart` — pass `parentId` only
- `lib/screens/settings/settings_screen.dart` — update display text

### Bug B: Restructure free plan card with ListTile

Replace the manual `Padding` + `Column` layout with a `ListTile`-based card, matching the premium plan card's structure. This ensures consistent alignment with no manual spacing hacks.

**Files:**
- `lib/screens/settings/settings_screen.dart` — rebuild free tier section of `_SubscriptionCard`
