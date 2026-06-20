const Post = require('../models/Post');
const Like = require('../models/Like');
const Bookmark = require('../models/Bookmark');
const Repost = require('../models/Repost');
const User = require('../models/User');
const Follow = require('../models/Follow');
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
    bookmarksCount: post.bookmarksCount,
    repostsCount: post.repostsCount,
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

// GET /api/posts/following?cursor=&limit= — posts authored by accounts the
// caller follows, reverse-chronological. Empty list if following no one.
async function getFollowingFeed(req, res) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const follows = await Follow.find({ followerId: req.uid }).select('followingId');
  const followingIds = follows.map((f) => f.followingId);

  if (followingIds.length === 0) {
    return res.json([]);
  }

  const query = buildCursorQuery(
    { authorId: { $in: followingIds }, status: 'published' },
    req.query.cursor,
  );

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

// GET /api/posts/:postId/bookmarked
async function getBookmarked(req, res) {
  const bookmark = await Bookmark.findOne({ postId: req.params.postId, uid: req.uid });
  res.json({ bookmarked: !!bookmark });
}

// POST /api/posts/:postId/bookmark
async function bookmark(req, res) {
  const postId = req.params.postId;

  const post = await Post.findById(postId);
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }

  try {
    await Bookmark.create({ postId, uid: req.uid });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(204).end(); // already bookmarked — idempotent
    }
    throw err;
  }

  await Post.updateOne({ _id: postId }, { $inc: { bookmarksCount: 1 } });
  res.status(204).end();
}

// DELETE /api/posts/:postId/bookmark
async function unbookmark(req, res) {
  const postId = req.params.postId;
  const deleted = await Bookmark.findOneAndDelete({ postId, uid: req.uid });
  if (deleted) {
    await Post.updateOne({ _id: postId }, { $inc: { bookmarksCount: -1 } });
  }
  res.status(204).end();
}

// GET /api/posts/:postId/reposted
async function getReposted(req, res) {
  const repost = await Repost.findOne({ postId: req.params.postId, uid: req.uid });
  res.json({ reposted: !!repost });
}

// POST /api/posts/:postId/repost
async function repost(req, res) {
  const postId = req.params.postId;

  const post = await Post.findById(postId);
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }

  try {
    await Repost.create({ postId, uid: req.uid });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(204).end(); // already reposted — idempotent
    }
    throw err;
  }

  await Post.updateOne({ _id: postId }, { $inc: { repostsCount: 1 } });
  res.status(204).end();
}

// DELETE /api/posts/:postId/repost
async function unrepost(req, res) {
  const postId = req.params.postId;
  const deleted = await Repost.findOneAndDelete({ postId, uid: req.uid });
  if (deleted) {
    await Post.updateOne({ _id: postId }, { $inc: { repostsCount: -1 } });
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
  getFollowingFeed,
  getUserPosts,
  createPost,
  getLiked,
  like,
  unlike,
  getBookmarked,
  bookmark,
  unbookmark,
  getReposted,
  repost,
  unrepost,
  share,
  view,
};
