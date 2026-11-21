import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_utils.dart';

/// Provider for the currently selected date.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return RenovoDateUtils.normalizeDate(DateTime.now());
  }

  void selectDate(DateTime date) {
    state = RenovoDateUtils.normalizeDate(date);
  }
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// Provider for the focused calendar month/view.
class FocusedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return RenovoDateUtils.normalizeDate(DateTime.now());
  }

  void setFocusedDay(DateTime day) {
    state = RenovoDateUtils.normalizeDate(day);
  }
}

final focusedDayProvider =
    NotifierProvider<FocusedDayNotifier, DateTime>(FocusedDayNotifier.new);
