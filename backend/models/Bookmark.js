const mongoose = require('mongoose');

const bookmarkSchema = new mongoose.Schema({
  postId: { type: mongoose.Schema.Types.ObjectId, ref: 'Post', required: true },
  uid: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

bookmarkSchema.index({ postId: 1, uid: 1 }, { unique: true });

module.exports = mongoose.model('Bookmark', bookmarkSchema);
