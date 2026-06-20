const Comment = require('../models/Comment');
const Post = require('../models/Post');
const User = require('../models/User');
const { ApiError } = require('../utils/ApiError');

function toJson(comment) {
  return {
    commentId: comment._id.toString(),
    postId: comment.postId.toString(),
    authorId: comment.authorId,
    authorUsername: comment.authorUsername,
    authorPhotoUrl: comment.authorPhotoUrl,
    text: comment.text,
    likesCount: comment.likesCount,
    parentCommentId: comment.parentCommentId ? comment.parentCommentId.toString() : null,
    createdAt: comment.createdAt,
  };
}

// GET /api/posts/:postId/comments?limit=
async function listComments(req, res) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const comments = await Comment.find({ postId: req.params.postId })
    .sort({ createdAt: -1 })
    .limit(limit);
  res.json(comments.map(toJson));
}

// POST /api/posts/:postId/comments — {text}
async function addComment(req, res) {
  const { postId } = req.params;
  const { text } = req.body;

  if (!text || !text.trim()) {
    throw new ApiError(400, 'text is required.');
  }

  const [post, author] = await Promise.all([Post.findById(postId), User.findById(req.uid)]);
  if (!post) {
    throw new ApiError(404, 'Post not found.');
  }
  if (!author) {
    throw new ApiError(404, 'User profile not found.');
  }

  const comment = await Comment.create({
    postId,
    authorId: req.uid,
    authorUsername: author.username,
    authorPhotoUrl: author.photoUrl,
    text: text.trim(),
  });

  await Post.updateOne({ _id: postId }, { $inc: { commentsCount: 1 } });

  res.status(201).json(toJson(comment));
}

module.exports = { toJson, listComments, addComment };
