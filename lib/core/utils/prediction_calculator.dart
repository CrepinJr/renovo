import 'date_utils.dart';

/// Strategy for Saturday alignment if target date (date + 21 days) is not already a Saturday.
enum SaturdayAlignmentMode {
  /// Aligns to the closest Saturday (e.g. Wednesday -> Saturday +3d, Sunday -> Saturday -1d).
  closest,

  /// Aligns to the upcoming Saturday (e.g. Wednesday -> Saturday +3d, Sunday -> next Saturday +6d).
  upcoming,
}

/// Pure and unit-testable algorithm for calculating upcoming confession dates.
///
/// Rules:
/// 1. Takes the latest effective confession date as the reference.
/// 2. Projects forward by adding 21 days (3 weeks).
/// 3. Aligns the first projection to Saturday if not already a Saturday.
/// 4. Repeats the exact 21-day interval from that Saturday forward for 6 months (~182 days).
/// 5. Every generated predicted date is strictly guaranteed to fall on a Saturday (DateTime.saturday).
class PredictionCalculator {
  PredictionCalculator._();

  /// Standard cycle interval in days (3 weeks).
  static const int cycleDays = 21;

  /// Default projection horizon in months.
  static const int defaultHorizonMonths = 6;

  /// Aligns any given date to a Saturday.
  ///
  /// - If [date] is already Saturday ([DateTime.saturday]), it returns [date].
  /// - In [SaturdayAlignmentMode.closest]:
  ///   - Monday: -2 days (previous Saturday)
  ///   - Tuesday: -3 days (previous Saturday)
  ///   - Wednesday: +3 days (Saturday of this week)
  ///   - Thursday: +2 days (Saturday of this week)
  ///   - Friday: +1 day (Saturday of this week)
  ///   - Sunday: -1 day (closest Saturday)
  /// - In [SaturdayAlignmentMode.upcoming]:
  ///   - Moves forward to the next Saturday (0 to 6 days).
  static DateTime alignToSaturday(
    DateTime date, {
    SaturdayAlignmentMode mode = SaturdayAlignmentMode.closest,
  }) {
    final normalized = RenovoDateUtils.normalizeDate(date);
    final weekday = normalized.weekday;

    if (weekday == DateTime.saturday) {
      return normalized;
    }

    if (mode == SaturdayAlignmentMode.upcoming) {
      final daysForward = (DateTime.saturday - weekday + 7) % 7;
      return normalized.add(Duration(days: daysForward));
    }

    // Closest Saturday logic
    final daysBack = (weekday - DateTime.saturday + 7) % 7;
    final daysForward = (DateTime.saturday - weekday + 7) % 7;

    if (daysForward <= daysBack) {
      return normalized.add(Duration(days: daysForward));
    } else {
      return normalized.subtract(Duration(days: daysBack));
    }
  }

  /// Calculates predicted confession dates for the next [monthsAhead] months
  /// based on [latestConfessionDate].
  ///
  /// Returns an empty list if [latestConfessionDate] is null.
  /// Guarantees that every date in the returned list has `date.weekday == DateTime.saturday`.
  static List<DateTime> calculatePredictions({
    required DateTime? latestConfessionDate,
    int monthsAhead = defaultHorizonMonths,
    SaturdayAlignmentMode alignmentMode = SaturdayAlignmentMode.closest,
  }) {
    if (latestConfessionDate == null) {
      return const [];
    }

    final normalizedLatest = RenovoDateUtils.normalizeDate(latestConfessionDate);
    // Horizon limit: 6 months from reference (e.g., 183 days)
    final horizonEnd = DateTime(
      normalizedLatest.year,
      normalizedLatest.month + monthsAhead,
      normalizedLatest.day,
    );

    final predictions = <DateTime>[];

    // 1. Calculate first target: latest + 21 days
    final firstRawTarget = normalizedLatest.add(const Duration(days: cycleDays));

    // 2. Align to Saturday
    var currentSaturday = alignToSaturday(firstRawTarget, mode: alignmentMode);

    // If aligning closest resulted in a date on or before the latest confession date (edge case),
    // shift forward by 21 days or to next Saturday.
    while (!currentSaturday.isAfter(normalizedLatest)) {
      currentSaturday = currentSaturday.add(const Duration(days: cycleDays));
    }

    // 3. Repeat the 21-day interval from this Saturday for the entire horizon
    while (!currentSaturday.isAfter(horizonEnd)) {
      predictions.add(currentSaturday);
      // Since currentSaturday is a Saturday, adding 21 days (multiple of 7)
      // strictly guarantees that all subsequent dates are also Saturdays.
      currentSaturday = currentSaturday.add(const Duration(days: cycleDays));
    }

    return predictions;
  }
}
