import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/confession_frequency.dart';
import 'confessions_provider.dart';
import 'notification_provider.dart';

class ConfessionFrequencyWeeksNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final preferences = await SharedPreferences.getInstance();
    final savedWeeks = preferences.getInt(ConfessionFrequency.preferenceKey);
    final weeks = ConfessionFrequency.clampWeeks(
      savedWeeks ?? ConfessionFrequency.defaultWeeks,
    );
    if (savedWeeks != null && savedWeeks != weeks) {
      final saved = await preferences.setInt(
        ConfessionFrequency.preferenceKey,
        weeks,
      );
      if (!saved) {
        throw StateError('Impossible de corriger la fréquence enregistrée.');
      }
    }
    return weeks;
  }

  Future<void> setFrequencyWeeks(int weeks) async {
    if (weeks < ConfessionFrequency.minWeeks ||
        weeks > ConfessionFrequency.maxWeeks) {
      throw ArgumentError.value(
        weeks,
        'weeks',
        'La fréquence doit être comprise entre 1 et 12 semaines.',
      );
    }

    final currentWeeks = state.asData?.value;
    if (currentWeeks == null) {
      throw StateError('La fréquence de confession n’est pas chargée.');
    }
    if (currentWeeks == weeks) return;

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setInt(
      ConfessionFrequency.preferenceKey,
      weeks,
    );
    if (!saved) {
      throw StateError('Impossible d’enregistrer la fréquence de confession.');
    }

    state = AsyncData(weeks);
    final service = await ref.read(notificationServiceProvider.future);
    final confessions = await ref.read(confessionsProvider.future);
    await service.rescheduleReminders(confessions: confessions);
  }
}

final confessionFrequencyWeeksProvider =
    AsyncNotifierProvider<ConfessionFrequencyWeeksNotifier, int>(
      ConfessionFrequencyWeeksNotifier.new,
    );
