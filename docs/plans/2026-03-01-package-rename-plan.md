# Package Rename Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename Android package from `com.aimathtest.aimathtest` to `com.numerixlabs.aimathtest` and update privacy email to `numerixlabs@gmail.com`.

**Architecture:** Find-and-replace the package name across 9 code files, move the Kotlin source directory, then reconfigure Firebase/Play Console external services. Automation scripts handle most Firebase + Play Store steps.

**Tech Stack:** Flutter/Dart, Android Gradle (Kotlin DSL), Firebase Console, Google Cloud Console, Google Play Console, Node.js automation scripts.

---

### Task 1: Rename Android build configuration

**Files:**
- Modify: `android/app/build.gradle.kts:20,35`

**Step 1: Update namespace**

Change line 20 from:
```kotlin
namespace = "com.aimathtest.aimathtest"
```
to:
```kotlin
namespace = "com.numerixlabs.aimathtest"
```

**Step 2: Update applicationId**

Change line 35 from:
```kotlin
applicationId = "com.aimathtest.aimathtest"
```
to:
```kotlin
applicationId = "com.numerixlabs.aimathtest"
```

**Step 3: Verify no other references**

Run: `grep -r "com.aimathtest.aimathtest" android/app/build.gradle.kts`
Expected: No matches

---

### Task 2: Move Kotlin source directory and update package declaration

**Files:**
- Move: `android/app/src/main/kotlin/com/aimathtest/aimathtest/MainActivity.kt` → `android/app/src/main/kotlin/com/numerixlabs/aimathtest/MainActivity.kt`
- Delete: `android/app/src/main/kotlin/com/aimathtest/` (empty after move)

**Step 1: Create new directory**

Run:
```bash
mkdir -p android/app/src/main/kotlin/com/numerixlabs/aimathtest
```

**Step 2: Move and update MainActivity.kt**

Write to `android/app/src/main/kotlin/com/numerixlabs/aimathtest/MainActivity.kt`:
```kotlin
package com.numerixlabs.aimathtest

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

**Step 3: Delete old directory**

Run:
```bash
rm -rf android/app/src/main/kotlin/com/aimathtest
```

**Step 4: Verify structure**

Run: `find android/app/src/main/kotlin -name "*.kt"`
Expected: `android/app/src/main/kotlin/com/numerixlabs/aimathtest/MainActivity.kt`

---

### Task 3: Update web configuration files

**Files:**
- Modify: `web/.well-known/assetlinks.json:5`
- Modify: `web/privacy.html:83`

**Step 1: Update assetlinks.json**

Change line 5 from:
```json
"package_name": "com.aimathtest.aimathtest",
```
to:
```json
"package_name": "com.numerixlabs.aimathtest",
```

**Step 2: Update privacy.html contact email**

Change line 83 from:
```html
<p><a href="mailto:manish.dce@gmail.com">manish.dce@gmail.com</a></p>
```
to:
```html
<p><a href="mailto:numerixlabs@gmail.com">numerixlabs@gmail.com</a></p>
```

---

### Task 4: Update Play Store automation scripts

**Files:**
- Modify: `tool/play_upload.js:18`
- Modify: `tool/play_update_listing.js:16`
- Modify: `tool/diagnose_signin.js:23`
- Modify: `tool/fix_play_signing.js:150`

**Step 1: Update all 4 scripts**

In each file, replace `com.aimathtest.aimathtest` with `com.numerixlabs.aimathtest`:

- `tool/play_upload.js` line 18: `const PACKAGE_NAME = "com.numerixlabs.aimathtest";`
- `tool/play_update_listing.js` line 16: `const PACKAGE_NAME = "com.numerixlabs.aimathtest";`
- `tool/diagnose_signin.js` line 23: `const PACKAGE_NAME = "com.numerixlabs.aimathtest";`
- `tool/fix_play_signing.js` line 150: `packageName: "com.numerixlabs.aimathtest",`

**Step 2: Verify no old references remain in tool scripts**

Run: `grep -r "com.aimathtest.aimathtest" tool/`
Expected: No matches

---

### Task 5: Update Cloud Function

**Files:**
- Modify: `functions/src/verifyPurchase.ts:38`

**Step 1: Update package name**

Change line 38 from:
```typescript
const packageName = "com.aimathtest.aimathtest";
```
to:
```typescript
const packageName = "com.numerixlabs.aimathtest";
```

**Step 2: Run Cloud Function tests**

Run: `cd functions && npm test`
Expected: All tests pass

**Step 3: Commit all code changes**

```bash
git add -A
git commit -m "refactor: rename package com.aimathtest.aimathtest → com.numerixlabs.aimathtest

Update Android namespace, applicationId, Kotlin source directory,
assetlinks.json, Play Store scripts, verifyPurchase Cloud Function,
and privacy contact email to numerixlabs@gmail.com."
```

---

### Task 6: Firebase Console — Register new Android app

**This task requires manual steps in the browser.**

**Step 1: Add new Android app to Firebase**

1. Go to: https://console.firebase.google.com/project/aimathtest-kids-3ca24/settings/general
2. Click **"Add app"** → **Android**
3. Package name: `com.numerixlabs.aimathtest`
4. App nickname: `AIMathTest Android`
5. Skip the "Download google-services.json" step for now
6. Click **"Continue"** → **"Continue to console"**

**Step 2: Add SHA-1 fingerprints**

On the same project settings page, find the new `com.numerixlabs.aimathtest` app and click **"Add fingerprint"** three times:

1. Debug: `9D:E4:22:F3:B0:73:DD:90:F3:4B:FF:51:58:00:8F:6D:28:9B:70:72`
2. Upload: `1E:7E:99:62:7D:80:69:7B:4C:19:F0:D4:5F:1C:0D:E1:22:AE:05:1B`
3. Play Signing: `4D:9E:F4:1F:22:E6:E5:85:D2:9A:57:91:6F:82:EA:6C:80:EE:D1:35` (reuse if same keystore; update after new Play Console app if different)

**Step 3: Download new google-services.json**

1. Click **"Download google-services.json"** for the new `com.numerixlabs.aimathtest` app
2. Replace `android/app/google-services.json` with the downloaded file

**Step 4: Verify google-services.json**

Run:
```bash
node -e "const d=require('./android/app/google-services.json'); console.log('Package:', d.client[0].client_info.android_client_info.package_name); console.log('OAuth clients:', d.client[0].oauth_client.length)"
```
Expected:
```
Package: com.numerixlabs.aimathtest
OAuth clients: 3 (or more)
```

---

### Task 7: Google Cloud Console — API key restrictions

**Step 1: Add new package to API key restrictions**

1. Go to: https://console.cloud.google.com/apis/credentials?project=aimathtest-kids-3ca24
2. Click on the Android API key (auto created by Firebase)
3. Under **"Application restrictions"** → **"Android apps"**
4. Add new entry:
   - Package name: `com.numerixlabs.aimathtest`
   - SHA-1: `9D:E4:22:F3:B0:73:DD:90:F3:4B:FF:51:58:00:8F:6D:28:9B:70:72` (debug)
5. Add another entry:
   - Package name: `com.numerixlabs.aimathtest`
   - SHA-1: `1E:7E:99:62:7D:80:69:7B:4C:19:F0:D4:5F:1C:0D:E1:22:AE:05:1B` (upload)
6. Add another entry:
   - Package name: `com.numerixlabs.aimathtest`
   - SHA-1: `4D:9E:F4:1F:22:E6:E5:85:D2:9A:57:91:6F:82:EA:6C:80:EE:D1:35` (play signing — update later if different)
7. Click **"Save"**

**Step 2: Verify OAuth consent screen**

1. Go to: https://console.cloud.google.com/apis/credentials/consent?project=aimathtest-kids-3ca24
2. Confirm status is **"Production"** (not "Testing")

---

### Task 8: Build and test locally

**Step 1: Build debug APK**

Run: `flutter build apk --debug`
Expected: Build succeeds without errors

**Step 2: Install on emulator and test sign-in**

Run:
```bash
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```
Expected: App installs and Google Sign-In works

**Step 3: Run Flutter tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Commit google-services.json**

```bash
git add android/app/google-services.json
git commit -m "chore: add google-services.json for com.numerixlabs.aimathtest"
```

---

### Task 9: Google Play Console — Create new app and upload

**Step 1: Create new app in Play Console**

1. Go to: https://play.google.com/console
2. Click **"Create app"**
3. App name: `AIMathTest - Math for Kids`
4. Default language: English (United States)
5. App or Game: App
6. Free or Paid: Free
7. Accept declarations → **"Create app"**

**Step 2: Build release AAB**

Bump version in `pubspec.yaml` (set to `1.1.0+1` for fresh start):

Change:
```yaml
version: 1.0.5+6
```
to:
```yaml
version: 1.1.0+1
```

Run: `flutter build appbundle --release`
Expected: `build/app/outputs/bundle/release/app-release.aab` created

**Step 3: Upload AAB via automation script**

Run:
```bash
node tool/play_upload.js internal "Initial release with new package name"
```
Expected: Upload succeeds, version code 1

**Step 4: Upload store listing via automation script**

Run:
```bash
node tool/play_update_listing.js
```
Expected: Screenshots + feature graphic uploaded

**Step 5: Note Play App Signing SHA-1**

1. In Play Console → **Setup** → **App signing**
2. Copy the **"App signing key certificate"** SHA-1 fingerprint
3. If it differs from `4D:9E:F4:1F...`, run:
```bash
node tool/fix_play_signing.js "NEW:SHA:FINGERPRINT:HERE"
```
4. Rebuild and re-upload if google-services.json changed

**Step 6: Complete store listing in Play Console**

1. Set privacy policy URL: `https://aimathtest.numerixlabs.com/privacy.html`
2. Complete content rating questionnaire
3. Set target audience and content
4. Complete any remaining setup steps for release

**Step 7: Commit version bump**

```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.1.0+1 for new package"
```

---

### Task 10: Deploy web and Cloud Functions

**Step 1: Deploy to Firebase Hosting (privacy.html update)**

Run:
```bash
npx firebase-tools deploy --only hosting --project aimathtest-kids-3ca24
```
Expected: Privacy page updated at `https://aimathtest.numerixlabs.com/privacy.html`

**Step 2: Deploy Cloud Functions (verifyPurchase update)**

Run:
```bash
npx firebase-tools deploy --only functions --project aimathtest-kids-3ca24
```
Expected: `verifyPurchase` deployed with new package name

**Step 3: Verify privacy page**

Open: `https://aimathtest.numerixlabs.com/privacy.html`
Expected: Contact email shows `numerixlabs@gmail.com`

---

### Task 11: Verify sign-in on Play Store build

**Step 1: Install from Play Store internal testing**

1. On test device, open Play Store → find AIMathTest
2. Install the app
3. Sign in with Google

Expected: Sign-in succeeds

**Step 2: If sign-in fails, run diagnostics**

Run: `node tool/diagnose_signin.js`
Follow any fix instructions.

---

### Task 12: Clean up old app entries (optional)

**Step 1: Remove old Android app from Firebase Console**

1. Go to Firebase Console → Project Settings
2. Find `com.aimathtest.aimathtest` app
3. Click menu → **"Remove this app"**

**Step 2: Unpublish old app from Play Console**

1. Go to Play Console → old `com.aimathtest.aimathtest` app
2. Internal testing → **"Pause"** or discard the release

**Step 3: Clean up old OAuth clients in Google Cloud Console**

1. Go to Credentials page
2. Remove old OAuth 2.0 clients for `com.aimathtest.aimathtest`
3. Remove old API key entries for `com.aimathtest.aimathtest`

**Step 4: Update project memory**

Update `MEMORY.md` to reflect new package name `com.numerixlabs.aimathtest`.

**Step 5: Final commit and push**

```bash
git push origin master
```

---
