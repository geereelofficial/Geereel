const Chat = require('../models/Chat');
const { persistMessage } = require('../controllers/chatController');

function registerChatHandlers(io, socket) {
  socket.on('join_chat', async ({ chatId }) => {
    if (!chatId) return;
    const chat = await Chat.findById(chatId);
    if (!chat || !chat.participantIds.includes(socket.uid)) {
      socket.emit('chat_error', { message: 'Chat not found.' });
      return;
    }
    socket.join(`chat:${chatId}`);
  });

  socket.on('leave_chat', ({ chatId }) => {
    if (!chatId) return;
    socket.leave(`chat:${chatId}`);
  });

  socket.on('send_message', async ({ chatId, text }) => {
    if (!chatId || !text || !text.trim()) {
      socket.emit('chat_error', { message: 'chatId and text are required.' });
      return;
    }

    try {
      const { message, recipientId } = await persistMessage({
        chatId,
        senderId: socket.uid,
        text: text.trim(),
      });

      io.to(`chat:${chatId}`).emit('new_message', message);
      if (recipientId) {
        io.to(`user:${recipientId}`).emit('new_message', message);
      }
    } catch (err) {
      socket.emit('chat_error', { message: err.message || 'Failed to send message.' });
    }
  });
}

module.exports = { registerChatHandlers };
