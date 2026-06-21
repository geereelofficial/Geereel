const admin = require('../config/firebaseAdmin');
const User = require('../models/User');
const Chat = require('../models/Chat');
const presence = require('../utils/presence');
const { registerChatHandlers } = require('./chatSocket');

// Tells every account that shares a chat with [uid] that their online state
// changed, so chat lists/screens update live without polling. Scoped to
// chat partners (not a global broadcast) and a single indexed query
// regardless of how many users are on the server.
async function broadcastPresence(io, uid, online, lastActiveAt) {
  const chats = await Chat.find({ participantIds: uid }).select('participantIds');
  const partnerIds = new Set();
  for (const chat of chats) {
    for (const id of chat.participantIds) {
      if (id !== uid) partnerIds.add(id);
    }
  }
  for (const partnerId of partnerIds) {
    io.to(`user:${partnerId}`).emit('presence_update', { uid, online, lastActiveAt });
  }
}

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

    presence.markOnline(socket.uid);
    broadcastPresence(io, socket.uid, true, null).catch(() => {});

    socket.on('disconnect', async () => {
      if (!presence.markOffline(socket.uid)) return; // another socket for this uid is still open

      const lastActiveAt = new Date();
      try {
        await User.updateOne({ _id: socket.uid }, { $set: { lastActiveAt } });
        await broadcastPresence(io, socket.uid, false, lastActiveAt);
      } catch {
        // Best-effort — a failed presence broadcast shouldn't crash the socket server.
      }
    });
  });
}

module.exports = { initSockets };
