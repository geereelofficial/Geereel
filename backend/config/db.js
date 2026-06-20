const mongoose = require('mongoose');
const dns = require('dns');

// The default OS resolver on this machine is unreliable for the SRV lookup
// mongodb+srv:// needs (intermittent ETIMEOUT/ECONNREFUSED) — point Node at
// public resolvers instead.
dns.setServers(['8.8.8.8', '1.1.1.1']);

async function connectDb() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI is not set in the environment.');
  }

  mongoose.connection.on('connected', () => console.log('[db] connected'));
  mongoose.connection.on('error', (err) => console.error('[db] connection error:', err.message));

  await mongoose.connect(uri);
}

module.exports = { connectDb };
