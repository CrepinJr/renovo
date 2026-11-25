import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/confession.dart';
import 'confession_repository_provider.dart';
import 'confessions_provider.dart';
import 'selected_date_provider.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = FutureProvider<NotificationService>((
  ref,
) async {
  final service = NotificationService(
    onMarkDone: (date) async {
      final repository = ref.read(confessionRepositoryProvider);
      final confessions = await repository.getAllConfessions();
      final normalizedDate = RenovoDateUtils.normalizeDate(date);
      final alreadyRecorded = confessions.any(
        (confession) => confession.normalizedDate == normalizedDate,
      );
      if (!alreadyRecorded) {
        await repository.insertConfession(
          Confession(date: normalizedDate, parish: 'Paroisse non renseignée'),
        );
      }
      ref.invalidate(confessionsProvider);
    },
    onOpenDate: (date) {
      ref.read(selectedDateProvider.notifier).selectDate(date);
      ref.read(focusedDayProvider.notifier).setFocusedDay(date);
    },
  );
  await service.initialize();
  final confessions = await ref.read(confessionsProvider.future);
  await service.rescheduleReminders(confessions: confessions);
  return service;
});

class ReminderSettingsNotifier extends AsyncNotifier<ReminderPreferences> {
  @override
  Future<ReminderPreferences> build() async {
    final service = await ref.watch(notificationServiceProvider.future);
    return service.loadPreferences();
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Les préférences de rappel ne sont pas chargées.');
    }

    await _save(
      current.copyWith(enabled: enabled),
      requestPermission: enabled && !current.enabled,
    );
  }

  Future<void> setTime({required int hour, required int minute}) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Les préférences de rappel ne sont pas chargées.');
    }
    await _save(current.copyWith(hour: hour, minute: minute));
  }

  Future<void> _save(
    ReminderPreferences value, {
    bool requestPermission = false,
  }) async {
    final previous = state.asData?.value;
    if (previous == null) {
      throw StateError('Les préférences de rappel ne sont pas chargées.');
    }

    try {
      final service = await ref.read(notificationServiceProvider.future);
      if (requestPermission &&
          !await service.requestPermissions(requestExactAlarms: true)) {
        throw StateError(
          'Les permissions de notification ou d’alarme exacte ont été refusées.',
        );
      }
      await service.savePreferences(value);
      final confessions = await ref.read(confessionsProvider.future);
      await service.rescheduleReminders(confessions: confessions);
      state = AsyncData(value);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, ReminderPreferences>(
      ReminderSettingsNotifier.new,
    );
