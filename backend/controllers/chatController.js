const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');
const { ApiError } = require('../utils/ApiError');

function chatIdFor(uidA, uidB) {
  return [uidA, uidB].sort().join('_');
}

function mapToPlainObject(map) {
  if (!map) return {};
  return map instanceof Map ? Object.fromEntries(map) : map;
}

function toJson(chat) {
  return {
    chatId: chat._id,
    participantIds: chat.participantIds,
    participantInfo: mapToPlainObject(chat.participantInfo),
    lastMessage: chat.lastMessage && chat.lastMessage.createdAt ? chat.lastMessage : null,
    unreadCount: mapToPlainObject(chat.unreadCount),
    createdAt: chat.createdAt,
  };
}

function messageToJson(message) {
  return {
    messageId: message._id.toString(),
    chatId: message.chatId,
    senderId: message.senderId,
    text: message.text,
    type: message.type,
    createdAt: message.createdAt,
  };
}

// GET /api/chats — all chats the caller participates in.
async function listChats(req, res) {
  const chats = await Chat.find({ participantIds: req.uid }).sort({ lastMessageAt: -1 });
  res.json(chats.map(toJson));
}

// POST /api/chats — {otherUid} -> {chatId}. Other side's info looked up server-side.
async function getOrCreateChat(req, res) {
  const { otherUid } = req.body;
  if (!otherUid) {
    throw new ApiError(400, 'otherUid is required.');
  }
  if (otherUid === req.uid) {
    throw new ApiError(400, 'Cannot start a chat with yourself.');
  }

  const [me, other] = await Promise.all([User.findById(req.uid), User.findById(otherUid)]);
  if (!me || !other) {
    throw new ApiError(404, 'User not found.');
  }

  const chatId = chatIdFor(req.uid, otherUid);

  const chat = await Chat.findOneAndUpdate(
    { _id: chatId },
    {
      $setOnInsert: {
        _id: chatId,
        participantIds: [req.uid, otherUid],
        participantInfo: {
          [req.uid]: { username: me.username, photoUrl: me.photoUrl },
          [otherUid]: { username: other.username, photoUrl: other.photoUrl },
        },
        lastMessage: null,
        unreadCount: { [req.uid]: 0, [otherUid]: 0 },
        lastMessageAt: new Date(),
        createdAt: new Date(),
      },
    },
    { upsert: true, new: true },
  );

  res.json({ chatId: chat._id });
}

// GET /api/chats/:chatId/messages?cursor=&limit=
async function getMessages(req, res) {
  const { chatId } = req.params;

  const chat = await Chat.findById(chatId);
  if (!chat || !chat.participantIds.includes(req.uid)) {
    throw new ApiError(404, 'Chat not found.');
  }

  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const query = { chatId };
  if (req.query.cursor) {
    const date = new Date(req.query.cursor);
    if (Number.isNaN(date.getTime())) {
      throw new ApiError(400, 'cursor must be a valid ISO-8601 date string.');
    }
    query.createdAt = { $lt: date };
  }

  const messages = await Message.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(messages.map(messageToJson));
}

// POST /api/chats/:chatId/read
async function markAsRead(req, res) {
  const { chatId } = req.params;
  const chat = await Chat.findById(chatId);
  if (!chat || !chat.participantIds.includes(req.uid)) {
    throw new ApiError(404, 'Chat not found.');
  }

  await Chat.updateOne({ _id: chatId }, { $set: { [`unreadCount.${req.uid}`]: 0 } });
  res.status(204).end();
}

// Shared by the Socket.io layer: persists a message and updates the chat's
// denormalized lastMessage/unreadCount, mirroring the old Firestore batch write.
async function persistMessage({ chatId, senderId, text }) {
  const chat = await Chat.findById(chatId);
  if (!chat || !chat.participantIds.includes(senderId)) {
    throw new ApiError(404, 'Chat not found.');
  }

  const recipientId = chat.participantIds.find((id) => id !== senderId);
  const createdAt = new Date();

  const message = await Message.create({ chatId, senderId, text, type: 'text', createdAt });

  const update = {
    lastMessage: { text, senderId, createdAt },
    lastMessageAt: createdAt,
  };
  await Chat.updateOne(
    { _id: chatId },
    {
      $set: update,
      ...(recipientId ? { $inc: { [`unreadCount.${recipientId}`]: 1 } } : {}),
    },
  );

  return { message: messageToJson(message), recipientId };
}

module.exports = {
  toJson,
  messageToJson,
  chatIdFor,
  listChats,
  getOrCreateChat,
  getMessages,
  markAsRead,
  persistMessage,
};
