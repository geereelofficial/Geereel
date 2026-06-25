const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipientId: { type: String, required: true },
  actorId: { type: String, required: true },
  // Denormalized so the notification list never needs a per-item User
  // lookup — same trade-off as Post's authorUsername/authorPhotoUrl.
  actorUsername: { type: String, required: true },
  actorPhotoUrl: { type: String, default: '' },
  type: { type: String, enum: ['follow', 'like', 'comment', 'repost'], required: true },
  postId: { type: mongoose.Schema.Types.ObjectId, ref: 'Post' },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

notificationSchema.index({ recipientId: 1, createdAt: -1 });
notificationSchema.index({ recipientId: 1, type: 1, createdAt: -1 });
notificationSchema.index({ recipientId: 1, read: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
