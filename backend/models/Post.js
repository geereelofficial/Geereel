const mongoose = require('mongoose');

const postSchema = new mongoose.Schema({
  authorId: { type: String, required: true, index: true },
  authorUsername: { type: String, required: true },
  authorPhotoUrl: { type: String, default: '' },
  mediaType: { type: String, enum: ['video', 'image'], required: true },
  mediaUrl: { type: String, required: true },
  thumbnailUrl: { type: String, default: '' },
  caption: { type: String, default: '' },
  likesCount: { type: Number, default: 0 },
  commentsCount: { type: Number, default: 0 },
  sharesCount: { type: Number, default: 0 },
  viewsCount: { type: Number, default: 0 },
  durationSeconds: { type: Number, default: 0 },
  width: { type: Number, default: 0 },
  height: { type: Number, default: 0 },
  status: { type: String, enum: ['processing', 'published', 'failed'], default: 'published' },
  createdAt: { type: Date, default: Date.now },
});

postSchema.index({ status: 1, createdAt: -1 });
postSchema.index({ authorId: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model('Post', postSchema);
