const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// resolve serviceAccountKey.json from project root or script locations
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
    console.error('serviceAccountKey.json not found. Place it in project root.');
    process.exit(1);
}

admin.initializeApp({
    credential: admin.credential.cert(require(svcPath)),
});

const uid = process.argv[2];
let password = process.argv[3];
if (!uid) {
    console.error('Usage: node tools/set_admin_password.js <UID> [password]');
    process.exit(1);
}

if (!password) {
    // generate a strong password
    const buf = crypto.randomBytes(12);
    // base64 -> replace non-url safe, then ensure length
    password = buf.toString('base64').replace(/[^A-Za-z0-9]/g, 'A').slice(0, 16);
}

admin.auth().updateUser(uid, { password })
    .then(userRecord => {
        console.log('Password updated for uid=' + uid);
        console.log('NEW_PASSWORD:' + password);
        process.exit(0);
    })
    .catch(err => {
        console.error('Failed to update password:', err);
        process.exit(1);
    });
