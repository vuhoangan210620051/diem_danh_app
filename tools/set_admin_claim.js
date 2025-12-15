/**
 * Node script to set `admin: true` custom claim on a Firebase user.
 *
 * Usage:
 * 1. Download a Service Account JSON from Firebase Console (Project Settings -> Service accounts)
 * 2. Place it next to this script as `serviceAccountKey.json` (or update the path below)
 * 3. Run: `node tools/set_admin_claim.js <USER_UID>`
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Prefer serviceAccountKey.json in project root (process.cwd()),
// fall back to script directory.
const svcPathCandidate = [
    path.join(process.cwd(), 'serviceAccountKey.json'),
    path.join(__dirname, '../serviceAccountKey.json'),
    path.join(__dirname, 'serviceAccountKey.json'),
];

let svcPath = null;
for (const p of svcPathCandidate) {
    if (fs.existsSync(p)) {
        svcPath = p;
        break;
    }
}

if (!svcPath) {
    console.error('serviceAccountKey.json not found. Download it from Firebase Console and place it in the project root.');
    process.exit(1);
}

admin.initializeApp({
    credential: admin.credential.cert(require(svcPath)),
});

const uid = process.argv[2];
if (!uid) {
    console.error('Usage: node tools/set_admin_claim.js <USER_UID>');
    process.exit(1);
}

admin.auth().setCustomUserClaims(uid, { admin: true })
    .then(() => console.log(`Custom claim set for uid=${uid}`))
    .catch(err => {
        console.error('Failed to set claim:', err);
        process.exit(1);
    });
