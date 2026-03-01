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

      const subscription = payload.subscription?.entity;
      const payment = payload.payment?.entity;
      const userId = subscription?.notes?.userId || payment?.notes?.userId;

      if (!userId) {
        console.warn("No userId in webhook payload, skipping");
        res.status(200).send("OK");
        return;
      }

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
