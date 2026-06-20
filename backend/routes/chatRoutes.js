const express = require('express');
const { requireAuth } = require('../middleware/requireAuth');
const { asyncHandler } = require('../utils/asyncHandler');
const chatController = require('../controllers/chatController');

const router = express.Router();

router.use(requireAuth);

router.get('/', asyncHandler(chatController.listChats));
router.post('/', asyncHandler(chatController.getOrCreateChat));
router.get('/:chatId/messages', asyncHandler(chatController.getMessages));
router.post('/:chatId/read', asyncHandler(chatController.markAsRead));

module.exports = router;
