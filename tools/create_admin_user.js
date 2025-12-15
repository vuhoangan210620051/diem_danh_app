const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// find serviceAccountKey.json in project root or script dir
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

const email = process.argv[2];
const password = process.argv[3];
if (!email || !password) {
    console.error('Usage: node tools/create_admin_user.js <email> <password>');
    process.exit(1);
}

console.log('Creating user', email);
admin.auth().createUser({ email, password })
    .then(userRecord => {
        const uid = userRecord.uid;
        console.log('User created uid=' + uid);
        return admin.auth().setCustomUserClaims(uid, { admin: true })
            .then(() => {
                console.log('Set admin claim for uid=' + uid);
                console.log('CREATED_UID:' + uid);
                process.exit(0);
            });
    })
    .catch(err => {
        console.error('Error creating user:', err);
        process.exit(1);
    });
