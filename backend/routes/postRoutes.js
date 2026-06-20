const express = require('express');
const { requireAuth } = require('../middleware/requireAuth');
const { asyncHandler } = require('../utils/asyncHandler');
const postController = require('../controllers/postController');
const commentController = require('../controllers/commentController');

const router = express.Router();

router.use(requireAuth);

router.get('/feed', asyncHandler(postController.getFeed));
router.get('/user/:authorId', asyncHandler(postController.getUserPosts));
router.post('/', asyncHandler(postController.createPost));

router.get('/:postId/liked', asyncHandler(postController.getLiked));
router.post('/:postId/like', asyncHandler(postController.like));
router.delete('/:postId/like', asyncHandler(postController.unlike));
router.post('/:postId/share', asyncHandler(postController.share));
router.post('/:postId/view', asyncHandler(postController.view));

router.get('/:postId/comments', asyncHandler(commentController.listComments));
router.post('/:postId/comments', asyncHandler(commentController.addComment));

module.exports = router;
