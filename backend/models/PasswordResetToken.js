const mongoose = require('mongoose');

const passwordResetTokenSchema = new mongoose.Schema({
  uid:       { type: String, required: true },
  email:     { type: String, required: true, lowercase: true, trim: true },
  token:     { type: String, required: true, unique: true },
  expiresAt: { type: Date, required: true },
  used:      { type: Boolean, default: false },
});

// MongoDB TTL: auto-delete documents after they expire
passwordResetTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('PasswordResetToken', passwordResetTokenSchema);
