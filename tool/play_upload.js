#!/usr/bin/env node
/**
 * Upload AAB to Google Play Console and create a release.
 *
 * Usage:
 *   node tool/play_upload.js [track] [release_notes]
 *
 * Tracks: internal (default), alpha (closed), beta (open), production
 *
 * Example:
 *   node tool/play_upload.js internal "Bug fixes and improved answer accuracy"
 */

const fs = require("fs");
const path = require("path");
const { GoogleAuth } = require("google-auth-library");

const PACKAGE_NAME = "com.numerixlabs.aimathtest";
const KEY_FILE = path.join(__dirname, "..", "Keys", "aimathtest-kids-3ca24-399b72c9dbae.json");
const AAB_PATH = path.join(__dirname, "..", "build", "app", "outputs", "bundle", "release", "app-release.aab");
const API_BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";

// Map friendly names to API track names
const TRACK_MAP = {
  internal: "internal",
  alpha: "alpha",
  closed: "alpha",
  beta: "beta",
  open: "beta",
  production: "production",
};

async function main() {
  const track = TRACK_MAP[process.argv[2] || "internal"] || "internal";
  const releaseNotes = process.argv[3] || "Bug fixes and improvements";

  console.log(`\n📦 Play Store Upload`);
  console.log(`   Track: ${track}`);
  console.log(`   Package: ${PACKAGE_NAME}`);
  console.log(`   AAB: ${AAB_PATH}\n`);

  // Validate files exist
  if (!fs.existsSync(KEY_FILE)) {
    console.error(`❌ Service account key not found: ${KEY_FILE}`);
    process.exit(1);
  }
  if (!fs.existsSync(AAB_PATH)) {
    console.error(`❌ AAB not found: ${AAB_PATH}`);
    console.error("   Run: flutter build appbundle --release");
    process.exit(1);
  }

  const aabSize = fs.statSync(AAB_PATH).size;
  console.log(`   AAB size: ${(aabSize / 1024 / 1024).toFixed(1)} MB\n`);

  // Authenticate
  console.log("🔑 Authenticating with service account...");
  const auth = new GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await auth.getClient();

  // Step 1: Create an edit
  console.log("📝 Creating edit...");
  const editRes = await client.request({
    url: `${API_BASE}/${PACKAGE_NAME}/edits`,
    method: "POST",
    data: {},
  });
  const editId = editRes.data.id;
  console.log(`   Edit ID: ${editId}`);

  // Step 2: Upload AAB
  console.log("⬆️  Uploading AAB (this may take a minute)...");
  const aabData = fs.readFileSync(AAB_PATH);
  const uploadRes = await client.request({
    url: `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PACKAGE_NAME}/edits/${editId}/bundles`,
    method: "POST",
    headers: {
      "Content-Type": "application/octet-stream",
    },
    body: aabData,
  });
  const versionCode = uploadRes.data.versionCode;
  console.log(`   Uploaded! Version code: ${versionCode}`);

  // Step 3: Assign to track
  console.log(`🚀 Assigning to ${track} track...`);
  await client.request({
    url: `${API_BASE}/${PACKAGE_NAME}/edits/${editId}/tracks/${track}`,
    method: "PUT",
    data: {
      track: track,
      releases: [
        {
          status: process.argv[4] === "--draft" ? "draft" : "completed",
          versionCodes: [String(versionCode)],
          releaseNotes: [
            {
              language: "en-US",
              text: releaseNotes,
            },
          ],
        },
      ],
    },
  });
  console.log(`   Track updated!`);

  // Step 4: Commit the edit
  console.log("✅ Committing edit...");
  await client.request({
    url: `${API_BASE}/${PACKAGE_NAME}/edits/${editId}:commit`,
    method: "POST",
  });

  console.log(`\n🎉 Success! Release published to ${track} track.`);
  console.log(`   Version code: ${versionCode}`);
  console.log(`   Release notes: "${releaseNotes}"`);
  console.log(`\n   View in Play Console:`);
  console.log(`   https://play.google.com/console/developers/app/tracks/${track}\n`);
}

main().catch((err) => {
  console.error("\n❌ Upload failed:", err.message || err);
  if (err.response?.data) {
    console.error("   API response:", JSON.stringify(err.response.data, null, 2));
  }
  process.exit(1);
});
