const mongoose = require('mongoose');

const repostSchema = new mongoose.Schema({
  postId: { type: mongoose.Schema.Types.ObjectId, ref: 'Post', required: true },
  uid: { type: String, required: true },
  // Optional quote text, like Twitter/X's "Quote" repost — empty for a
  // plain repost.
  comment: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now },
});

repostSchema.index({ postId: 1, uid: 1 }, { unique: true });
repostSchema.index({ uid: 1 });

module.exports = mongoose.model('Repost', repostSchema);
