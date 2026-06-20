import 'package:timeago/timeago.dart' as timeago;

/// Shared formatting helpers for counts and timestamps shown in the feed,
/// comments, and chat.
class Formatters {
  Formatters._();

  /// Compact form for like/comment/view counts, e.g. 1234 -> "1.2K".
  static String compactCount(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  /// Relative time, e.g. "3m ago", used for comments and chat messages.
  static String relativeTime(DateTime dateTime) => timeago.format(dateTime);
}
