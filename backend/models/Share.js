const mongoose = require('mongoose');

const shareSchema = new mongoose.Schema({
  postId: { type: mongoose.Schema.Types.ObjectId, ref: 'Post', required: true },
  uid: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

shareSchema.index({ postId: 1, uid: 1 }, { unique: true });
shareSchema.index({ uid: 1 });

module.exports = mongoose.model('Share', shareSchema);
