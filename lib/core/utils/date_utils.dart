import 'package:intl/intl.dart';

/// Common date utilities and French formatting helpers for Renovo.
class RenovoDateUtils {
  RenovoDateUtils._();

  /// Strips hours, minutes, seconds and milliseconds to ensure pure date comparisons.
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Checks if two DateTimes represent the same calendar day.
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Formats date with full weekday, day, month and year in French.
  /// Example: "samedi 21 novembre 2026"
  static String formatFullFrenchDate(DateTime date) {
    final formatter = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final formatted = formatter.format(date);
    // Capitalize first letter (e.g., "Samedi 21 novembre 2026")
    if (formatted.isEmpty) return formatted;
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// Formats short date. Example: "21/11/2026"
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  /// Formats month and year for calendar header. Example: "Novembre 2026"
  static String formatMonthYear(DateTime date) {
    final formatted = DateFormat('MMMM yyyy', 'fr_FR').format(date);
    if (formatted.isEmpty) return formatted;
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}
