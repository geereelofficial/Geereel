const express = require('express');
const { requireAuth } = require('../middleware/requireAuth');
const { asyncHandler } = require('../utils/asyncHandler');
const userController = require('../controllers/userController');

const router = express.Router();

// Public: checked during signup, before the caller has a Firebase ID token.
router.get('/username-available', asyncHandler(userController.usernameAvailable));

router.use(requireAuth);

router.post('/', asyncHandler(userController.createOrFetchProfile));
router.get('/:uid', asyncHandler(userController.getProfile));
router.patch('/:uid', asyncHandler(userController.updateProfile));
router.post('/:uid/avatar', asyncHandler(userController.setAvatar));
router.post('/:uid/fcm-tokens', asyncHandler(userController.addFcmToken));
router.delete('/:uid/fcm-tokens/:token', asyncHandler(userController.removeFcmToken));

module.exports = router;
