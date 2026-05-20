import 'package:intl/intl.dart';

class DateFormatHelper {
  /// Formats a single date to Malaysia-friendly format: e.g., "20 May 2026"
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  /// Formats a date with time: e.g., "20 May 2026, 9:00 AM"
  static String formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  /// Formats a date range to a compact Malaysia-friendly format.
  /// - Same month & year: "20–23 May 2026"
  /// - Different month, same year: "30 May – 2 Jun 2026"
  /// - Different year: "30 Dec 2026 – 2 Jan 2027"
  static String formatDateRange(DateTime start, DateTime end) {
    final sameYear = start.year == end.year;
    final sameMonth = sameYear && start.month == end.month;

    if (sameMonth) {
      return '${start.day}–${end.day} ${DateFormat('MMM yyyy').format(start)}';
    }

    if (sameYear) {
      return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
    }

    return '${DateFormat('d MMM yyyy').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
  }
}
