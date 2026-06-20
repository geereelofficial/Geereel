const Follow = require('../models/Follow');
const User = require('../models/User');
const { ApiError } = require('../utils/ApiError');

// POST /api/users/:uid/follow
async function follow(req, res) {
  const followingId = req.params.uid;
  if (followingId === req.uid) {
    throw new ApiError(400, 'You cannot follow yourself.');
  }

  const target = await User.findById(followingId);
  if (!target) {
    throw new ApiError(404, 'User not found.');
  }

  try {
    await Follow.create({ followerId: req.uid, followingId });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(204).end(); // already following — idempotent
    }
    throw err;
  }

  await Promise.all([
    User.updateOne({ _id: req.uid }, { $inc: { followingCount: 1 } }),
    User.updateOne({ _id: followingId }, { $inc: { followersCount: 1 } }),
  ]);

  res.status(204).end();
}

// DELETE /api/users/:uid/follow
async function unfollow(req, res) {
  const followingId = req.params.uid;
  const deleted = await Follow.findOneAndDelete({ followerId: req.uid, followingId });
  if (deleted) {
    await Promise.all([
      User.updateOne({ _id: req.uid }, { $inc: { followingCount: -1 } }),
      User.updateOne({ _id: followingId }, { $inc: { followersCount: -1 } }),
    ]);
  }
  res.status(204).end();
}

// GET /api/users/:uid/is-following
async function isFollowing(req, res) {
  const match = await Follow.findOne({ followerId: req.uid, followingId: req.params.uid });
  res.json({ following: !!match });
}

module.exports = { follow, unfollow, isFollowing };
