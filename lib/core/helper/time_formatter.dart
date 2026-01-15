/// Utility class for formatting time like Instagram comments
class TimeFormatter {
  /// Formats a DateTime or timestamp string to Instagram-style
  /// e.g., "just now", "1m ago", "5h ago", "2d ago", "9w ago", "104w ago"
  static String formatRelativeTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime? dateTime;

    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      if (timestamp.isEmpty) return '';
      if (_isAlreadyFormatted(timestamp)) return timestamp;

      dateTime = DateTime.tryParse(timestamp);
      if (dateTime == null) {
        final milliseconds = int.tryParse(timestamp);
        if (milliseconds != null) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
        }
      }
    } else if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    if (dateTime == null) return timestamp.toString();

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) return 'just now';

    if (difference.inSeconds < 60) {
      return 'just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    // Weeks
    final weeks = (difference.inDays / 7).floor();
    return '${weeks}w ago';
  }

  static bool _isAlreadyFormatted(String value) {
    final lower = value.toLowerCase();
    if (lower == 'just now') return true;
    if (RegExp(r'^\d+[mhdw] ago$').hasMatch(lower)) return true;
    return false;
  }
}
