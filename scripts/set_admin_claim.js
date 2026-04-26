/**
 * set_admin_claim.js
 * 
 * Creates the super admin user (if not exists) and sets the `superAdmin: true`
 * custom claim on Firebase Auth for hillstechadmin@spotsence.com
 * 
 * Usage:
 *   node set_admin_claim.js <path-to-service-account.json>
 * 
 * Example:
 *   node set_admin_claim.js ./serviceAccount.json
 */

const admin = require('firebase-admin');
const path = require('path');

// ──────────────────────────────────────────────
// Config
// ──────────────────────────────────────────────
const ADMIN_EMAIL    = 'hillstechadmin@spotsence.com';
const ADMIN_PASSWORD = '#HillsTech2026#';
const PROJECT_ID     = 'xplooria-de44c';

// ──────────────────────────────────────────────
// Init
// ──────────────────────────────────────────────
const serviceAccountPath = process.argv[2];

if (!serviceAccountPath) {
  console.error('\n❌  Usage: node set_admin_claim.js <path-to-service-account.json>\n');
  console.error('   Download your service account key from:');
  console.error('   Firebase Console → Project Settings → Service Accounts → Generate new private key\n');
  process.exit(1);
}

const serviceAccount = require(path.resolve(serviceAccountPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: PROJECT_ID,
});

const auth = admin.auth();
const db   = admin.firestore();

// ──────────────────────────────────────────────
// Main
// ──────────────────────────────────────────────
async function run() {
  console.log(`\n🔧  Setting up super admin for project: ${PROJECT_ID}`);
  console.log(`📧  Email: ${ADMIN_EMAIL}\n`);

  let uid;

  // 1. Get or create the Auth user
  try {
    const existing = await auth.getUserByEmail(ADMIN_EMAIL);
    uid = existing.uid;
    console.log(`✅  Auth user already exists — UID: ${uid}`);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.log(`📝  User not found — creating...`);
      const newUser = await auth.createUser({
        email:         ADMIN_EMAIL,
        password:      ADMIN_PASSWORD,
        displayName:   'Super Admin',
        emailVerified: true,
      });
      uid = newUser.uid;
      console.log(`✅  Auth user created — UID: ${uid}`);
    } else {
      throw err;
    }
  }

  // 2. Set the custom claim
  await auth.setCustomUserClaims(uid, { superAdmin: true });
  console.log(`✅  Custom claim set: { superAdmin: true }`);

  // 3. Verify the claim was written
  const updated = await auth.getUser(uid);
  console.log(`🔍  Verified claims: ${JSON.stringify(updated.customClaims)}`);

  // 4. Upsert the Firestore admin document
  const adminRef = db.collection('app_admins').doc(uid);
  const snap = await adminRef.get();

  if (!snap.exists) {
    await adminRef.set({
      uid,
      email:       ADMIN_EMAIL,
      displayName: 'Super Admin',
      role:        'superAdmin',
      permissions: {
        canManageSpots:       true,
        canManageListings:    true,
        canManageEvents:      true,
        canManageVentures:    true,
        canManageUsers:       true,
        canViewAnalytics:     true,
        canManageCommunity:   true,
        canManageAdmins:      true,
      },
      isActive:    true,
      createdAt:   admin.firestore.FieldValue.serverTimestamp(),
      lastLogin:   admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`✅  Firestore app_admins/${uid} document created`);
  } else {
    await adminRef.update({ lastLogin: admin.firestore.FieldValue.serverTimestamp() });
    console.log(`ℹ️   Firestore app_admins/${uid} document already exists — updated lastLogin`);
  }

  console.log('\n🎉  Super admin setup complete!\n');
  console.log(`   Email:    ${ADMIN_EMAIL}`);
  console.log(`   Password: #HillsTech2026#`);
  console.log(`   UID:      ${uid}`);
  console.log(`   Claim:    { superAdmin: true }\n`);
  console.log('   You can now sign in through the app with the above credentials.\n');

  process.exit(0);
}

run().catch(err => {
  console.error('\n❌  Error:', err.message);
  process.exit(1);
});
