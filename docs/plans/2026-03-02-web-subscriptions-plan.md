# Web Subscriptions (Razorpay) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add web subscription support using Razorpay alongside the existing Android Google Play Billing system.

**Architecture:** Razorpay Checkout.js handles the payment UI on web. A new `verifyRazorpay` Cloud Function receives webhooks from Razorpay, verifies the signature, and updates Firestore subscription fields (same schema as the Android flow). The existing `isPremiumProvider` reads from Firestore and works cross-platform without changes.

**Tech Stack:** Razorpay Checkout.js, Firebase Cloud Functions (Node.js), Flutter web (dart:js_interop), Riverpod providers.

---

### Task 1: Add Razorpay constants

**Files:**
- Modify: `lib/config/constants.dart:65-72`

**Step 1: Add Razorpay plan ID constants**

After `static const String annualProductId = 'premium_annual';` (line 68), add:

```dart
  // Razorpay (web subscriptions)
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_xxxxxxxxxxxxx', // Replace with test key
  );
  static const String razorpayMonthlyPlanId = 'plan_premium_monthly';
  static const String razorpayAnnualPlanId = 'plan_premium_annual';
```

**Step 2: Commit**

```bash
git add lib/config/constants.dart
git commit -m "feat: add Razorpay constants for web subscriptions"
```

---

### Task 2: Add Razorpay Checkout.js to web/index.html

**Files:**
- Modify: `web/index.html:46`

**Step 1: Add Razorpay script tag**

Before the `flutter_bootstrap.js` script tag (line 46), add:

```html
  <!-- Razorpay Checkout for web subscriptions -->
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
```

**Step 2: Commit**

```bash
git add web/index.html
git commit -m "feat: add Razorpay Checkout.js to web index.html"
```

---

### Task 3: Create Razorpay web service

**Files:**
- Create: `lib/services/razorpay_web_service.dart`

**Step 1: Create the web-only Razorpay service**

This service uses `dart:js_interop` to call Razorpay Checkout.js. It creates a Razorpay subscription checkout and handles success/failure callbacks.

```dart
import 'dart:async';
import 'dart:js_interop';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import '../config/constants.dart';

@JS('Razorpay')
extension type RazorpayJS._(JSObject _) implements JSObject {
  external factory RazorpayJS(JSObject options);
  external void open();
}

class RazorpayWebService {
  final void Function(String status)? onPaymentUpdate;

  RazorpayWebService({this.onPaymentUpdate});

  /// Open Razorpay checkout for a subscription plan.
  /// [planId] should be AppConstants.razorpayMonthlyPlanId or razorpayAnnualPlanId
  /// [userId] is the Firebase Auth UID (used to link payment to user)
  /// [email] is the user's email for Razorpay prefill
  Future<void> checkout({
    required String planId,
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final completer = Completer<void>();

    // First, create a Razorpay subscription via Cloud Function
    final callable = FirebaseFunctions.instance.httpsCallable('createRazorpaySubscription');
    final result = await callable.call({
      'planId': planId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final subscriptionId = data['subscriptionId'] as String;

    final options = {
      'key': AppConstants.razorpayKeyId,
      'subscription_id': subscriptionId,
      'name': AppConstants.appName,
      'description': planId == AppConstants.razorpayMonthlyPlanId
          ? 'Premium Monthly'
          : 'Premium Annual',
      'prefill': {
        'name': displayName,
        'email': email,
      },
      'theme': {
        'color': '#6C63FF',
      },
      'handler': ((JSObject response) {
        debugPrint('Razorpay payment success');
        onPaymentUpdate?.call('success');
        completer.complete();
      }).toJS,
      'modal': {
        'ondismiss': (() {
          debugPrint('Razorpay checkout dismissed');
          if (!completer.isCompleted) {
            onPaymentUpdate?.call('cancelled');
            completer.complete();
          }
        }).toJS,
      },
    }.jsify() as JSObject;

    try {
      final razorpay = RazorpayJS(options);
      razorpay.open();
    } catch (e) {
      debugPrint('Razorpay checkout error: $e');
      onPaymentUpdate?.call('error');
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future;
  }
}
```

**Step 2: Commit**

```bash
git add lib/services/razorpay_web_service.dart
git commit -m "feat: add Razorpay web service with JS interop"
```

---

### Task 4: Create `createRazorpaySubscription` Cloud Function

**Files:**
- Create: `functions/src/createRazorpaySubscription.ts`
- Modify: `functions/src/index.ts`

**Step 1: Create the Cloud Function**

This function creates a Razorpay subscription server-side (so the API secret stays on the server) and returns the subscription ID to the client for checkout.

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const razorpayKeyId = defineSecret("RAZORPAY_KEY_ID");
const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");

interface CreateSubscriptionRequest {
  planId: string;
}

export const createRazorpaySubscription = onCall(
  { secrets: [razorpayKeyId, razorpayKeySecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be logged in");
    }

    const { planId } = request.data as CreateSubscriptionRequest;
    if (!planId) {
      throw new HttpsError("invalid-argument", "Missing planId");
    }

    const userId = request.auth.uid;
    const email = request.auth.token.email || "";

    try {
      const keyId = razorpayKeyId.value();
      const keySecret = razorpayKeySecret.value();
      const authHeader = Buffer.from(`${keyId}:${keySecret}`).toString("base64");

      // Create a Razorpay subscription
      const response = await fetch("https://api.razorpay.com/v1/subscriptions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${authHeader}`,
        },
        body: JSON.stringify({
          plan_id: planId,
          total_count: planId.includes("annual") ? 10 : 120, // max billing cycles
          quantity: 1,
          notes: {
            userId,
            email,
          },
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Razorpay API error:", errorText);
        throw new Error(`Razorpay API error (${response.status}): ${errorText}`);
      }

      const subscription = await response.json();
      return { subscriptionId: subscription.id };
    } catch (error: unknown) {
      console.error("Failed to create Razorpay subscription:", error);
      const message = error instanceof Error ? error.message : "Unknown error";
      throw new HttpsError("internal", message);
    }
  }
);
```

**Step 2: Add to index.ts exports**

Change `functions/src/index.ts` to:

```typescript
import { generateTest } from "./generateTest";
import { cleanupExpiredTests } from "./cleanupExpiredTests";
import { verifyPurchase } from "./verifyPurchase";
import { createRazorpaySubscription } from "./createRazorpaySubscription";
import { verifyRazorpay } from "./verifyRazorpay";

export { generateTest, cleanupExpiredTests, verifyPurchase, createRazorpaySubscription, verifyRazorpay };
```

(Note: `verifyRazorpay` is created in the next task.)

**Step 3: Commit**

```bash
git add functions/src/createRazorpaySubscription.ts functions/src/index.ts
git commit -m "feat: add createRazorpaySubscription Cloud Function"
```

---

### Task 5: Create `verifyRazorpay` webhook Cloud Function

**Files:**
- Create: `functions/src/verifyRazorpay.ts`

**Step 1: Create the webhook handler**

This function receives Razorpay webhook events via HTTPS, verifies the signature, and updates Firestore.

```typescript
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const razorpayWebhookSecret = defineSecret("RAZORPAY_WEBHOOK_SECRET");

export const verifyRazorpay = onRequest(
  { secrets: [razorpayWebhookSecret] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    try {
      // Verify webhook signature
      const signature = req.headers["x-razorpay-signature"] as string;
      const body = JSON.stringify(req.body);
      const expectedSignature = crypto
        .createHmac("sha256", razorpayWebhookSecret.value())
        .update(body)
        .digest("hex");

      if (signature !== expectedSignature) {
        console.error("Razorpay webhook signature mismatch");
        res.status(400).send("Invalid signature");
        return;
      }

      const event = req.body;
      const eventType = event.event;
      const payload = event.payload;

      console.log(`Razorpay webhook: ${eventType}`);

      // Extract user ID from subscription notes
      const subscription = payload.subscription?.entity;
      const payment = payload.payment?.entity;
      const userId = subscription?.notes?.userId || payment?.notes?.userId;

      if (!userId) {
        console.warn("No userId in webhook payload, skipping");
        res.status(200).send("OK");
        return;
      }

      // Map Razorpay events to subscription status
      let status: string | null = null;
      let plan: string | null = null;

      switch (eventType) {
        case "subscription.activated":
        case "payment.authorized":
        case "payment.captured":
          status = "active";
          plan = subscription?.plan_id?.includes("annual")
            ? "premium_annual"
            : "premium_monthly";
          break;
        case "subscription.cancelled":
          status = "cancelled";
          break;
        case "subscription.completed":
        case "subscription.expired":
          status = "expired";
          plan = "free";
          break;
        case "subscription.paused":
          status = "grace_period";
          break;
        default:
          console.log(`Unhandled Razorpay event: ${eventType}`);
          res.status(200).send("OK");
          return;
      }

      // Update Firestore
      const updateData: Record<string, unknown> = {
        "subscription.status": status,
        "subscription.lastVerifiedAt": admin.firestore.Timestamp.now(),
        "subscription.source": "razorpay",
      };

      if (plan) {
        updateData["subscription.plan"] = plan;
      }

      if (subscription?.id) {
        updateData["subscription.razorpaySubscriptionId"] = subscription.id;
      }

      if (subscription?.current_end) {
        updateData["subscription.expiresAt"] = admin.firestore.Timestamp.fromMillis(
          subscription.current_end * 1000
        );
      }

      await db.collection("users").doc(userId).update(updateData);
      console.log(`Updated subscription for user ${userId}: ${status} (${plan || "unchanged"})`);

      res.status(200).send("OK");
    } catch (error) {
      console.error("Razorpay webhook error:", error);
      res.status(500).send("Internal error");
    }
  }
);
```

**Step 2: Commit**

```bash
git add functions/src/verifyRazorpay.ts
git commit -m "feat: add verifyRazorpay webhook Cloud Function"
```

---

### Task 6: Update subscription providers for web

**Files:**
- Modify: `lib/providers/subscription_provider.dart`

**Step 1: Make billingAvailableProvider return true on web**

Replace the entire file content:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';
import '../config/constants.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

/// The subscription service singleton (Android only).
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService(
    onPurchaseUpdate: (productId, status) {
      ref.invalidate(userProvider);
    },
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Whether billing is available on this platform.
final billingAvailableProvider = FutureProvider<bool>((ref) async {
  if (!AppConfig.useFirebase) return false;
  // Web uses Razorpay — always available
  if (kIsWeb) return true;
  if (!Platform.isAndroid) return false;
  final service = ref.read(subscriptionServiceProvider);
  return await service.initialize();
});

/// Available products from Google Play (Android only).
final subscriptionProductsProvider =
    FutureProvider<List<ProductDetails>>((ref) async {
  if (kIsWeb) return []; // Web uses Razorpay, not Google Play products
  final available = await ref.watch(billingAvailableProvider.future);
  if (!available) return [];
  final service = ref.read(subscriptionServiceProvider);
  return await service.getProducts();
});

/// Convenience: is current user premium?
/// Admin emails in AppConstants.adminEmails are always treated as premium.
final isPremiumProvider = Provider<bool>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final email = authUser?.email;
  if (email != null &&
      AppConstants.adminEmails.contains(email.toLowerCase())) {
    return true;
  }
  final user = ref.watch(userProvider).valueOrNull;
  return user?.isPremium ?? false;
});
```

**Step 2: Commit**

```bash
git add lib/providers/subscription_provider.dart
git commit -m "feat: enable billing on web via Razorpay"
```

---

### Task 7: Update UpgradeDialog for web

**Files:**
- Modify: `lib/widgets/upgrade_dialog.dart`

**Step 1: Replace with platform-aware upgrade dialog**

The dialog shows Razorpay plans on web, Google Play products on Android:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';

class UpgradeDialog extends ConsumerStatefulWidget {
  const UpgradeDialog({super.key});

  @override
  ConsumerState<UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends ConsumerState<UpgradeDialog> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upgrade to Premium'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unlock unlimited tests for your kids!'),
            const SizedBox(height: 16),
            _featureRow(Icons.all_inclusive, 'Unlimited daily tests'),
            _featureRow(Icons.family_restroom, 'All profiles included'),
            const SizedBox(height: 16),
            if (kIsWeb) ..._buildWebPlans() else ..._buildAndroidPlans(),
            if (!kIsWeb) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _purchasing ? null : _restorePurchases,
                child: const Text('Restore Purchases'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not Now'),
        ),
      ],
    );
  }

  List<Widget> _buildWebPlans() {
    return [
      _planCard(
        title: 'Monthly',
        price: '\u20B950/month',
        onTap: () => _purchaseWeb(AppConstants.razorpayMonthlyPlanId),
      ),
      _planCard(
        title: 'Annual',
        price: '\u20B9500/year (save 17%)',
        onTap: () => _purchaseWeb(AppConstants.razorpayAnnualPlanId),
      ),
    ];
  }

  List<Widget> _buildAndroidPlans() {
    final productsAsync = ref.watch(subscriptionProductsProvider);
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return [
            const Text(
              'No subscription plans available right now. Please try again later.',
              style: TextStyle(color: Colors.grey),
            ),
          ];
        }
        return products.map((p) => _productCard(p)).toList();
      },
      loading: () => [
        const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [Text('Could not load plans: $e')],
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(price),
        trailing: ElevatedButton(
          onPressed: _purchasing ? null : onTap,
          child: _purchasing
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Subscribe'),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _productCard(ProductDetails product) {
    final isAnnual = product.id == AppConstants.annualProductId;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(isAnnual ? 'Annual' : 'Monthly'),
        subtitle: Text(product.price),
        trailing: ElevatedButton(
          onPressed: _purchasing ? null : () => _purchase(product),
          child: _purchasing
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Subscribe'),
        ),
      ),
    );
  }

  Future<void> _purchaseWeb(String planId) async {
    setState(() => _purchasing = true);
    try {
      // Dynamic import to avoid loading on Android
      final module = await import('package:aimathtest/services/razorpay_web_service.dart');
      // Use the service
      final authUser = ref.read(authStateProvider).valueOrNull;
      final user = ref.read(userProvider).valueOrNull;

      final service = module.RazorpayWebService(
        onPaymentUpdate: (status) {
          if (status == 'success') {
            ref.invalidate(userProvider);
          }
        },
      );

      await service.checkout(
        planId: planId,
        userId: authUser!.uid,
        email: authUser.email ?? '',
        displayName: user?.profiles.firstOrNull?.name ?? 'Parent',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _purchase(ProductDetails product) async {
    setState(() => _purchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.buySubscription(product);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _purchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
}
```

Note: The dynamic `import()` for `razorpay_web_service.dart` may need to be replaced with a conditional import pattern if `dart:js_interop` causes compile errors on Android. In that case, use the same `_stub.dart` / `_web.dart` conditional import pattern the project already uses for URL strategy.

**Step 2: Commit**

```bash
git add lib/widgets/upgrade_dialog.dart
git commit -m "feat: platform-aware upgrade dialog (Razorpay on web, Google Play on Android)"
```

---

### Task 8: Update Settings screen Manage button for web

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart:373-379`

**Step 1: Make "Manage" button platform-aware**

Replace the Manage button `onPressed` (line 374-377):

```dart
trailing: TextButton(
  onPressed: () {
    if (kIsWeb) {
      // Razorpay doesn't have a customer portal — show info dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Manage Subscription'),
          content: const Text(
            'To cancel or modify your subscription, please contact us at numerixlabs@gmail.com',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      launchUrl(
        Uri.parse('https://play.google.com/store/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
    }
  },
  child: const Text('Manage'),
),
```

Add `import 'package:flutter/foundation.dart';` at the top if not already present.

**Step 2: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat: platform-aware subscription manage button"
```

---

### Task 9: Razorpay account setup (manual)

**This task requires manual steps.**

**Step 1: Create Razorpay account**
1. Go to https://razorpay.com and sign up
2. Complete KYC verification

**Step 2: Get API keys**
1. Dashboard → Settings → API Keys → Generate Key
2. Note the Key ID (`rzp_live_xxxxx`) and Key Secret

**Step 3: Create subscription plans**
1. Dashboard → Products → Subscriptions → Plans → Create Plan
2. Plan 1:
   - Name: `Premium Monthly`
   - Plan ID: `plan_premium_monthly`
   - Amount: ₹50
   - Period: monthly
   - Billing cycle: 1 month
3. Plan 2:
   - Name: `Premium Annual`
   - Plan ID: `plan_premium_annual`
   - Amount: ₹500
   - Period: yearly
   - Billing cycle: 1 year

**Step 4: Set up webhook**
1. Dashboard → Settings → Webhooks → Add New Webhook
2. URL: `https://us-central1-aimathtest-kids-3ca24.cloudfunctions.net/verifyRazorpay`
3. Secret: Generate a random string (save it)
4. Events: `payment.authorized`, `payment.captured`, `subscription.activated`, `subscription.cancelled`, `subscription.completed`, `subscription.expired`, `subscription.paused`

**Step 5: Store secrets in Firebase**
```bash
npx firebase-tools functions:secrets:set RAZORPAY_KEY_ID
npx firebase-tools functions:secrets:set RAZORPAY_KEY_SECRET
npx firebase-tools functions:secrets:set RAZORPAY_WEBHOOK_SECRET
```

**Step 6: Update constants.dart**

Replace the test Razorpay Key ID with the live one, or configure via `--dart-define` at build time:
```bash
flutter build web --dart-define=RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxx
```

---

### Task 10: Deploy and test

**Step 1: Run Cloud Function tests**

```bash
cd functions && npm test
```
Expected: All tests pass

**Step 2: Deploy Cloud Functions**

```bash
npx firebase-tools deploy --only functions --project aimathtest-kids-3ca24
```
Expected: 5 functions deployed (generateTest, cleanupExpiredTests, verifyPurchase, createRazorpaySubscription, verifyRazorpay)

**Step 3: Build and deploy web**

```bash
flutter build web --release --dart-define=RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxx
npx firebase-tools deploy --only hosting --project aimathtest-kids-3ca24
```

**Step 4: Test on web**

1. Go to https://aimathtest.numerixlabs.com
2. Sign in → Settings → Upgrade to Premium
3. Verify Razorpay checkout opens with monthly/annual options
4. Use Razorpay test card: `4111 1111 1111 1111`, expiry any future date, CVV any 3 digits
5. Verify webhook fires and user becomes premium

**Step 5: Commit and push**

```bash
git add -A
git commit -m "feat: complete web subscription system with Razorpay"
git push origin master
```

---
