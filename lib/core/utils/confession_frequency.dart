class ConfessionFrequency {
  ConfessionFrequency._();

  static const preferenceKey = 'confession_frequency_weeks';
  static const defaultWeeks = 3;
  static const minWeeks = 1;
  static const maxWeeks = 12;

  static int clampWeeks(int weeks) => weeks.clamp(minWeeks, maxWeeks).toInt();
}
