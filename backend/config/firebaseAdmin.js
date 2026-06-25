const admin = require('firebase-admin');
const path = require('path');

let credential;
if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  credential = admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON));
} else {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './config/firebase-service-account.json';
  credential = admin.credential.cert(require(path.resolve(serviceAccountPath)));
}

admin.initializeApp({ credential });

module.exports = admin;
