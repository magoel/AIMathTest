#!/usr/bin/env node
/**
 * Diagnose Google Sign-In issues for Play Store builds.
 *
 * Checks:
 *  1. Firebase SHA fingerprints (all 3 keys registered?)
 *  2. google-services.json OAuth clients (matching?)
 *  3. OAuth 2.0 client status in Google Cloud (blocked?)
 *  4. OAuth consent screen status (Testing vs Production?)
 *  5. People API enabled? (required for Google Sign-In)
 *
 * Usage:
 *   node tool/diagnose_signin.js
 */

const fs = require("fs");
const path = require("path");
const { GoogleAuth } = require("google-auth-library");

const PROJECT_ID = "aimathtest-kids-3ca24";
const PROJECT_NUMBER = "299048422905";
const APP_ID = "1:299048422905:android:cea4b9bfa6581159368128";
const PACKAGE_NAME = "com.numerixlabs.aimathtest";
const KEY_FILE = path.join(__dirname, "..", "Keys", "aimathtest-kids-3ca24-399b72c9dbae.json");
const GOOGLE_SERVICES_PATH = path.join(__dirname, "..", "android", "app", "google-services.json");

const FIREBASE_API = "https://firebase.googleapis.com/v1beta1";
const CLOUD_API = "https://serviceusage.googleapis.com/v1";
const OAUTH_API = "https://oauth2.googleapis.com";

// Known SHA-1 fingerprints
const KNOWN_KEYS = {
  "9de422f3b073dd90f34bff5158008f6d289b7072": "Debug key",
  "1e7e99627d80697b4c19f0d45f1c0de122ae051b": "Upload/Release key",
  "4d9ef41f22e6e585d29a57916f82ea6c80eed135": "Play App Signing key",
};

function status(ok, msg) {
  console.log(`   ${ok ? "✅" : "❌"} ${msg}`);
}

function warn(msg) {
  console.log(`   ⚠️  ${msg}`);
}

async function main() {
  console.log("\n🔍 AIMathTest Sign-In Diagnostics\n");

  // Authenticate
  const auth = new GoogleAuth({
    keyFile: KEY_FILE,
    scopes: [
      "https://www.googleapis.com/auth/firebase",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/cloud-platform.read-only",
    ],
  });
  const client = await auth.getClient();

  let hasIssues = false;

  // ═══ CHECK 1: Firebase SHA Fingerprints ═══
  console.log("1️⃣  Firebase SHA Fingerprints");
  try {
    const res = await client.request({
      url: `${FIREBASE_API}/projects/${PROJECT_ID}/androidApps/${APP_ID}/sha`,
      method: "GET",
    });
    const certs = res.data.certificates || [];
    const registeredHashes = certs.map((c) => c.shaHash.replace(/:/g, "").toLowerCase());

    for (const [hash, label] of Object.entries(KNOWN_KEYS)) {
      const found = registeredHashes.includes(hash);
      status(found, `${label}: ${hash.substring(0, 12)}...${found ? "" : " (MISSING!)"}`);
      if (!found) hasIssues = true;
    }

    // Check for extra fingerprints
    for (const cert of certs) {
      const h = cert.shaHash.replace(/:/g, "").toLowerCase();
      if (!KNOWN_KEYS[h]) {
        warn(`Unknown fingerprint: ${h} (${cert.certType})`);
      }
    }
  } catch (err) {
    status(false, `Failed to check Firebase: ${err.message}`);
    hasIssues = true;
  }

  // ═══ CHECK 2: google-services.json ═══
  console.log("\n2️⃣  google-services.json");
  try {
    const gsJson = JSON.parse(fs.readFileSync(GOOGLE_SERVICES_PATH, "utf-8"));
    const oauthClients = gsJson.client?.[0]?.oauth_client || [];
    const androidClients = oauthClients.filter((c) => c.client_type === 1);
    const webClients = oauthClients.filter((c) => c.client_type === 3);

    status(webClients.length > 0, `Web client ID: ${webClients[0]?.client_id?.substring(0, 30) || "MISSING"}...`);
    status(androidClients.length >= 3, `Android OAuth clients: ${androidClients.length} (need 3: debug + upload + play signing)`);

    for (const ac of androidClients) {
      const hash = ac.android_info?.certificate_hash || "unknown";
      const label = KNOWN_KEYS[hash] || "Unknown key";
      console.log(`      - ${label}: ${hash.substring(0, 12)}... → ${ac.client_id.substring(0, 25)}...`);
    }

    // Verify all known keys have OAuth clients
    for (const [hash, label] of Object.entries(KNOWN_KEYS)) {
      const hasClient = androidClients.some((c) => c.android_info?.certificate_hash === hash);
      if (!hasClient) {
        status(false, `No OAuth client for ${label} — re-download google-services.json from Firebase Console`);
        hasIssues = true;
      }
    }
  } catch (err) {
    status(false, `Failed to read google-services.json: ${err.message}`);
    hasIssues = true;
  }

  // ═══ CHECK 3: OAuth 2.0 Clients Status ═══
  console.log("\n3️⃣  OAuth 2.0 Client Status (Google Cloud)");
  try {
    const res = await client.request({
      url: `https://oauth2.googleapis.com/v1/projects/${PROJECT_NUMBER}/oauthClients`,
      method: "GET",
    });
    const clients = res.data.oauthClients || [];
    for (const oc of clients) {
      const blocked = oc.state === "BLOCKED" || oc.disabled;
      status(!blocked, `${oc.displayName || oc.clientId}: ${blocked ? "BLOCKED!" : "active"}`);
      if (blocked) hasIssues = true;
    }
  } catch (err) {
    // This API might not be accessible — fall back to manual check
    warn(`Cannot check OAuth client status via API (${err.response?.status || err.message})`);
    console.log("      → Manual check: https://console.cloud.google.com/apis/credentials?project=" + PROJECT_ID);
    console.log("      → Look for OAuth 2.0 Client IDs → ensure none are disabled/blocked");
    console.log("      → The Play Signing client (SHA-1: 4d9ef41f...) must be enabled");
  }

  // ═══ CHECK 4: Required APIs Enabled ═══
  console.log("\n4️⃣  Required APIs");
  const requiredApis = [
    { id: "people.googleapis.com", name: "People API" },
    { id: "firebaseauth.googleapis.com", name: "Firebase Auth API" },
    { id: "identitytoolkit.googleapis.com", name: "Identity Toolkit API" },
  ];

  for (const api of requiredApis) {
    try {
      const res = await client.request({
        url: `${CLOUD_API}/projects/${PROJECT_ID}/services/${api.id}`,
        method: "GET",
      });
      const state = res.data.state;
      status(state === "ENABLED", `${api.name}: ${state}`);
      if (state !== "ENABLED") hasIssues = true;
    } catch (err) {
      if (err.response?.status === 403 || err.response?.status === 404) {
        status(false, `${api.name}: DISABLED or not accessible`);
        hasIssues = true;
      } else {
        warn(`${api.name}: Could not check (${err.message})`);
      }
    }
  }

  // ═══ CHECK 5: OAuth Consent Screen ═══
  console.log("\n5️⃣  OAuth Consent Screen");
  try {
    const res = await client.request({
      url: `https://oauth2.googleapis.com/v1/projects/${PROJECT_NUMBER}/brandStatus`,
      method: "GET",
    });
    console.log("      Status:", JSON.stringify(res.data));
  } catch (err) {
    warn(`Cannot check consent screen via API (${err.response?.status || err.message})`);
    console.log("      → Manual check: https://console.cloud.google.com/apis/credentials/consent?project=" + PROJECT_ID);
    console.log("      → Must be in 'Production' mode (not 'Testing')");
    console.log("      → If in 'Testing', add test user emails or publish to Production");
  }

  // ═══ SUMMARY ═══
  console.log("\n" + "═".repeat(60));
  if (hasIssues) {
    console.log("❌ Issues found! See details above.");
    console.log("\n   Most common fix for 'blocked' error:");
    console.log("   1. Go to: https://console.cloud.google.com/apis/credentials?project=" + PROJECT_ID);
    console.log("   2. Find OAuth 2.0 Client IDs section");
    console.log("   3. Click on client with SHA-1 4d9ef41f... (Play App Signing)");
    console.log("   4. Make sure it is ENABLED (not blocked/disabled)");
    console.log("   5. Also check OAuth consent screen is in 'Production' mode");
  } else {
    console.log("✅ All checks passed! Sign-in should work.");
  }
  console.log("═".repeat(60) + "\n");
}

main().catch((err) => {
  console.error("❌ Diagnostic failed:", err.message);
  if (err.response?.data) {
    console.error("   API response:", JSON.stringify(err.response.data, null, 2));
  }
  process.exit(1);
});
