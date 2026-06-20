const admin = require('../config/firebaseAdmin');
const { registerChatHandlers } = require('./chatSocket');

function initSockets(io) {
  io.use(async (socket, next) => {
    const token = socket.handshake.auth && socket.handshake.auth.token;
    if (!token) {
      next(new Error('Missing auth token.'));
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      socket.uid = decoded.uid;
      next();
    } catch (err) {
      next(new Error('Invalid or expired auth token.'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(`user:${socket.uid}`);
    registerChatHandlers(io, socket);
  });
}

module.exports = { initSockets };
