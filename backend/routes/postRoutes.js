const express = require('express');
const { requireAuth } = require('../middleware/requireAuth');
const { asyncHandler } = require('../utils/asyncHandler');
const postController = require('../controllers/postController');
const commentController = require('../controllers/commentController');

const router = express.Router();

router.use(requireAuth);

router.get('/feed', asyncHandler(postController.getFeed));
router.get('/following', asyncHandler(postController.getFollowingFeed));
router.get('/user/:authorId', asyncHandler(postController.getUserPosts));
router.get('/user/:authorId/liked', asyncHandler(postController.getUserLikedPosts));
router.get('/user/:authorId/reposted', asyncHandler(postController.getUserRepostedPosts));
router.get('/user/:authorId/bookmarked', asyncHandler(postController.getUserBookmarkedPosts));
router.get('/user/:authorId/shared', asyncHandler(postController.getUserSharedPosts));
router.post('/', asyncHandler(postController.createPost));

router.get('/:postId', asyncHandler(postController.getPost));

router.get('/:postId/liked', asyncHandler(postController.getLiked));
router.post('/:postId/like', asyncHandler(postController.like));
router.delete('/:postId/like', asyncHandler(postController.unlike));
router.get('/:postId/bookmarked', asyncHandler(postController.getBookmarked));
router.post('/:postId/bookmark', asyncHandler(postController.bookmark));
router.delete('/:postId/bookmark', asyncHandler(postController.unbookmark));
router.get('/:postId/reposted', asyncHandler(postController.getReposted));
router.post('/:postId/repost', asyncHandler(postController.repost));
router.delete('/:postId/repost', asyncHandler(postController.unrepost));
router.post('/:postId/share', asyncHandler(postController.share));
router.post('/:postId/view', asyncHandler(postController.view));

router.get('/:postId/comments', asyncHandler(commentController.listComments));
router.post('/:postId/comments', asyncHandler(commentController.addComment));

module.exports = router;
