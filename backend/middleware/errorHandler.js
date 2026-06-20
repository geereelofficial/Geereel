const { ApiError } = require('../utils/ApiError');

function notFoundHandler(req, res) {
  res.status(404).json({ message: `Route not found: ${req.method} ${req.originalUrl}` });
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({ message: err.message });
  }

  if (err && err.code === 11000) {
    return res.status(409).json({ message: 'That value is already taken.' });
  }

  if (err && err.name === 'ValidationError') {
    return res.status(400).json({ message: err.message });
  }

  console.error(err);
  res.status(500).json({ message: 'Something went wrong. Please try again.' });
}

module.exports = { notFoundHandler, errorHandler };
