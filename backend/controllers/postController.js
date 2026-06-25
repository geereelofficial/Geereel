const Post = require('../models/Post');
const Like = require('../models/Like');
const Bookmark = require('../models/Bookmark');
const Repost = require('../models/Repost');
const Share = require('../models/Share');
const User = require('../models/User');
const Follow = require('../models/Follow');
const { ApiError } = require('../utils/ApiError');
const { notify } = require('./notificationController');

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

// Batches the viewer's liked/bookmarked/reposted/following state for a page
// of posts into one query per collection, instead of the client making four
// separate round trips per post (which is what made the feed feel slow).
async function attachViewerState(posts, uid) {
  if (posts.length === 0) return [];

  const postIds = posts.map((p) => p._id);
  const authorIds = [...new Set(posts.map((p) => p.authorId))];

  const [likes, bookmarks, reposts, follows] = await Promise.all([
    Like.find({ postId: { $in: postIds }, uid }).select('postId'),
    Bookmark.find({ postId: { $in: postIds }, uid }).select('postId'),
    Repost.find({ postId: { $in: postIds }, uid }).select('postId'),
    Follow.find({ followerId: uid, followingId: { $in: authorIds } }).select('followingId'),
  ]);

  const likedIds = new Set(likes.map((l) => l.postId.toString()));
  const bookmarkedIds = new Set(bookmarks.map((b) => b.postId.toString()));
  const repostedIds = new Set(reposts.map((r) => r.postId.toString()));
  const followedAuthorIds = new Set(follows.map((f) => f.followingId));

  return posts.map((post) => ({
    ...toJson(post),
    liked: likedIds.has(post._id.toString()),
    bookmarked: bookmarkedIds.has(post._id.toString()),
    reposted: repostedIds.has(post._id.toString()),
    isFollowingAuthor: followedAuthorIds.has(post.authorId),
  }));
}

// GET /api/posts/feed?cursor=&limit=
async function getFeed(req, res) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const query = buildCursorQuery({ status: 'published' }, req.query.cursor);

  const posts = await Post.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(await attachViewerState(posts, req.uid));
}

// GET /api/posts/:postId — single post, e.g. for opening a shared post link.
async function getPost(req, res) {
  const post = await Post.findById(req.params.postId);
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }
  const [withState] = await attachViewerState([post], req.uid);
  res.json(withState);
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
  res.json(await attachViewerState(posts, req.uid));
}

// GET /api/posts/user/:authorId?cursor=&limit=
async function getUserPosts(req, res) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const query = buildCursorQuery(
    { authorId: req.params.authorId, status: 'published' },
    req.query.cursor,
  );

  const posts = await Post.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(await attachViewerState(posts, req.uid));
}

// GET /api/posts/user/:authorId/liked?cursor=&limit= — self only, since
// what someone has liked is private (unlike what they've posted/reposted).
async function getUserLikedPosts(req, res) {
  const { authorId } = req.params;
  if (authorId !== req.uid) {
    throw new ApiError(403, 'You can only view your own liked posts.');
  }

  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const likes = await Like.find({ uid: authorId }).select('postId');
  if (likes.length === 0) {
    return res.json([]);
  }

  const query = buildCursorQuery(
    { _id: { $in: likes.map((l) => l.postId) }, status: 'published' },
    req.query.cursor,
  );
  const posts = await Post.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(await attachViewerState(posts, req.uid));
}

// GET /api/posts/user/:authorId/reposted?cursor=&limit= — public, like the
// reposted pill shown on each post in the feed. Each post carries the
// reposting user's quote text (if any) as `repostComment`, so a quote
// repost reads the same way on this list as a Twitter/X quote-retweet does.
async function getUserRepostedPosts(req, res) {
  const { authorId } = req.params;
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const reposts = await Repost.find({ uid: authorId }).select('postId comment');
  if (reposts.length === 0) {
    return res.json([]);
  }

  const commentsByPostId = new Map(reposts.map((r) => [r.postId.toString(), r.comment]));
  const query = buildCursorQuery(
    { _id: { $in: reposts.map((r) => r.postId) }, status: 'published' },
    req.query.cursor,
  );
  const posts = await Post.find(query).sort({ createdAt: -1 }).limit(limit);
  const withState = await attachViewerState(posts, req.uid);
  res.json(
    withState.map((post) => ({
      ...post,
      repostComment: commentsByPostId.get(post.postId) || null,
    })),
  );
}

// GET /api/posts/user/:authorId/bookmarked?cursor=&limit= — self only, since
// what someone has bookmarked/marked is private, like liked posts.
async function getUserBookmarkedPosts(req, res) {
  const { authorId } = req.params;
  if (authorId !== req.uid) {
    throw new ApiError(403, 'You can only view your own marked posts.');
  }

  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const bookmarks = await Bookmark.find({ uid: authorId }).select('postId');
  if (bookmarks.length === 0) {
    return res.json([]);
  }

  const query = buildCursorQuery(
    { _id: { $in: bookmarks.map((b) => b.postId) }, status: 'published' },
    req.query.cursor,
  );
  const posts = await Post.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(await attachViewerState(posts, req.uid));
}

// GET /api/posts/user/:authorId/shared?cursor=&limit= — self only, since
// what someone has shared isn't otherwise exposed on a post.
async function getUserSharedPosts(req, res) {
  const { authorId } = req.params;
  if (authorId !== req.uid) {
    throw new ApiError(403, 'You can only view your own shared posts.');
  }

  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const shares = await Share.find({ uid: authorId }).select('postId');
  if (shares.length === 0) {
    return res.json([]);
  }

  const query = buildCursorQuery(
    { _id: { $in: shares.map((s) => s.postId) }, status: 'published' },
    req.query.cursor,
  );
  const posts = await Post.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(await attachViewerState(posts, req.uid));
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

  const actor = await User.findById(req.uid);
  await notify({
    recipientId: post.authorId,
    actorId: req.uid,
    actorUsername: actor.username,
    actorPhotoUrl: actor.photoUrl,
    type: 'like',
    postId,
  });

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

// POST /api/posts/:postId/repost — body may include { comment } for a
// quote-repost (your own thoughts attached), omitted/empty for a plain
// repost. Reposting again while already reposted updates the comment
// instead of double-counting, so switching plain -> quote (or editing a
// quote) doesn't need a separate endpoint.
async function repost(req, res) {
  const postId = req.params.postId;
  const comment = typeof req.body.comment === 'string' ? req.body.comment.trim().slice(0, 300) : '';

  const post = await Post.findById(postId);
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }

  try {
    await Repost.create({ postId, uid: req.uid, comment });
  } catch (err) {
    if (err.code === 11000) {
      await Repost.updateOne({ postId, uid: req.uid }, { $set: { comment } });
      return res.status(204).end(); // already reposted — notified the first time
    }
    throw err;
  }

  await Post.updateOne({ _id: postId }, { $inc: { repostsCount: 1 } });

  const actor = await User.findById(req.uid);
  await notify({
    recipientId: post.authorId,
    actorId: req.uid,
    actorUsername: actor.username,
    actorPhotoUrl: actor.photoUrl,
    type: 'repost',
    postId,
  });

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

// POST /api/posts/:postId/share — sharesCount increments on every tap (you
// can share the same post to multiple people), but the Share record is
// upserted so the "Shared" profile tab lists each post once regardless of
// how many times it's been shared.
async function share(req, res) {
  const postId = req.params.postId;
  const post = await Post.findByIdAndUpdate(postId, { $inc: { sharesCount: 1 } }, { new: true });
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }

  await Share.updateOne(
    { postId, uid: req.uid },
    { $setOnInsert: { createdAt: new Date() } },
    { upsert: true },
  );

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
  buildCursorQuery,
  getPost,
  getFeed,
  getFollowingFeed,
  getUserPosts,
  getUserLikedPosts,
  getUserRepostedPosts,
  getUserBookmarkedPosts,
  getUserSharedPosts,
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
