#!/usr/bin/env node
/**
 * Fix Google Sign-In for Play Store builds.
 *
 * Automates: Add SHA fingerprint to Firebase → Download google-services.json
 *
 * Usage:
 *   node tool/fix_play_signing.js <SHA-1 or SHA-256 fingerprint>
 *
 * Example:
 *   node tool/fix_play_signing.js "4D:9E:F4:1F:22:E6:E5:85:D2:9A:57:91:6F:82:EA:6C:80:EE:D1:35"
 *
 * Where to find the fingerprint:
 *   Play Console → Setup → App signing → "App signing key certificate" → SHA-1
 */

const fs = require("fs");
const path = require("path");
const { GoogleAuth } = require("google-auth-library");

const PROJECT_ID = "aimathtest-kids-3ca24";
const APP_ID = "1:299048422905:android:df093ec03eacde2d368128";
const KEY_FILE = path.join(__dirname, "..", "Keys", "aimathtest-kids-3ca24-399b72c9dbae.json");
const GOOGLE_SERVICES_PATH = path.join(__dirname, "..", "android", "app", "google-services.json");

const FIREBASE_API = "https://firebase.googleapis.com/v1beta1";

async function main() {
  let sha = process.argv[2];
  if (!sha) {
    console.error("\n❌ Usage: node tool/fix_play_signing.js <SHA fingerprint>");
    console.error("\n   Get it from: Play Console → Setup → App signing");
    console.error('   → "App signing key certificate" → SHA-1 fingerprint\n');
    process.exit(1);
  }

  // Normalize: remove colons, lowercase
  const shaClean = sha.replace(/:/g, "").toLowerCase();
  const shaType = shaClean.length === 40 ? "SHA_1" : shaClean.length === 64 ? "SHA_256" : null;
  if (!shaType) {
    console.error(`\n❌ Invalid fingerprint length (${shaClean.length} hex chars).`);
    console.error("   Expected SHA-1 (40 hex chars) or SHA-256 (64 hex chars).\n");
    process.exit(1);
  }

  console.log(`\n🔧 Fix Play Store Sign-In`);
  console.log(`   Project: ${PROJECT_ID}`);
  console.log(`   App ID: ${APP_ID}`);
  console.log(`   Fingerprint: ${sha}`);
  console.log(`   Type: ${shaType}\n`);

  // Authenticate
  console.log("🔑 Authenticating...");
  const auth = new GoogleAuth({
    keyFile: KEY_FILE,
    scopes: [
      "https://www.googleapis.com/auth/firebase",
      "https://www.googleapis.com/auth/cloud-platform",
    ],
  });
  const client = await auth.getClient();

  // Step 1: List existing SHA certificates
  console.log("\n📋 Step 1: Checking existing SHA certificates...");
  const existingRes = await client.request({
    url: `${FIREBASE_API}/projects/${PROJECT_ID}/androidApps/${APP_ID}/sha`,
    method: "GET",
  });
  const existing = existingRes.data.certificates || [];
  console.log(`   Found ${existing.length} existing certificate(s):`);
  for (const cert of existing) {
    console.log(`   - ${cert.certType}: ${cert.shaHash}`);
  }

  // Check if already added
  const alreadyExists = existing.some(
    (c) => c.shaHash.replace(/:/g, "").toLowerCase() === shaClean
  );
  if (alreadyExists) {
    console.log("\n   ✅ Fingerprint already registered in Firebase!");
  } else {
    // Step 2: Add the SHA certificate
    console.log(`\n📝 Step 2: Adding ${shaType} fingerprint to Firebase...`);
    await client.request({
      url: `${FIREBASE_API}/projects/${PROJECT_ID}/androidApps/${APP_ID}/sha`,
      method: "POST",
      data: {
        shaHash: sha,
        certType: shaType,
      },
    });
    console.log("   ✅ Fingerprint added!");
  }

  // Step 3: Download updated google-services.json
  console.log("\n📥 Step 3: Downloading updated google-services.json...");
  const configRes = await client.request({
    url: `${FIREBASE_API}/projects/${PROJECT_ID}/androidApps/${APP_ID}/config`,
    method: "GET",
  });

  const configContent = configRes.data.configFileContents;
  if (!configContent) {
    console.error("   ❌ No config file returned from Firebase API.");
    process.exit(1);
  }

  // configFileContents is base64-encoded
  const decoded = Buffer.from(configContent, "base64").toString("utf-8");
  const parsed = JSON.parse(decoded);

  // Write formatted JSON
  fs.writeFileSync(GOOGLE_SERVICES_PATH, JSON.stringify(parsed, null, 2) + "\n");
  console.log(`   ✅ Saved to ${GOOGLE_SERVICES_PATH}`);

  // Count oauth_clients to verify
  const clients = parsed.client?.[0]?.oauth_client || [];
  console.log(`   OAuth clients: ${clients.length}`);
  for (const oc of clients) {
    if (oc.android_info) {
      console.log(`   - ${oc.android_info.certificate_hash} (${oc.client_type === 1 ? "Android" : "Web"})`);
    } else {
      console.log(`   - Web client: ${oc.client_id.substring(0, 20)}...`);
    }
  }

  // Step 4: Check API key restrictions
  console.log("\n🔑 Step 4: Checking API key restrictions...");
  try {
    const keysRes = await client.request({
      url: `https://apikeys.googleapis.com/v2/projects/${PROJECT_ID}/locations/global/keys`,
      method: "GET",
    });
    const keys = keysRes.data.keys || [];
    for (const key of keys) {
      const restrictions = key.restrictions?.androidKeyRestrictions?.allowedApplications || [];
      if (restrictions.length > 0) {
        const keyName = key.displayName || key.uid || "unnamed";
        console.log(`   API Key "${keyName}":`);
        const hasPlaySigning = restrictions.some(
          (r) => r.sha1Fingerprint?.replace(/:/g, "").toLowerCase() === shaClean
        );
        if (hasPlaySigning) {
          console.log(`   ✅ Play Signing SHA-1 already in allowed list`);
        } else {
          console.log(`   ⚠️  Play Signing SHA-1 NOT in allowed list — adding it...`);
          // Add the fingerprint to allowed applications
          const updated = [...restrictions, {
            sha1Fingerprint: sha,
            packageName: "com.numerixlabs.aimathtest",
          }];
          await client.request({
            url: `https://apikeys.googleapis.com/v2/${key.name}?updateMask=restrictions.androidKeyRestrictions.allowedApplications`,
            method: "PATCH",
            data: {
              restrictions: {
                ...key.restrictions,
                androidKeyRestrictions: {
                  allowedApplications: updated,
                },
              },
            },
          });
          console.log(`   ✅ Added! Play Signing SHA-1 now allowed for this API key.`);
        }
      }
    }
  } catch (err) {
    console.warn(`   ⚠️  Could not check API key restrictions: ${err.message}`);
    console.log("      → Manual check: https://console.cloud.google.com/apis/credentials?project=" + PROJECT_ID);
    console.log("      → Ensure Android API key allows SHA-1: " + sha);
  }

  console.log("\n🎉 Done! Next steps:");
  console.log("   1. Rebuild AAB:  node tool/play_upload.js internal \"Fix sign-in\"");
  console.log("   2. Or run:       flutter build appbundle --release");
  console.log("");
}

main().catch((err) => {
  console.error("\n❌ Failed:", err.message || err);
  if (err.response?.data) {
    console.error("   API response:", JSON.stringify(err.response.data, null, 2));
  }
  process.exit(1);
});
