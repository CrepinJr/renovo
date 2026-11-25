import 'date_utils.dart';

enum PredictionStatus { upcoming, missed, completed }

/// Strategy for Saturday alignment if the calculated target is not a Saturday.
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
/// 2. Projects forward by adding the configured number of weeks.
/// 3. Aligns the first projection to Saturday if not already a Saturday.
/// 4. Repeats the configured interval from that Saturday forward for 6 months.
/// 5. Every generated predicted date is strictly guaranteed to fall on a Saturday (DateTime.saturday).
class PredictionCalculator {
  PredictionCalculator._();

  /// Default cycle interval in days (3 weeks).
  static const int cycleDays = 21;
  static const int defaultCycleWeeks = 3;

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
    int cycleWeeks = defaultCycleWeeks,
    SaturdayAlignmentMode alignmentMode = SaturdayAlignmentMode.closest,
    DateTime? now,
  }) {
    if (cycleWeeks < 1 || cycleWeeks > 12) {
      throw ArgumentError.value(
        cycleWeeks,
        'cycleWeeks',
        'Cycle must be between 1 and 12 weeks.',
      );
    }
    if (latestConfessionDate == null) {
      return const [];
    }

    final cycleDuration = Duration(days: cycleWeeks * 7);
    final normalizedLatest = RenovoDateUtils.normalizeDate(
      latestConfessionDate,
    );
    // Horizon limit: 6 months from reference (e.g., 183 days)
    var horizonEnd = DateTime(
      normalizedLatest.year,
      normalizedLatest.month + monthsAhead,
      normalizedLatest.day,
    );
    if (now != null) {
      final currentHorizonEnd = DateTime(
        now.year,
        now.month + monthsAhead,
        now.day,
      );
      if (currentHorizonEnd.isAfter(horizonEnd)) {
        horizonEnd = currentHorizonEnd;
      }
    }

    final predictions = <DateTime>[];

    // 1. Calculate the first target using the configured interval.
    final firstRawTarget = normalizedLatest.add(cycleDuration);

    // 2. Align to Saturday
    var currentSaturday = alignToSaturday(firstRawTarget, mode: alignmentMode);

    // If alignment lands on or before the latest confession date, advance by
    // the configured interval.
    while (!currentSaturday.isAfter(normalizedLatest)) {
      currentSaturday = currentSaturday.add(cycleDuration);
    }

    // 3. Repeat the interval from this Saturday for the entire horizon.
    while (!currentSaturday.isAfter(horizonEnd)) {
      predictions.add(currentSaturday);
      // Since each interval is a multiple of 7 days,
      // strictly guarantees that all subsequent dates are also Saturdays.
      currentSaturday = currentSaturday.add(cycleDuration);
    }

    return predictions;
  }

  static PredictionStatus statusForDate({
    required DateTime date,
    required Iterable<DateTime> completedDates,
    required DateTime now,
  }) {
    final normalizedDate = RenovoDateUtils.normalizeDate(date);
    if (completedDates.any(
      (completedDate) =>
          RenovoDateUtils.normalizeDate(completedDate) == normalizedDate,
    )) {
      return PredictionStatus.completed;
    }

    final missedAt = normalizedDate.add(const Duration(hours: 72));
    return now.isAfter(missedAt)
        ? PredictionStatus.missed
        : PredictionStatus.upcoming;
  }
}
