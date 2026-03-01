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

      const response = await fetch("https://api.razorpay.com/v1/subscriptions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${authHeader}`,
        },
        body: JSON.stringify({
          plan_id: planId,
          total_count: planId.includes("annual") ? 10 : 120,
          quantity: 1,
          notes: { userId, email },
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
