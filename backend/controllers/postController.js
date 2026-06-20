const Post = require('../models/Post');
const Like = require('../models/Like');
const User = require('../models/User');
const { ApiError } = require('../utils/ApiError');

function toJson(post) {
  return {
    postId: post._id.toString(),
    authorId: post.authorId,
    authorUsername: post.authorUsername,
    authorPhotoUrl: post.authorPhotoUrl,
    mediaType: post.mediaType,
    mediaUrl: post.mediaUrl,
    thumbnailUrl: post.thumbnailUrl,
    caption: post.caption,
    likesCount: post.likesCount,
    commentsCount: post.commentsCount,
    sharesCount: post.sharesCount,
    viewsCount: post.viewsCount,
    durationSeconds: post.durationSeconds,
    width: post.width,
    height: post.height,
    status: post.status,
    createdAt: post.createdAt,
  };
}

function buildCursorQuery(baseQuery, cursor) {
  if (!cursor) return baseQuery;
  const date = new Date(cursor);
  if (Number.isNaN(date.getTime())) {
    throw new ApiError(400, 'cursor must be a valid ISO-8601 date string.');
  }
  return { ...baseQuery, createdAt: { $lt: date } };
}

// GET /api/posts/feed?cursor=&limit=
async function getFeed(req, res) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const query = buildCursorQuery({ status: 'published' }, req.query.cursor);

  const posts = await Post.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(posts.map(toJson));
}

// GET /api/posts/user/:authorId?cursor=&limit=
async function getUserPosts(req, res) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const query = buildCursorQuery(
    { authorId: req.params.authorId, status: 'published' },
    req.query.cursor,
  );

  const posts = await Post.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(posts.map(toJson));
}

// POST /api/posts — author fields derived server-side from req.uid.
async function createPost(req, res) {
  const { mediaType, mediaUrl, thumbnailUrl, caption, durationSeconds, width, height } = req.body;

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

  const post = await Post.create({
    authorId: req.uid,
    authorUsername: author.username,
    authorPhotoUrl: author.photoUrl,
    mediaType,
    mediaUrl,
    thumbnailUrl: thumbnailUrl || '',
    caption: caption || '',
    durationSeconds: durationSeconds || 0,
    width: width || 0,
    height: height || 0,
  });

  await User.updateOne({ _id: req.uid }, { $inc: { postsCount: 1 } });

  res.status(201).json(toJson(post));
}

// GET /api/posts/:postId/liked
async function getLiked(req, res) {
  const like = await Like.findOne({ postId: req.params.postId, uid: req.uid });
  res.json({ liked: !!like });
}

// POST /api/posts/:postId/like
async function like(req, res) {
  const postId = req.params.postId;

  const post = await Post.findById(postId);
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }

  try {
    await Like.create({ postId, uid: req.uid });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(204).end(); // already liked — idempotent
    }
    throw err;
  }

  await Post.updateOne({ _id: postId }, { $inc: { likesCount: 1 } });
  res.status(204).end();
}

// DELETE /api/posts/:postId/like
async function unlike(req, res) {
  const postId = req.params.postId;
  const deleted = await Like.findOneAndDelete({ postId, uid: req.uid });
  if (deleted) {
    await Post.updateOne({ _id: postId }, { $inc: { likesCount: -1 } });
  }
  res.status(204).end();
}

// POST /api/posts/:postId/share
async function share(req, res) {
  const post = await Post.findByIdAndUpdate(
    req.params.postId,
    { $inc: { sharesCount: 1 } },
    { new: true },
  );
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }
  res.status(204).end();
}

// POST /api/posts/:postId/view
async function view(req, res) {
  const post = await Post.findByIdAndUpdate(
    req.params.postId,
    { $inc: { viewsCount: 1 } },
    { new: true },
  );
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }
  res.status(204).end();
}

module.exports = {
  toJson,
  getFeed,
  getUserPosts,
  createPost,
  getLiked,
  like,
  unlike,
  share,
  view,
};
