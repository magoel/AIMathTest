# Package Rename Design

**Date:** 2026-03-01
**Change:** `com.aimathtest.aimathtest` → `com.numerixlabs.aimathtest`
**Additional:** Privacy contact email → `numerixlabs@gmail.com`

## Context

The app was initially created with package name `com.aimathtest.aimathtest`. Now that the domain `numerixlabs.com` is owned and the brand is established, the package should reflect the company identity. The app is still in internal testing on Play Store, so a new listing is acceptable.

## Code Changes (10 files)

### 1. `android/app/build.gradle.kts`
- Line 20: `namespace` → `com.numerixlabs.aimathtest`
- Line 35: `applicationId` → `com.numerixlabs.aimathtest`

### 2. `android/app/src/main/kotlin/` (directory + file)
- Move `com/aimathtest/aimathtest/MainActivity.kt` → `com/numerixlabs/aimathtest/MainActivity.kt`
- Update `package` declaration in `MainActivity.kt`
- Delete old empty directories

### 3. `web/.well-known/assetlinks.json`
- `package_name` → `com.numerixlabs.aimathtest`

### 4. `web/privacy.html`
- Line 83: Contact email → `numerixlabs@gmail.com`

### 5. `tool/play_upload.js`
- Line 18: `PACKAGE_NAME` → `com.numerixlabs.aimathtest`

### 6. `tool/play_update_listing.js`
- Line 16: `PACKAGE_NAME` → `com.numerixlabs.aimathtest`

### 7. `tool/diagnose_signin.js`
- Line 23: `PACKAGE_NAME` → `com.numerixlabs.aimathtest`

### 8. `tool/fix_play_signing.js`
- Line 150: `packageName` → `com.numerixlabs.aimathtest`

### 9. `functions/src/verifyPurchase.ts`
- Line 38: `packageName` → `com.numerixlabs.aimathtest`

## External Console Changes

### Firebase Console
1. Add new Android app: `com.numerixlabs.aimathtest`
2. Add 3 SHA-1 fingerprints:
   - Debug: `9D:E4:22:F3:B0:73:DD:90:F3:4B:FF:51:58:00:8F:6D:28:9B:70:72`
   - Upload: `1E:7E:99:62:7D:80:69:7B:4C:19:F0:D4:5F:1C:0D:E1:22:AE:05:1B`
   - Play Signing: TBD (from new Play Console app)
3. Download new `google-services.json` → replace `android/app/google-services.json`
4. Optionally remove old `com.aimathtest.aimathtest` Android app

### Google Cloud Console
1. New OAuth clients auto-created by Firebase for new package
2. Add Play Signing SHA-1 to new Android API key restrictions (via `fix_play_signing.js`)
3. Verify OAuth consent screen still in Production mode
4. Optionally clean up old OAuth clients for `com.aimathtest.aimathtest`

### Google AI Studio
- No changes needed (Gemini API key is project-level, not package-level)

### Google Play Console
1. Create new app with package `com.numerixlabs.aimathtest`
2. Reuse existing upload keystore (`upload-keystore.jks` is not tied to package name)
3. Upload AAB via `node tool/play_upload.js internal "Initial release"`
4. Upload store listing via `node tool/play_update_listing.js`
5. Note new Play App Signing SHA-1 from Setup → App signing
6. Run `node tool/fix_play_signing.js "NEW:SHA:HERE"` to register in Firebase + API key
7. Set privacy policy URL: `https://aimathtest.numerixlabs.com/privacy.html`
8. Complete content rating questionnaire
9. Unpublish/remove old `com.aimathtest.aimathtest` from internal testing

### GitHub Actions CI/CD
- No changes needed (references Firebase project ID, not Android package)
- `FIREBASE_SERVICE_ACCOUNT` secret unchanged
- `GITHUB_TOKEN` unchanged

## Unchanged
- Firebase project (`aimathtest-kids-3ca24`)
- Firestore data, Cloud Functions, Firebase Auth users
- Web app, custom domain (`aimathtest.numerixlabs.com`)
- Firebase Hosting configuration
- Gemini API key / AI Studio
- Admin emails in `constants.dart`
- CI/CD pipeline + GitHub secrets

## Execution Order
1. Code changes (all 10 files)
2. Firebase Console: add new Android app + SHA-1s + download google-services.json
3. Build + test locally
4. Play Console: create new app
5. Upload AAB + store listing
6. Add Play Signing SHA-1 via automation script
7. Verify sign-in works
8. Deploy web (privacy.html update) + Cloud Functions (verifyPurchase.ts)
9. Clean up old app entries (Firebase, Play Console, Cloud Console)
