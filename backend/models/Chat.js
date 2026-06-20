const mongoose = require('mongoose');

const lastMessageSchema = new mongoose.Schema(
  {
    text: { type: String, default: '' },
    senderId: { type: String, default: '' },
    createdAt: { type: Date, default: null },
  },
  { _id: false },
);

const participantInfoSchema = new mongoose.Schema(
  {
    username: { type: String, default: '' },
    photoUrl: { type: String, default: '' },
  },
  { _id: false },
);

const chatSchema = new mongoose.Schema({
  _id: { type: String, required: true }, // sorted "uidA_uidB"
  participantIds: { type: [String], required: true, index: true },
  participantInfo: { type: Map, of: participantInfoSchema, default: {} },
  lastMessage: { type: lastMessageSchema, default: null },
  unreadCount: { type: Map, of: Number, default: {} },
  lastMessageAt: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now },
});

chatSchema.index({ participantIds: 1, lastMessageAt: -1 });

module.exports = mongoose.model('Chat', chatSchema);
