const Status = require('../models/Status');
const StatusView = require('../models/StatusView');
const Follow = require('../models/Follow');
const User = require('../models/User');
const { ApiError } = require('../utils/ApiError');

const STATUS_LIFETIME_MS = 24 * 60 * 60 * 1000;

function toJson(status) {
  return {
    statusId: status._id.toString(),
    authorId: status.authorId,
    authorUsername: status.authorUsername,
    authorPhotoUrl: status.authorPhotoUrl,
    mediaType: status.mediaType,
    mediaUrl: status.mediaUrl,
    thumbnailUrl: status.thumbnailUrl,
    durationSeconds: status.durationSeconds,
    width: status.width,
    height: status.height,
    viewsCount: status.viewsCount,
    createdAt: status.createdAt,
    expiresAt: status.expiresAt,
  };
}

async function isAuthorizedToView(viewerId, authorId) {
  if (viewerId === authorId) return true;
  const follow = await Follow.findOne({ followerId: viewerId, followingId: authorId }).select('_id');
  return !!follow;
}

// POST /api/statuses — {mediaType, mediaUrl, thumbnailUrl?, durationSeconds?, width?, height?}
async function createStatus(req, res) {
  const { mediaType, mediaUrl, thumbnailUrl, durationSeconds, width, height } = req.body;

  if (!mediaType || !mediaUrl) {
    throw new ApiError(400, 'mediaType and mediaUrl are required.');
  }
  if (!['video', 'image'].includes(mediaType)) {
    throw new ApiError(400, "mediaType must be 'video' or 'image'.");
  }

  const author = await User.findById(req.uid);
  if (!author) {
    throw new ApiError(404, 'User profile not found.');
  }

  const now = new Date();
  const status = await Status.create({
    authorId: req.uid,
    authorUsername: author.username,
    authorPhotoUrl: author.photoUrl,
    mediaType,
    mediaUrl,
    thumbnailUrl: thumbnailUrl || '',
    durationSeconds: durationSeconds || 0,
    width: width || 0,
    height: height || 0,
    createdAt: now,
    expiresAt: new Date(now.getTime() + STATUS_LIFETIME_MS),
  });

  res.status(201).json(toJson(status));
}

// GET /api/statuses — the tray: the caller's own active statuses plus those
// of everyone they follow, grouped by author. Three queries total
// (following ids, statuses, viewed-by-me ids) regardless of how many
// authors/statuses are active, so this stays flat as the userbase grows.
async function getTray(req, res) {
  const follows = await Follow.find({ followerId: req.uid }).select('followingId');
  const authorIds = [...new Set([req.uid, ...follows.map((f) => f.followingId)])];

  const statuses = await Status.find({
    authorId: { $in: authorIds },
    expiresAt: { $gt: new Date() },
  }).sort({ createdAt: 1 });

  if (statuses.length === 0) {
    return res.json([]);
  }

  const statusIds = statuses.map((s) => s._id);
  const views = await StatusView.find({ viewerId: req.uid, statusId: { $in: statusIds } }).select(
    'statusId',
  );
  const viewedIds = new Set(views.map((v) => v.statusId.toString()));

  const groupsByAuthor = new Map();
  for (const status of statuses) {
    if (!groupsByAuthor.has(status.authorId)) {
      groupsByAuthor.set(status.authorId, {
        authorId: status.authorId,
        authorUsername: status.authorUsername,
        authorPhotoUrl: status.authorPhotoUrl,
        statuses: [],
        hasUnviewed: false,
        latestAt: status.createdAt,
      });
    }
    const group = groupsByAuthor.get(status.authorId);
    const viewed = viewedIds.has(status._id.toString());
    group.statuses.push({ ...toJson(status), viewed });
    if (!viewed) group.hasUnviewed = true;
    if (status.createdAt > group.latestAt) group.latestAt = status.createdAt;
  }

  const groups = [...groupsByAuthor.values()];
  groups.sort((a, b) => {
    if (a.authorId === req.uid) return -1;
    if (b.authorId === req.uid) return 1;
    if (a.hasUnviewed !== b.hasUnviewed) return a.hasUnviewed ? -1 : 1;
    return b.latestAt - a.latestAt;
  });

  res.json(groups.map(({ latestAt, ...group }) => group));
}

// GET /api/statuses/user/:authorId — one author's active statuses, with
// per-status `viewed` flags for the caller. 403s if the caller doesn't
// follow the author (and isn't the author), matching the tray's visibility.
async function getUserStatuses(req, res) {
  const { authorId } = req.params;

  if (!(await isAuthorizedToView(req.uid, authorId))) {
    throw new ApiError(403, 'You must follow this user to view their status.');
  }

  const statuses = await Status.find({ authorId, expiresAt: { $gt: new Date() } }).sort({
    createdAt: 1,
  });

  if (statuses.length === 0) {
    return res.json([]);
  }

  const statusIds = statuses.map((s) => s._id);
  const views = await StatusView.find({ viewerId: req.uid, statusId: { $in: statusIds } }).select(
    'statusId',
  );
  const viewedIds = new Set(views.map((v) => v.statusId.toString()));

  res.json(statuses.map((status) => ({ ...toJson(status), viewed: viewedIds.has(status._id.toString()) })));
}

// POST /api/statuses/:statusId/view
async function viewStatus(req, res) {
  const { statusId } = req.params;

  const status = await Status.findById(statusId);
  if (!status) {
    throw new ApiError(404, 'Status not found.');
  }
  if (!(await isAuthorizedToView(req.uid, status.authorId))) {
    throw new ApiError(403, 'You must follow this user to view their status.');
  }

  const viewer = await User.findById(req.uid);

  try {
    await StatusView.create({
      statusId,
      viewerId: req.uid,
      viewerUsername: viewer ? viewer.username : '',
      viewerPhotoUrl: viewer ? viewer.photoUrl : '',
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(204).end(); // already viewed — idempotent
    }
    throw err;
  }

  await Status.updateOne({ _id: statusId }, { $inc: { viewsCount: 1 } });
  res.status(204).end();
}

// GET /api/statuses/:statusId/viewers — owner-only.
async function getViewers(req, res) {
  const { statusId } = req.params;

  const status = await Status.findById(statusId).select('authorId');
  if (!status) {
    throw new ApiError(404, 'Status not found.');
  }
  if (status.authorId !== req.uid) {
    throw new ApiError(403, 'Only the author can see who viewed this status.');
  }

  const views = await StatusView.find({ statusId }).sort({ viewedAt: -1 });
  res.json(
    views.map((v) => ({
      uid: v.viewerId,
      username: v.viewerUsername,
      photoUrl: v.viewerPhotoUrl,
      viewedAt: v.viewedAt,
    })),
  );
}

// DELETE /api/statuses/:statusId — owner-only early removal.
async function deleteStatus(req, res) {
  const { statusId } = req.params;

  const status = await Status.findById(statusId).select('authorId');
  if (!status) {
    throw new ApiError(404, 'Status not found.');
  }
  if (status.authorId !== req.uid) {
    throw new ApiError(403, 'You can only delete your own status.');
  }

  await Promise.all([Status.deleteOne({ _id: statusId }), StatusView.deleteMany({ statusId })]);
  res.status(204).end();
}

module.exports = {
  createStatus,
  getTray,
  getUserStatuses,
  viewStatus,
  getViewers,
  deleteStatus,
};
