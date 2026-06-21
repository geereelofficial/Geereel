const mongoose = require('mongoose');

// 24h-ephemeral story-style post. `expiresAt` carries a TTL index so Mongo
// itself purges expired documents — no cron job or app-level cleanup needed.
const statusSchema = new mongoose.Schema({
  authorId: { type: String, required: true, index: true },
  authorUsername: { type: String, required: true },
  authorPhotoUrl: { type: String, default: '' },
  mediaType: { type: String, enum: ['video', 'image'], required: true },
  mediaUrl: { type: String, required: true },
  thumbnailUrl: { type: String, default: '' },
  durationSeconds: { type: Number, default: 0 },
  width: { type: Number, default: 0 },
  height: { type: Number, default: 0 },
  viewsCount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  expiresAt: { type: Date, required: true },
});

statusSchema.index({ authorId: 1, expiresAt: 1 });
statusSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('Status', statusSchema);
