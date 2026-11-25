import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../core/utils/prediction_calculator.dart';
import 'confessions_provider.dart';
import 'frequency_provider.dart';

/// Provider generating upcoming predicted confession dates for 6 months.
/// Automatically recalculates whenever the latest confession changes.
final predictionsProvider = Provider<List<DateTime>>((ref) {
  final latestConfession = ref.watch(latestConfessionProvider);
  if (latestConfession == null) {
    return const [];
  }

  final cycleWeeks =
      ref.watch(confessionFrequencyWeeksProvider).asData?.value ??
      PredictionCalculator.defaultCycleWeeks;
  final now = ref.watch(predictionNowProvider).asData?.value ?? DateTime.now();
  return PredictionCalculator.calculatePredictions(
    latestConfessionDate: latestConfession.date,
    cycleWeeks: cycleWeeks,
    now: now,
  );
});

/// Emits at each 72-hour threshold so overdue predictions update while the app
/// remains open, as well as when the latest confession changes.
final predictionNowProvider = StreamProvider<DateTime>((ref) {
  final latestConfessionDate = ref.watch(latestConfessionProvider)?.date;
  final cycleWeeks =
      ref.watch(confessionFrequencyWeeksProvider).asData?.value ??
      PredictionCalculator.defaultCycleWeeks;
  final controller = StreamController<DateTime>();
  Timer? timer;

  void update() {
    if (controller.isClosed) return;
    final now = DateTime.now();
    controller.add(now);
    if (latestConfessionDate == null) return;

    final nextChange =
        PredictionCalculator.calculatePredictions(
              latestConfessionDate: latestConfessionDate,
              cycleWeeks: cycleWeeks,
              now: now,
            )
            .map((date) => date.add(const Duration(hours: 72)))
            .map((date) => date.add(const Duration(milliseconds: 1)))
            .where((date) => date.isAfter(now))
            .fold<DateTime?>(null, (nearest, date) {
              if (nearest == null || date.isBefore(nearest)) return date;
              return nearest;
            });
    if (nextChange != null) {
      timer = Timer(nextChange.difference(now), update);
    }
  }

  scheduleMicrotask(update);
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});

final predictionStatusesProvider = Provider<Map<DateTime, PredictionStatus>>((
  ref,
) {
  final predictions = ref.watch(predictionsProvider);
  final confessions = ref.watch(confessionsProvider).asData?.value ?? const [];
  final completedDates = confessions.map((confession) => confession.date);
  final now = ref.watch(predictionNowProvider).asData?.value ?? DateTime.now();
  return {
    for (final date in predictions)
      RenovoDateUtils.normalizeDate(date): PredictionCalculator.statusForDate(
        date: date,
        completedDates: completedDates,
        now: now,
      ),
  };
});

/// Fast O(1) lookup sets for calendar decoration.
final predictionsSetProvider = Provider<Set<DateTime>>((ref) {
  final statuses = ref.watch(predictionStatusesProvider);
  return statuses.entries
      .where((entry) => entry.value == PredictionStatus.upcoming)
      .map((entry) => entry.key)
      .toSet();
});

final missedPredictionsSetProvider = Provider<Set<DateTime>>((ref) {
  final statuses = ref.watch(predictionStatusesProvider);
  return statuses.entries
      .where((entry) => entry.value == PredictionStatus.missed)
      .map((entry) => entry.key)
      .toSet();
});
