import 'package:intl/intl.dart';

/// Human-friendly time/date formatting for chat UI.
class ChatFormatters {
  const ChatFormatters._();

  /// Short clock time, e.g. `9:05 PM`. Used on message bubbles.
  static String time(DateTime t) => DateFormat.jm().format(t.toLocal());

  /// Relative label for the conversation list / "last seen":
  /// time today, "Yesterday", weekday this week, else a short date.
  static String relativeStamp(DateTime t) {
    final local = t.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(that).inDays;

    if (diffDays == 0) return DateFormat.jm().format(local);
    if (diffDays == 1) return 'Yesterday';
    if (diffDays < 7) return DateFormat.EEEE().format(local);
    return DateFormat.yMd().format(local);
  }

  /// Full day label for the in-thread date separator
  /// ("Today", "Yesterday", or a long date).
  static String daySeparator(DateTime t) {
    final local = t.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(that).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return DateFormat.yMMMMd().format(local);
  }

  /// "last seen" subtitle from a presence timestamp.
  static String lastSeen(DateTime t) => 'last seen ${relativeStamp(t)}';

  /// Whether [a] and [b] fall on different calendar days (drives separators).
  static bool isDifferentDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year != lb.year || la.month != lb.month || la.day != lb.day;
  }

  /// Compact byte size, e.g. `1.2 MB`.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var size = bytes / 1024;
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unit]}';
  }

  /// `m:ss` clip duration from milliseconds.
  static String duration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
