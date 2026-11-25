import 'package:flutter_test/flutter_test.dart';
import 'package:renovo/core/utils/reminder_calculator.dart';
import 'package:renovo/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('falls back for Africa/Porto-Novo and keeps local reminder scheduling usable', () {
    final now = DateTime(2026, 11, 24, 12);
    final location = NotificationService.setLocalTimezone(
      timezoneName: 'Africa/Porto-Novo',
      systemOffset: const Duration(hours: 1),
      now: now,
    );

    expect(tz.local, same(location));
    expect(
      location.timeZone(now.toUtc().millisecondsSinceEpoch).offset,
      const Duration(hours: 1),
    );

    final reminder = ReminderCalculator.calculateReminderTimes(
      deadline: DateTime(2026, 12, 12),
      hour: 9,
      minute: 30,
    ).first;
    final scheduledDate = tz.TZDateTime.from(reminder.scheduledAt, tz.local);

    expect(scheduledDate.location, same(location));
    expect(scheduledDate.timeZoneOffset, const Duration(hours: 1));
  });

  test('uses UTC when no location matches the system offset', () {
    final location = NotificationService.setLocalTimezone(
      timezoneName: 'Africa/Porto-Novo',
      systemOffset: const Duration(seconds: 37),
      now: DateTime(2026, 11, 24, 12),
    );

    expect(location, same(tz.UTC));
    expect(tz.local, same(tz.UTC));
  });
}
