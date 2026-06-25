const Notification = require('../models/Notification');
const Follow = require('../models/Follow');
const { ApiError } = require('../utils/ApiError');

// Not imported from postController to avoid a circular require — that
// module needs to call notify() from here, and Node resolves circular
// requires with whichever side loaded first, leaving the other with a
// stale/incomplete export.
function buildCursorQuery(baseQuery, cursor) {
  if (!cursor) return baseQuery;
  const date = new Date(cursor);
  if (Number.isNaN(date.getTime())) {
    throw new ApiError(400, 'cursor must be a valid ISO-8601 date string.');
  }
  return { ...baseQuery, createdAt: { $lt: date } };
}

function toJson(n) {
  return {
    notificationId: n._id.toString(),
    type: n.type,
    actorId: n.actorId,
    actorUsername: n.actorUsername,
    actorPhotoUrl: n.actorPhotoUrl,
    postId: n.postId ? n.postId.toString() : null,
    read: n.read,
    createdAt: n.createdAt,
  };
}

// Creates a notification for an action taken on another user's content (or
// on the user directly, for follows) — never for actions on your own
// content, so liking/commenting/reposting your own post stays silent.
// Failures here are logged, not thrown, so a notification glitch can never
// fail the like/comment/repost/follow request it's attached to.
async function notify({ recipientId, actorId, actorUsername, actorPhotoUrl, type, postId }) {
  if (recipientId === actorId) return;
  try {
    await Notification.create({ recipientId, actorId, actorUsername, actorPhotoUrl, type, postId });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[notify] failed to create notification:', err);
  }
}

// GET /api/notifications?type=&cursor=&limit=
async function getNotifications(req, res) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const baseQuery = { recipientId: req.uid };
  if (req.query.type) {
    baseQuery.type = req.query.type;
  }
  const query = buildCursorQuery(baseQuery, req.query.cursor);

  const notifications = await Notification.find(query).sort({ createdAt: -1 }).limit(limit);

  const followActorIds = [...new Set(notifications.filter((n) => n.type === 'follow').map((n) => n.actorId))];
  const follows =
    followActorIds.length === 0
      ? []
      : await Follow.find({ followerId: req.uid, followingId: { $in: followActorIds } }).select('followingId');
  const followingIds = new Set(follows.map((f) => f.followingId));

  res.json(
    notifications.map((n) => ({
      ...toJson(n),
      isFollowingActor: n.type === 'follow' ? followingIds.has(n.actorId) : null,
    })),
  );
}

// GET /api/notifications/unread-count
async function getUnreadCount(req, res) {
  const count = await Notification.countDocuments({ recipientId: req.uid, read: false });
  res.json({ count });
}

// POST /api/notifications/read — marks every notification for the caller as
// read; the client calls this when the notifications screen opens.
async function markAllRead(req, res) {
  await Notification.updateMany({ recipientId: req.uid, read: false }, { $set: { read: true } });
  res.status(204).end();
}

module.exports = { notify, getNotifications, getUnreadCount, markAllRead };
