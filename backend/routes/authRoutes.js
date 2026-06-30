const express = require('express');
const router = express.Router();
const { forgotPassword, getResetPasswordPage, postResetPassword } = require('../controllers/authController');

router.post('/forgot-password', forgotPassword);

module.exports = router;
