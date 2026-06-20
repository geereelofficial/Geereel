const User = require('../models/User');
const { ApiError } = require('../utils/ApiError');

function toJson(user) {
  return {
    uid: user._id,
    username: user.username,
    displayName: user.displayName,
    email: user.email,
    photoUrl: user.photoUrl,
    bio: user.bio,
    followersCount: user.followersCount,
    followingCount: user.followingCount,
    postsCount: user.postsCount,
    createdAt: user.createdAt,
  };
}

// POST /api/users — create-or-fetch the caller's own profile.
async function createOrFetchProfile(req, res) {
  const existing = await User.findById(req.uid);
  if (existing) {
    return res.json(toJson(existing));
  }

  const { username, displayName } = req.body;
  if (!username || !displayName) {
    throw new ApiError(400, 'username and displayName are required.');
  }

  const taken = await User.findOne({ username });
  if (taken) {
    throw new ApiError(409, 'That username is already taken.');
  }

  const user = await User.create({
    _id: req.uid,
    username,
    displayName,
    email: req.firebaseUser.email || '',
    photoUrl: req.firebaseUser.picture || '',
  });

  res.status(201).json(toJson(user));
}

// GET /api/users/:uid
async function getProfile(req, res) {
  const user = await User.findById(req.params.uid);
  if (!user) {
    throw new ApiError(404, 'User not found.');
  }
  res.json(toJson(user));
}

// PATCH /api/users/:uid — self only.
async function updateProfile(req, res) {
  if (req.params.uid !== req.uid) {
    throw new ApiError(403, 'You can only update your own profile.');
  }

  const { displayName, bio } = req.body;
  const updates = {};
  if (displayName !== undefined) updates.displayName = displayName;
  if (bio !== undefined) updates.bio = bio;

  const user = await User.findByIdAndUpdate(req.uid, updates, { new: true });
  if (!user) {
    throw new ApiError(404, 'User not found.');
  }
  res.json(toJson(user));
}

// GET /api/users/username-available?username=
async function usernameAvailable(req, res) {
  const { username } = req.query;
  if (!username) {
    throw new ApiError(400, 'username query param is required.');
  }
  const existing = await User.findOne({ username });
  res.json({ available: !existing });
}

// POST /api/users/:uid/avatar — self only. {photoUrl} already uploaded to Cloudinary.
async function setAvatar(req, res) {
  if (req.params.uid !== req.uid) {
    throw new ApiError(403, 'You can only update your own avatar.');
  }

  const { photoUrl } = req.body;
  if (!photoUrl) {
    throw new ApiError(400, 'photoUrl is required.');
  }

  const user = await User.findByIdAndUpdate(req.uid, { photoUrl }, { new: true });
  if (!user) {
    throw new ApiError(404, 'User not found.');
  }
  res.json(toJson(user));
}

// POST /api/users/:uid/fcm-tokens — self only. {token, platform}
async function addFcmToken(req, res) {
  if (req.params.uid !== req.uid) {
    throw new ApiError(403, 'You can only register tokens for yourself.');
  }

  const { token, platform } = req.body;
  if (!token) {
    throw new ApiError(400, 'token is required.');
  }

  await User.updateOne({ _id: req.uid }, { $pull: { fcmTokens: { token } } });
  await User.updateOne(
    { _id: req.uid },
    { $push: { fcmTokens: { token, platform: platform || 'android', createdAt: new Date() } } },
  );

  res.status(204).end();
}

// DELETE /api/users/:uid/fcm-tokens/:token — self only.
async function removeFcmToken(req, res) {
  if (req.params.uid !== req.uid) {
    throw new ApiError(403, 'You can only remove tokens for yourself.');
  }

  await User.updateOne({ _id: req.uid }, { $pull: { fcmTokens: { token: req.params.token } } });
  res.status(204).end();
}

module.exports = {
  toJson,
  createOrFetchProfile,
  getProfile,
  updateProfile,
  usernameAvailable,
  setAvatar,
  addFcmToken,
  removeFcmToken,
};
