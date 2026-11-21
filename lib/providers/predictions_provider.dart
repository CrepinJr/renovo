import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/prediction_calculator.dart';
import 'confessions_provider.dart';

/// Provider generating upcoming predicted confession dates for 6 months.
/// Automatically recalculates whenever the latest confession changes.
final predictionsProvider = Provider<List<DateTime>>((ref) {
  final latestConfession = ref.watch(latestConfessionProvider);
  if (latestConfession == null) {
    return const [];
  }

  return PredictionCalculator.calculatePredictions(
    latestConfessionDate: latestConfession.date,
  );
});

/// Fast O(1) lookup set of normalized predicted dates for calendar decoration.
final predictionsSetProvider = Provider<Set<DateTime>>((ref) {
  final predictions = ref.watch(predictionsProvider);
  return predictions.map((d) => RenovoDateUtils.normalizeDate(d)).toSet();
});
