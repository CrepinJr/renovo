import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';
import '../providers/confessions_provider.dart';
import '../providers/predictions_provider.dart';
import '../providers/selected_date_provider.dart';

/// Monthly Calendar Card widget calibrated to the Stitch "Sacred Minimalism" design:
/// Lora headline-md month header, French weekdays (lun., mar. ...), 12px rounded day cells,
/// antique gold ring for predictions, emerald dot for completed confessions, indigo for selected.
class RenovoCalendarWidget extends ConsumerWidget {
  const RenovoCalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final confessionsMap = ref.watch(confessionsMapProvider);
    final predictionsSet = ref.watch(predictionsSetProvider);
    final missedDatesSet = ref.watch(missedPredictionsSetProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceContainer = isDark ? AppTheme.darkSurfaceContainer : AppTheme.lightSurfaceContainer;
    final outlineColor = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;
    final onSurfaceVariant = isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.lightOnSurfaceVariant;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final onPrimary = isDark ? AppTheme.darkOnPrimary : AppTheme.lightOnPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: outlineColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month Header with Lora font and Prev/Next Chevrons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  RenovoDateUtils.formatMonthYear(focusedDay),
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                    color: onSurface,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        final prevMonth = DateTime(focusedDay.year, focusedDay.month - 1, 1);
                        ref.read(focusedDayProvider.notifier).setFocusedDay(prevMonth);
                      },
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        final nextMonth = DateTime(focusedDay.year, focusedDay.month + 1, 1);
                        ref.read(focusedDayProvider.notifier).setFocusedDay(nextMonth);
                      },
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TableCalendar with custom header suppressed (headerVisible: false)
            TableCalendar(
              locale: 'fr_FR',
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: focusedDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              currentDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
              headerVisible: false,
              daysOfWeekHeight: 24,
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) {
                  // Returns "lun.", "mar.", "mer.", "jeu.", "ven.", "sam.", "dim."
                  const days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
                  return days[(date.weekday - 1) % 7];
                },
                weekdayStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: onSurfaceVariant,
                ),
                weekendStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: onSurfaceVariant,
                ),
              ),
              selectedDayPredicate: (day) => RenovoDateUtils.isSameDay(selectedDate, day),
              onDaySelected: (newSelectedDay, newFocusedDay) {
                ref.read(selectedDateProvider.notifier).selectDate(newSelectedDay);
                ref.read(focusedDayProvider.notifier).setFocusedDay(newFocusedDay);
              },
              onPageChanged: (newFocusedDay) {
                ref.read(focusedDayProvider.notifier).setFocusedDay(newFocusedDay);
              },
              rowHeight: 46,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, currentFocusedDay) {
                  return _buildDayItem(
                    day: day,
                    isSelected: false,
                    isToday: RenovoDateUtils.isSameDay(day, DateTime.now()),
                    confessionsMap: confessionsMap,
                    predictionsSet: predictionsSet,
                    missedDatesSet: missedDatesSet,
                    primaryColor: primaryColor,
                    onPrimary: onPrimary,
                    onSurface: onSurface,
                    isDark: isDark,
                  );
                },
                selectedBuilder: (context, day, currentFocusedDay) {
                  return _buildDayItem(
                    day: day,
                    isSelected: true,
                    isToday: RenovoDateUtils.isSameDay(day, DateTime.now()),
                    confessionsMap: confessionsMap,
                    predictionsSet: predictionsSet,
                    missedDatesSet: missedDatesSet,
                    primaryColor: primaryColor,
                    onPrimary: onPrimary,
                    onSurface: onSurface,
                    isDark: isDark,
                  );
                },
                todayBuilder: (context, day, currentFocusedDay) {
                  final isSelected = RenovoDateUtils.isSameDay(selectedDate, day);
                  return _buildDayItem(
                    day: day,
                    isSelected: isSelected,
                    isToday: true,
                    confessionsMap: confessionsMap,
                    predictionsSet: predictionsSet,
                    missedDatesSet: missedDatesSet,
                    primaryColor: primaryColor,
                    onPrimary: onPrimary,
                    onSurface: onSurface,
                    isDark: isDark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem({
    required DateTime day,
    required bool isSelected,
    required bool isToday,
    required Map<DateTime, dynamic> confessionsMap,
    required Set<DateTime> predictionsSet,
    required Set<DateTime> missedDatesSet,
    required Color primaryColor,
    required Color onPrimary,
    required Color onSurface,
    required bool isDark,
  }) {
    final norm = RenovoDateUtils.normalizeDate(day);
    final hasConfession = confessionsMap.containsKey(norm);
    final isPredicted = predictionsSet.contains(norm);
    final isMissed = missedDatesSet.contains(norm);

    Color? backgroundColor;
    Color textColor = onSurface;
    Border? border;

    if (isSelected) {
      backgroundColor = primaryColor;
      textColor = onPrimary;
    } else if (isPredicted) {
      // Ring 1px Antique Gold for predicted Saturday
      border = Border.all(color: AppTheme.antiqueGold, width: 1);
      textColor = onSurface;
    } else if (isMissed) {
      border = Border.all(
        color: (isDark
            ? AppTheme.darkOnSurfaceVariant
            : AppTheme.lightOnSurfaceVariant).withValues(alpha: 0.35),
        width: 1,
      );
      textColor = isDark
          ? AppTheme.darkOnSurfaceVariant
          : AppTheme.lightOnSurfaceVariant;
    } else if (isToday) {
      backgroundColor = isDark
          ? AppTheme.darkSurfaceContainerLow
          : AppTheme.lightSurfaceContainerLow;
    }

    Color dotColor = Colors.transparent;
    if (hasConfession) {
      dotColor = isSelected ? onPrimary : AppTheme.sageEmerald;
    } else if (isPredicted) {
      dotColor = isSelected ? onPrimary : AppTheme.antiqueGold;
    } else if (isMissed) {
      dotColor = isSelected
          ? onPrimary
          : (isDark
                ? AppTheme.darkOnSurfaceVariant
                : AppTheme.lightOnSurfaceVariant).withValues(alpha: 0.6);
    }

    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
