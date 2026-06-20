const cloudinary = require('../config/cloudinary');
const { ApiError } = require('../utils/ApiError');

const ALLOWED_FOLDERS = new Set(['posts', 'avatars']);

// POST /api/media/signature — {folder: 'posts'|'avatars'}
// Signs an upload request server-side; the secret never leaves the backend.
async function getSignature(req, res) {
  const { folder } = req.body;
  if (!folder || !ALLOWED_FOLDERS.has(folder)) {
    throw new ApiError(400, "folder must be one of: 'posts', 'avatars'.");
  }

  const timestamp = Math.round(Date.now() / 1000);
  const paramsToSign = { timestamp, folder };

  const signature = cloudinary.utils.api_sign_request(
    paramsToSign,
    process.env.CLOUDINARY_API_SECRET,
  );

  res.json({
    signature,
    timestamp,
    apiKey: process.env.CLOUDINARY_API_KEY,
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    folder,
  });
}

module.exports = { getSignature };
