import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { google } from "googleapis";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface VerifyPurchaseRequest {
  purchaseToken: string;
  productId: string;
  source: string;
}

export const verifyPurchase = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in");
  }

  const { purchaseToken, productId } = request.data as VerifyPurchaseRequest;
  const userId = request.auth.uid;

  if (!purchaseToken || !productId) {
    throw new HttpsError("invalid-argument", "Missing purchaseToken or productId");
  }

  try {
    // Use Application Default Credentials (Firebase service account)
    const auth = new google.auth.GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });

    const androidPublisher = google.androidpublisher({
      version: "v3",
      auth: auth,
    });

    // Verify the subscription with Google Play using v2 API
    const response = await androidPublisher.purchases.subscriptionsv2.get({
      packageName: "com.aimathtest.aimathtest",
      token: purchaseToken,
    });

    const purchase = response.data;

    // Determine subscription status from lineItems
    let status = "expired";
    let expiryTimeMillis = 0;

    if (purchase.lineItems && purchase.lineItems.length > 0) {
      const lineItem = purchase.lineItems[0];
      if (lineItem.expiryTime) {
        expiryTimeMillis = new Date(lineItem.expiryTime).getTime();
      }

      const now = Date.now();
      if (expiryTimeMillis > now) {
        // Subscription is still within its period
        if (purchase.subscriptionState === "SUBSCRIPTION_STATE_ACTIVE") {
          status = "active";
        } else if (purchase.subscriptionState === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
          status = "grace_period";
        } else if (purchase.subscriptionState === "SUBSCRIPTION_STATE_CANCELED") {
          // Cancelled but still within paid period
          status = "cancelled";
        } else {
          status = "active";
        }
      }
    }

    // Determine plan name
    const plan = status === "expired"
      ? "free"
      : (productId === "premium_monthly" ? "premium_monthly" : "premium_annual");

    // Update Firestore
    await db.collection("users").doc(userId).update({
      "subscription.plan": plan,
      "subscription.status": status,
      "subscription.purchaseToken": purchaseToken,
      "subscription.productId": productId,
      "subscription.expiresAt": admin.firestore.Timestamp.fromMillis(expiryTimeMillis),
      "subscription.lastVerifiedAt": admin.firestore.Timestamp.now(),
    });

    return { status, plan, expiresAt: expiryTimeMillis };
  } catch (error: unknown) {
    console.error("Purchase verification failed:", error);
    const message = error instanceof Error ? error.message : "Verification failed";
    throw new HttpsError("internal", message);
  }
});
