const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

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
    console.error('serviceAccountKey.json not found.');
    process.exit(1);
}

admin.initializeApp({
    credential: admin.credential.cert(require(svcPath)),
});

const uid = process.argv[2];
if (!uid) {
    console.error('Usage: node tools/get_user_info.js <UID>');
    process.exit(1);
}

admin.auth().getUser(uid)
    .then(user => {
        console.log('UID:', user.uid);
        console.log('Email:', user.email);
        console.log('EmailVerified:', user.emailVerified);
        console.log('Disabled:', user.disabled);
        console.log('CustomClaims:', user.customClaims);
    })
    .catch(err => {
        console.error('Error fetching user:', err);
        process.exit(1);
    });
