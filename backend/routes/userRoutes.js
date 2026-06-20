const express = require('express');
const { requireAuth } = require('../middleware/requireAuth');
const { asyncHandler } = require('../utils/asyncHandler');
const userController = require('../controllers/userController');
const followController = require('../controllers/followController');

const router = express.Router();

// Public: checked during signup, before the caller has a Firebase ID token.
router.get('/username-available', asyncHandler(userController.usernameAvailable));

router.use(requireAuth);

// Must come before '/:uid' so "search" isn't captured as a uid.
router.get('/search', asyncHandler(userController.searchUsers));

router.post('/', asyncHandler(userController.createOrFetchProfile));
router.get('/:uid', asyncHandler(userController.getProfile));
router.patch('/:uid', asyncHandler(userController.updateProfile));
router.post('/:uid/avatar', asyncHandler(userController.setAvatar));
router.post('/:uid/fcm-tokens', asyncHandler(userController.addFcmToken));
router.delete('/:uid/fcm-tokens/:token', asyncHandler(userController.removeFcmToken));

router.post('/:uid/follow', asyncHandler(followController.follow));
router.delete('/:uid/follow', asyncHandler(followController.unfollow));
router.get('/:uid/is-following', asyncHandler(followController.isFollowing));

module.exports = router;
