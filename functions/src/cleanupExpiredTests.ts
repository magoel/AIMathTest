import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const cleanupExpiredTests = onSchedule("every day 02:00", async () => {
  const now = admin.firestore.Timestamp.now();

  const expired = await db
    .collection("tests")
    .where("expiresAt", "<", now)
    .limit(500)
    .get();

  if (expired.empty) {
    console.log("No expired tests to clean up");
    return;
  }

  const batch = db.batch();
  let count = 0;

  for (const doc of expired.docs) {
    batch.delete(doc.ref);
    count++;
  }

  await batch.commit();
  console.log(`Deleted ${count} expired tests`);
});
