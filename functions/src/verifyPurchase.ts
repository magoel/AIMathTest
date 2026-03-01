import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { GoogleAuth } from "google-auth-library";

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
    // Use Application Default Credentials via google-auth-library
    const auth = new GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });
    const client = await auth.getClient();
    const accessToken = await client.getAccessToken();

    // Call Google Play Developer API v2 directly via REST
    const packageName = "com.numerixlabs.aimathtest";
    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptionsv2/tokens/${purchaseToken}`;

    const response = await fetch(url, {
      headers: {
        Authorization: `Bearer ${accessToken.token}`,
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Google Play API error (${response.status}): ${errorText}`);
    }

    const purchase = await response.json();

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
        if (purchase.subscriptionState === "SUBSCRIPTION_STATE_ACTIVE") {
          status = "active";
        } else if (purchase.subscriptionState === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
          status = "grace_period";
        } else if (purchase.subscriptionState === "SUBSCRIPTION_STATE_CANCELED") {
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
