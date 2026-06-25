const Follow = require('../models/Follow');
const User = require('../models/User');
const { ApiError } = require('../utils/ApiError');
const { toJson: userToJson } = require('./userController');
const { notify } = require('./notificationController');

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

  const actor = await User.findById(req.uid);
  await notify({
    recipientId: followingId,
    actorId: req.uid,
    actorUsername: actor.username,
    actorPhotoUrl: actor.photoUrl,
    type: 'follow',
  });

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

// Resolves a page of Follow edges (newest first) into the User documents on
// the other end, preserving follow order. Skip/limit rather than a
// createdAt cursor since the response is plain user profiles with no
// follow-edge timestamp to hand back as a cursor.
async function resolveFollowPage(query, { page, limit }) {
  const follows = await Follow.find(query)
    .sort({ createdAt: -1 })
    .skip(page * limit)
    .limit(limit);
  if (follows.length === 0) return [];

  const idField = query.followingId ? 'followerId' : 'followingId';
  const userIds = follows.map((f) => f[idField]);
  const users = await User.find({ _id: { $in: userIds } });
  const usersById = new Map(users.map((u) => [u._id, u]));
  return follows.map((f) => usersById.get(f[idField])).filter(Boolean);
}

function parsePageParams(req) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const page = Math.max(parseInt(req.query.page, 10) || 0, 0);
  return { page, limit };
}

// GET /api/users/:uid/followers?page=&limit= — accounts following :uid.
async function getFollowers(req, res) {
  const users = await resolveFollowPage(
    { followingId: req.params.uid },
    parsePageParams(req),
  );
  res.json(users.map(userToJson));
}

// GET /api/users/:uid/following?page=&limit= — accounts :uid follows.
async function getFollowing(req, res) {
  const users = await resolveFollowPage(
    { followerId: req.params.uid },
    parsePageParams(req),
  );
  res.json(users.map(userToJson));
}

module.exports = { follow, unfollow, isFollowing, getFollowers, getFollowing };
