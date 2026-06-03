import 'package:intl/intl.dart';

// Shared date formatting helper.
class DateFormatHelper {
  // Format date as 20 May 2026.
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  // Format date and time as 20 May 2026, 9:00 AM.
  static String formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  // Format date range for event dates.
  static String formatDateRange(DateTime start, DateTime end) {
    final sameYear = start.year == end.year;
    final sameMonth = sameYear && start.month == end.month;

    // Format range within same month.
    if (sameMonth) {
      return '${start.day}–${end.day} ${DateFormat('MMM yyyy').format(start)}';
    }

    // Format range within same year.
    if (sameYear) {
      return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
    }

    // Format range across different years.
    return '${DateFormat('d MMM yyyy').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
  }
}