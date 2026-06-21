const express = require('express');
const { requireAuth } = require('../middleware/requireAuth');
const { asyncHandler } = require('../utils/asyncHandler');
const statusController = require('../controllers/statusController');

const router = express.Router();

router.use(requireAuth);

router.get('/', asyncHandler(statusController.getTray));
router.post('/', asyncHandler(statusController.createStatus));
router.get('/user/:authorId', asyncHandler(statusController.getUserStatuses));
router.post('/:statusId/view', asyncHandler(statusController.viewStatus));
router.get('/:statusId/viewers', asyncHandler(statusController.getViewers));
router.delete('/:statusId', asyncHandler(statusController.deleteStatus));

module.exports = router;
