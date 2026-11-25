import 'package:flutter_test/flutter_test.dart';
import 'package:renovo/core/utils/reminder_calculator.dart';
import 'package:renovo/services/notification_service.dart';

void main() {
  test('calculates all five local reminder timestamps for the deadline', () {
    final moments = ReminderCalculator.calculateReminderTimes(
      deadline: DateTime(2026, 12, 12),
      hour: 9,
      minute: 30,
    );

    expect(moments.map((moment) => moment.scheduledAt).toList(), [
      DateTime(2026, 12, 5, 9, 30),
      DateTime(2026, 12, 9, 9, 30),
      DateTime(2026, 12, 11, 9, 30),
      DateTime(2026, 12, 13, 9, 30),
      DateTime(2026, 12, 15, 9, 30),
    ]);
    expect(moments.map((moment) => moment.milestone).toList(), [
      ReminderMilestone.weekBefore,
      ReminderMilestone.threeDaysBefore,
      ReminderMilestone.dayBefore,
      ReminderMilestone.dayAfter,
      ReminderMilestone.threeDaysAfter,
    ]);
  });

  test('uses the requested concise title and body for every reminder', () {
    final expected = [
      (
        ReminderMilestone.weekBefore,
        'Confession dans 7 jours',
        'Préparez votre cœur pour samedi prochain.',
      ),
      (
        ReminderMilestone.threeDaysBefore,
        'Confession dans 3 jours',
        'Votre prochaine échéance approche.',
      ),
      (
        ReminderMilestone.dayBefore,
        'Confession demain',
        'Rappel : confession prévue demain.',
      ),
      (
        ReminderMilestone.dayAfter,
        'Confession hier ?',
        "Pensez à l'enregistrer si elle a eu lieu.",
      ),
      (
        ReminderMilestone.threeDaysAfter,
        'Dernier rappel (72h)',
        'Sera marquée non effectuée ce soir.',
      ),
    ];

    for (final (milestone, title, body) in expected) {
      final content = NotificationService.reminderContentFor(milestone);
      expect(content.title, title);
      expect(content.body, body);
      expect(content.body.length, lessThanOrEqualTo(50));
    }

    expect(
      NotificationService.testNotificationBody,
      'Ceci est un aperçu de vos rappels Renovo.',
    );
    expect(
      NotificationService.testNotificationBody.length,
      lessThanOrEqualTo(50),
    );
  });
}
