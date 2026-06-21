const mongoose = require('mongoose');

const fcmTokenSchema = new mongoose.Schema(
  {
    token: { type: String, required: true },
    platform: { type: String, default: 'android' },
    createdAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

const userSchema = new mongoose.Schema({
  _id: { type: String, required: true }, // Firebase UID
  username: { type: String, required: true, unique: true, index: true },
  displayName: { type: String, default: '' },
  email: { type: String, default: '' },
  photoUrl: { type: String, default: '' },
  bio: { type: String, default: '' },
  followersCount: { type: Number, default: 0 },
  followingCount: { type: Number, default: 0 },
  postsCount: { type: Number, default: 0 },
  fcmTokens: { type: [fcmTokenSchema], default: [] },
  lastActiveAt: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);
