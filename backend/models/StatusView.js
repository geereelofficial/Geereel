const mongoose = require('mongoose');

const statusViewSchema = new mongoose.Schema({
  statusId: { type: mongoose.Schema.Types.ObjectId, ref: 'Status', required: true },
  viewerId: { type: String, required: true },
  viewerUsername: { type: String, required: true },
  viewerPhotoUrl: { type: String, default: '' },
  viewedAt: { type: Date, default: Date.now },
});

statusViewSchema.index({ statusId: 1, viewerId: 1 }, { unique: true });
statusViewSchema.index({ statusId: 1, viewedAt: -1 });

module.exports = mongoose.model('StatusView', statusViewSchema);
