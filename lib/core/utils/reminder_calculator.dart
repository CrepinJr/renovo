enum ReminderMilestone {
  weekBefore,
  threeDaysBefore,
  dayBefore,
  dayAfter,
  threeDaysAfter,
}

class ReminderMoment {
  const ReminderMoment({required this.milestone, required this.scheduledAt});

  final ReminderMilestone milestone;
  final DateTime scheduledAt;
}

class ReminderCalculator {
  ReminderCalculator._();

  static const List<(ReminderMilestone, int)> _dayOffsets = [
    (ReminderMilestone.weekBefore, -7),
    (ReminderMilestone.threeDaysBefore, -3),
    (ReminderMilestone.dayBefore, -1),
    (ReminderMilestone.dayAfter, 1),
    (ReminderMilestone.threeDaysAfter, 3),
  ];

  static List<ReminderMoment> calculateReminderTimes({
    required DateTime deadline,
    required int hour,
    required int minute,
  }) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'Must be between 0 and 23.');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'Must be between 0 and 59.');
    }

    return [
      for (final (milestone, dayOffset) in _dayOffsets)
        ReminderMoment(
          milestone: milestone,
          scheduledAt: DateTime(
            deadline.year,
            deadline.month,
            deadline.day + dayOffset,
            hour,
            minute,
          ),
        ),
    ];
  }
}
