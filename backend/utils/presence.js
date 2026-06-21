// In-memory online-presence tracking, keyed by Firebase uid. A uid can have
// multiple sockets (e.g. two devices), so we refcount rather than store a
// single boolean — the uid is "online" as long as at least one socket is
// open. O(1) per connect/disconnect/lookup; no database round trip needed
// to answer "is this user online right now".
const socketCountByUid = new Map();

function markOnline(uid) {
  socketCountByUid.set(uid, (socketCountByUid.get(uid) || 0) + 1);
}

// Returns true the instant a uid's last socket disconnects, so the caller
// can decide whether to broadcast an offline transition.
function markOffline(uid) {
  const remaining = (socketCountByUid.get(uid) || 1) - 1;
  if (remaining <= 0) {
    socketCountByUid.delete(uid);
    return true;
  }
  socketCountByUid.set(uid, remaining);
  return false;
}

function isOnline(uid) {
  return socketCountByUid.has(uid);
}

module.exports = { markOnline, markOffline, isOnline };
