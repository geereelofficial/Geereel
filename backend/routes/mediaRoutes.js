const express = require('express');
const { requireAuth } = require('../middleware/requireAuth');
const { asyncHandler } = require('../utils/asyncHandler');
const mediaController = require('../controllers/mediaController');

const router = express.Router();

router.use(requireAuth);

router.post('/signature', asyncHandler(mediaController.getSignature));

module.exports = router;
