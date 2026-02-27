# Quota Counting & Pricing Alignment Bugfix — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix two bugs: (A) count test *generations* toward the free tier quota instead of only *completions*, and (B) fix pricing text alignment on the Settings subscription card.

**Architecture:** Bug A changes the `getMonthTestCount()` method in both database services to query the `tests` collection (by `createdBy.parentId`) instead of `attempts`. Bug B restructures the free plan card to use `ListTile` for consistent alignment with the premium card.

**Tech Stack:** Flutter/Dart, Firestore, Riverpod

---

### Task 1: Update `getMonthTestCount()` in DatabaseService (Firestore)

**Files:**
- Modify: `lib/services/database_service.dart:168-180`

**Step 1: Rewrite `getMonthTestCount` to query `tests` collection**

Replace the existing method at line 168-180 with:

```dart
Future<int> getMonthTestCount(String parentId) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final snapshot = await _db
      .collection('tests')
      .where('createdBy.parentId', isEqualTo: parentId)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .get();
  return snapshot.docs.length;
}
```

Key change: queries `tests` (not `attempts`), uses `createdBy.parentId` (not `parentId` + `profileId`), counts all docs (each doc = one generation).

**Step 2: Verify it compiles**

Run: `cd C:\project\AIMathTest && C:\dev\flutter\bin\flutter.bat analyze --no-fatal-infos 2>&1 | head -20`

Expected: errors about callers still passing `profileId` — that's fine, we fix those next.

---

### Task 2: Update `getMonthTestCount()` in LocalDatabaseService

**Files:**
- Modify: `lib/services/local_database_service.dart:196-207`

**Step 1: Rewrite local `getMonthTestCount` to query `_tests` map**

Replace the existing method at line 196-207 with:

```dart
Future<int> getMonthTestCount(String parentId) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  return _tests.values
      .where((t) =>
          t.createdBy.parentId == parentId &&
          t.createdAt.isAfter(startOfMonth))
      .length;
}
```

---

### Task 3: Update FirebaseDatabaseWrapper delegation

**Files:**
- Modify: `lib/providers/user_provider.dart:150-152`

**Step 1: Update the wrapper method signature**

Replace line 150-152:

```dart
@override
Future<int> getMonthTestCount(String parentId) =>
    _fb.getMonthTestCount(parentId);
```

---

### Task 4: Update callers — test_config_screen.dart

**Files:**
- Modify: `lib/screens/test_config/test_config_screen.dart:48`

**Step 1: Remove `profile.id` from `getMonthTestCount` call**

Change line 48 from:
```dart
final monthCount = await db.getMonthTestCount(user.uid, profile.id);
```
To:
```dart
final monthCount = await db.getMonthTestCount(user.uid);
```

---

### Task 5: Update Settings screen — quota display + pricing card

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart:386-470`

**Step 1: Update quota counting to use `getMonthTestCount` (generations, not completions)**

Replace lines 386-396 with:

```dart
// Count generations this month (not completions — generation = cost)
final db = ref.read(databaseServiceProvider);
final authState = ref.watch(authStateProvider);
final parentId = authState.valueOrNull?.uid;
int monthUsed = 0;
if (parentId != null) {
  // Use FutureBuilder pattern or default to 0
  // We'll compute inline since this is a sync build method
}
final remaining = (AppConstants.freeTestMonthlyLimit - monthUsed)
    .clamp(0, AppConstants.freeTestMonthlyLimit);
```

Note: The settings screen currently computes `monthUsed` from `attemptsAsync` inline. Since we now need to query `tests` (a Future, not a Stream), we need to either:
- Add a `testsThisMonth` provider, OR
- Use a `FutureBuilder` inline

Simplest: create a small `monthGenerationCountProvider` in `test_provider.dart`.

**Step 2: Create `monthGenerationCountProvider`**

Add to `lib/providers/test_provider.dart`:

```dart
final monthGenerationCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return 0;
  final db = ref.read(databaseServiceProvider);
  return db.getMonthTestCount(user.uid);
});
```

**Step 3: Rebuild free plan card with ListTile + correct quota**

Replace lines 386-470 of `_SubscriptionCard` (the free plan section) with:

```dart
final monthUsed = ref.watch(monthGenerationCountProvider).valueOrNull ?? 0;
final remaining = (AppConstants.freeTestMonthlyLimit - monthUsed)
    .clamp(0, AppConstants.freeTestMonthlyLimit);

return Card(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: const Icon(Icons.diamond_outlined),
        title: const Text('Free Plan',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$remaining of ${AppConstants.freeTestMonthlyLimit} generations remaining this month',
        ),
      ),
      ListTile(
        dense: true,
        title: Text(
          'Upgrade to Premium for unlimited tests:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '\u2022 Monthly: \u20B950/month\n'
          '\u2022 Annual: \u20B9500/year (save 17%)',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ),
      if (canUpgrade)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const UpgradeDialog(),
              ),
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ),
    ],
  ),
);
```

**Step 4: Verify build**

Run: `cd C:\project\AIMathTest && C:\dev\flutter\bin\flutter.bat analyze --no-fatal-infos`
Expected: No errors.

**Step 5: Commit**

```bash
git add lib/services/database_service.dart lib/services/local_database_service.dart lib/providers/user_provider.dart lib/providers/test_provider.dart lib/screens/test_config/test_config_screen.dart lib/screens/settings/settings_screen.dart
git commit -m "Fix quota to count generations (not completions) and align pricing card"
```

---

### Task 6: Build and install on emulator for verification

**Step 1: Build debug APK**

Run: `cd C:\project\AIMathTest && C:\dev\flutter\bin\flutter.bat build apk --debug`

**Step 2: Install on emulator**

Run: `C:\Users\mgoel\AppData\Local\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r <apk-path>`

**Step 3: Manual verification**
- Open app, sign in
- Go to Settings → verify "X of 10 generations remaining this month" text
- Verify pricing bullets are left-aligned with "Free Plan" title
- Go to New Test → generate a test but don't submit → check Settings again (count should increase)

**Step 4: Push**

Run: `git push`
