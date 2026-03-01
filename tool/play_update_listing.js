#!/usr/bin/env node
/**
 * Update Google Play Store listing: screenshots and feature graphic.
 *
 * Usage:
 *   node tool/play_update_listing.js
 *
 * Uploads phone screenshots, tablet screenshots, and feature graphic
 * from assets/store/ directory.
 */

const fs = require("fs");
const path = require("path");
const { GoogleAuth } = require("google-auth-library");

const PACKAGE_NAME = "com.numerixlabs.aimathtest";
const KEY_FILE = path.join(__dirname, "..", "Keys", "aimathtest-kids-3ca24-399b72c9dbae.json");
const STORE_DIR = path.join(__dirname, "..", "assets", "store");
const API_BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";
const UPLOAD_BASE = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications";

// Phone screenshots in display order
const PHONE_SCREENSHOTS = [
  "phone_screenshot_home.png",
  "phone_screenshot_newtest.png",
  "phone_screenshot_testtaking.png",
  "phone_screenshot_mcq.png",
  "phone_screenshot_results.png",
  "phone_screenshot_progress.png",
  "phone_screenshot_settings.png",
  "phone_screenshot_profile.png",
];

// 7-inch tablet screenshots
const TABLET7_SCREENSHOTS = [
  "tablet_screenshot_landing.png",
];

// 10-inch tablet screenshots
const TABLET10_SCREENSHOTS = [
  "tablet10_screenshot_landing.png",
];

async function uploadImage(client, editId, imageType, filePath) {
  const imageData = fs.readFileSync(filePath);
  const res = await client.request({
    url: `${UPLOAD_BASE}/${PACKAGE_NAME}/edits/${editId}/listings/en-US/${imageType}`,
    method: "POST",
    headers: {
      "Content-Type": "image/png",
    },
    body: imageData,
  });
  return res.data;
}

async function deleteAllImages(client, editId, imageType) {
  try {
    await client.request({
      url: `${API_BASE}/${PACKAGE_NAME}/edits/${editId}/listings/en-US/${imageType}`,
      method: "DELETE",
    });
  } catch (err) {
    // Ignore if no images to delete
  }
}

async function main() {
  console.log(`\n🖼️  Play Store Listing Update`);
  console.log(`   Package: ${PACKAGE_NAME}\n`);

  // Validate
  if (!fs.existsSync(KEY_FILE)) {
    console.error(`❌ Service account key not found: ${KEY_FILE}`);
    process.exit(1);
  }

  // Authenticate
  console.log("🔑 Authenticating...");
  const auth = new GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await auth.getClient();

  // Create edit
  console.log("📝 Creating edit...");
  const editRes = await client.request({
    url: `${API_BASE}/${PACKAGE_NAME}/edits`,
    method: "POST",
    data: {},
  });
  const editId = editRes.data.id;
  console.log(`   Edit ID: ${editId}\n`);

  // Upload phone screenshots
  const phoneFiles = PHONE_SCREENSHOTS.filter(f => fs.existsSync(path.join(STORE_DIR, f)));
  if (phoneFiles.length > 0) {
    console.log(`📱 Phone screenshots (${phoneFiles.length}):`);
    console.log("   Clearing existing screenshots...");
    await deleteAllImages(client, editId, "phoneScreenshots");
    for (const file of phoneFiles) {
      const filePath = path.join(STORE_DIR, file);
      console.log(`   ⬆️  Uploading ${file}...`);
      await uploadImage(client, editId, "phoneScreenshots", filePath);
    }
    console.log("   ✅ Phone screenshots uploaded!\n");
  }

  // Upload 7-inch tablet screenshots
  const tablet7Files = TABLET7_SCREENSHOTS.filter(f => fs.existsSync(path.join(STORE_DIR, f)));
  if (tablet7Files.length > 0) {
    console.log(`📱 7-inch tablet screenshots (${tablet7Files.length}):`);
    console.log("   Clearing existing screenshots...");
    await deleteAllImages(client, editId, "sevenInchScreenshots");
    for (const file of tablet7Files) {
      const filePath = path.join(STORE_DIR, file);
      console.log(`   ⬆️  Uploading ${file}...`);
      await uploadImage(client, editId, "sevenInchScreenshots", filePath);
    }
    console.log("   ✅ 7-inch tablet screenshots uploaded!\n");
  }

  // Upload 10-inch tablet screenshots
  const tablet10Files = TABLET10_SCREENSHOTS.filter(f => fs.existsSync(path.join(STORE_DIR, f)));
  if (tablet10Files.length > 0) {
    console.log(`📱 10-inch tablet screenshots (${tablet10Files.length}):`);
    console.log("   Clearing existing screenshots...");
    await deleteAllImages(client, editId, "tenInchScreenshots");
    for (const file of tablet10Files) {
      const filePath = path.join(STORE_DIR, file);
      console.log(`   ⬆️  Uploading ${file}...`);
      await uploadImage(client, editId, "tenInchScreenshots", filePath);
    }
    console.log("   ✅ 10-inch tablet screenshots uploaded!\n");
  }

  // Upload feature graphic
  const featureGraphicPath = path.join(STORE_DIR, "feature_graphic.png");
  if (fs.existsSync(featureGraphicPath)) {
    console.log("🎨 Feature graphic:");
    console.log("   Clearing existing...");
    await deleteAllImages(client, editId, "featureGraphic");
    console.log("   ⬆️  Uploading feature_graphic.png...");
    await uploadImage(client, editId, "featureGraphic", featureGraphicPath);
    console.log("   ✅ Feature graphic uploaded!\n");
  }

  // Set store listing (required for commit — must have title)
  console.log("📋 Setting store listing...");
  let listingData = {
    language: "en-US",
    title: "AIMathTest - Math for Kids",
    shortDescription: "AI-powered math tests for K-12. Practice fractions, algebra & more!",
    fullDescription: "AIMathTest is an AI-powered math test generator designed for K-12 students. Create personalized math tests across 17 topics including addition, subtraction, multiplication, division, fractions, decimals, percentages, algebra, geometry, trigonometry, and more.\n\nFeatures:\n• AI-generated questions tailored to your child's grade level and curriculum (CBSE, IB, Cambridge)\n• Adjustable difficulty from Level 1 (easy) to Level 10 (competition math)\n• Mix of multiple-choice and fill-in-the-blank questions\n• Real-time scoring with detailed results\n• Progress tracking with score trends and topic performance\n• Multiple child profiles under one parent account\n• Share tests with friends via unique codes\n• Beautiful LaTeX math rendering\n• Timed or untimed test modes\n\nPerfect for:\n• Daily math practice\n• Exam preparation\n• Identifying weak areas\n• Building math confidence\n\nFree tier includes 10 test generations per month. Premium unlocks unlimited tests.",
  };

  // Try to preserve existing listing text if available
  try {
    const existingRes = await client.request({
      url: `${API_BASE}/${PACKAGE_NAME}/edits/${editId}/listings/en-US`,
      method: "GET",
    });
    const existing = existingRes.data;
    if (existing.title) {
      listingData = {
        language: "en-US",
        title: existing.title,
        shortDescription: existing.shortDescription || listingData.shortDescription,
        fullDescription: existing.fullDescription || listingData.fullDescription,
      };
      console.log(`   Found existing listing: "${existing.title}"`);
    }
  } catch (err) {
    console.log("   No existing listing found, creating new one.");
  }

  await client.request({
    url: `${API_BASE}/${PACKAGE_NAME}/edits/${editId}/listings/en-US`,
    method: "PUT",
    data: listingData,
  });
  console.log("   ✅ Store listing set!\n");

  // Commit
  console.log("✅ Committing edit...");
  await client.request({
    url: `${API_BASE}/${PACKAGE_NAME}/edits/${editId}:commit`,
    method: "POST",
  });

  console.log("\n🎉 Store listing updated successfully!\n");
}

main().catch((err) => {
  console.error("\n❌ Update failed:", err.message || err);
  if (err.response?.data) {
    console.error("   API response:", JSON.stringify(err.response.data, null, 2));
  }
  process.exit(1);
});
