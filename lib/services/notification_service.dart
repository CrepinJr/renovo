import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/confession_frequency.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/prediction_calculator.dart';
import '../core/utils/reminder_calculator.dart';
import '../data/models/confession.dart';

class ReminderPreferences {
  const ReminderPreferences({
    this.enabled = true,
    this.hour = 9,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderPreferences copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderPreferences(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    required this.onMarkDone,
    required this.onOpenDate,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'renovo_reminders';
  static const channelName = 'Rappels de confession';
  static const testNotificationBody =
      'Ceci est un aperçu de vos rappels Renovo.';
  static const _enabledKey = 'reminders_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _testNotificationId = 2147483000;

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<void> Function(DateTime date) onMarkDone;
  final void Function(DateTime date) onOpenDate;
  Future<void>? _initialization;
  Future<void> _rescheduling = Future<void>.value();

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    setLocalTimezone(
      timezoneName: localTimezone.identifier,
      systemOffset: DateTime.now().timeZoneOffset,
    );

    final initialized = await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              channelId,
              actions: [
                DarwinNotificationAction.plain(
                  'mark_done',
                  'Marquer effectuée',
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain('dismiss', 'Plus tard'),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _dispatchResponse,
    );
    if (initialized != true) {
      throw StateError('Impossible d’initialiser les notifications locales.');
    }

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true && response != null) {
      _dispatchResponse(response);
    }

    if ((await loadPreferences()).enabled) {
      await requestPermissions();
    }
  }

  @visibleForTesting
  static tz.Location setLocalTimezone({
    required String timezoneName,
    required Duration systemOffset,
    DateTime? now,
  }) {
    tz_data.initializeTimeZones();
    late final tz.Location location;
    try {
      location = tz.getLocation(timezoneName);
    } on tz.LocationNotFoundException {
      final instant = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
      final locations = tz.timeZoneDatabase.locations;
      final preferredLocations = [
        locations['Africa/Lagos'],
        ...locations.values.where(
          (candidate) => candidate.name.startsWith('Etc/GMT'),
        ),
      ];
      final candidates = [
        ...preferredLocations.whereType<tz.Location>(),
        ...locations.values,
      ];
      location = candidates.firstWhere(
        (candidate) => candidate.timeZone(instant).offset == systemOffset,
        orElse: () => tz.UTC,
      );
    }
    tz.setLocalLocation(location);
    return location;
  }

  Future<ReminderPreferences> loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    return ReminderPreferences(
      enabled: preferences.getBool(_enabledKey) ?? true,
      hour: preferences.getInt(_hourKey) ?? 9,
      minute: preferences.getInt(_minuteKey) ?? 0,
    );
  }

  Future<void> savePreferences(ReminderPreferences value) async {
    if (value.hour < 0 || value.hour > 23) {
      throw ArgumentError.value(
        value.hour,
        'hour',
        'Must be between 0 and 23.',
      );
    }
    if (value.minute < 0 || value.minute > 59) {
      throw ArgumentError.value(
        value.minute,
        'minute',
        'Must be between 0 and 59.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final enabledSaved = await preferences.setBool(_enabledKey, value.enabled);
    final hourSaved = await preferences.setInt(_hourKey, value.hour);
    final minuteSaved = await preferences.setInt(_minuteKey, value.minute);
    if (!enabledSaved || !hourSaved || !minuteSaved) {
      throw StateError('Impossible d’enregistrer les préférences de rappel.');
    }
  }

  Future<bool> requestPermissions({bool requestExactAlarms = false}) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notificationPermission = await android
          ?.requestNotificationsPermission();
      if (notificationPermission == false) return false;
      if (requestExactAlarms) {
        await android?.requestExactAlarmsPermission();
      }
      return true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final permission = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return permission != false;
    }
    return true;
  }

  Future<void> rescheduleReminders({
    required Iterable<Confession> confessions,
    DateTime? now,
  }) {
    final snapshot = confessions.toList();
    final operation = _rescheduling.then(
      (_) => _rescheduleReminders(snapshot, now),
    );
    _rescheduling = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  Future<void> _rescheduleReminders(
    List<Confession> confessions,
    DateTime? now,
  ) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
    final preferences = await loadPreferences();
    if (!preferences.enabled) return;
    final storedCycleWeeks = (await SharedPreferences.getInstance()).getInt(
      ConfessionFrequency.preferenceKey,
    );
    final cycleWeeks = ConfessionFrequency.clampWeeks(
      storedCycleWeeks ?? ConfessionFrequency.defaultWeeks,
    );

    final normalizedConfessions = confessions
        .map((confession) => confession.normalizedDate)
        .toList();
    if (normalizedConfessions.isEmpty) return;
    var latestConfessionDate = normalizedConfessions.first;
    for (final date in normalizedConfessions.skip(1)) {
      if (date.isAfter(latestConfessionDate)) latestConfessionDate = date;
    }

    final currentTime = now ?? DateTime.now();
    final predictions = PredictionCalculator.calculatePredictions(
      latestConfessionDate: latestConfessionDate,
      cycleWeeks: cycleWeeks,
      now: currentTime,
    );
    final deadline = predictions.where((date) {
      final deadlineEnd = date.add(const Duration(hours: 72));
      return !currentTime.isAfter(deadlineEnd);
    }).firstOrNull;
    if (deadline == null) return;

    final reminders = ReminderCalculator.calculateReminderTimes(
      deadline: deadline,
      hour: preferences.hour,
      minute: preferences.minute,
    );
    var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final exactAlarmsAllowed = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.canScheduleExactNotifications();
      if (exactAlarmsAllowed != true) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }
    for (var index = 0; index < reminders.length; index++) {
      final reminder = reminders[index];
      if (!reminder.scheduledAt.isAfter(currentTime)) continue;
      final content = reminderContentFor(reminder.milestone);
      await _plugin.zonedSchedule(
        id: _notificationId(deadline, index),
        title: content.title,
        body: content.body,
        scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
        notificationDetails: _notificationDetails,
        payload: jsonEncode({
          'date': RenovoDateUtils.normalizeDate(deadline).toIso8601String(),
          'type': 'reminder',
        }),
        androidScheduleMode: scheduleMode,
      );
    }
  }

  Future<void> sendTestNotification() async {
    await initialize();
    final today = RenovoDateUtils.normalizeDate(DateTime.now());
    await _plugin.show(
      id: _testNotificationId,
      title: channelName,
      body: testNotificationBody,
      notificationDetails: _notificationDetails,
      payload: jsonEncode({'date': today.toIso8601String(), 'type': 'test'}),
    );
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Rappels personnels des prochaines échéances.',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      actions: [
        AndroidNotificationAction(
          'mark_done',
          'Marquer effectuée',
          showsUserInterface: true,
        ),
        AndroidNotificationAction('dismiss', 'Plus tard'),
      ],
    ),
    iOS: DarwinNotificationDetails(categoryIdentifier: channelId),
  );

  int _notificationId(DateTime deadline, int milestoneIndex) {
    return int.parse(
      '${deadline.year}${deadline.month.toString().padLeft(2, '0')}'
      '${deadline.day.toString().padLeft(2, '0')}$milestoneIndex',
    );
  }

  @visibleForTesting
  static ({String title, String body}) reminderContentFor(
    ReminderMilestone milestone,
  ) {
    return switch (milestone) {
      ReminderMilestone.weekBefore => (
        title: 'Confession dans 7 jours',
        body: 'Préparez votre cœur pour samedi prochain.',
      ),
      ReminderMilestone.threeDaysBefore => (
        title: 'Confession dans 3 jours',
        body: 'Votre prochaine échéance approche.',
      ),
      ReminderMilestone.dayBefore => (
        title: 'Confession demain',
        body: 'Rappel : confession prévue demain.',
      ),
      ReminderMilestone.dayAfter => (
        title: 'Confession hier ?',
        body: "Pensez à l'enregistrer si elle a eu lieu.",
      ),
      ReminderMilestone.threeDaysAfter => (
        title: 'Dernier rappel (72h)',
        body: 'Sera marquée non effectuée ce soir.',
      ),
    };
  }

  void _dispatchResponse(NotificationResponse response) {
    unawaited(
      _handleResponse(response)
          .catchError((Object error, StackTrace stackTrace) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stackTrace,
                context: ErrorDescription(
                  'while handling a Renovo notification action',
                ),
              ),
            );
          }),
    );
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic> || decoded['date'] is! String) {
      throw FormatException('Invalid Renovo notification payload: $payload');
    }

    final date = RenovoDateUtils.normalizeDate(
      DateTime.parse(decoded['date'] as String),
    );
    if (response.actionId == 'mark_done') {
      final today = RenovoDateUtils.normalizeDate(DateTime.now());
      if (date.isAfter(today)) {
        throw ArgumentError(
          'Une confession effectuée ne peut pas être enregistrée dans le futur.',
        );
      }
      await onMarkDone(date);
    } else if (response.actionId == null) {
      onOpenDate(date);
    }
  }
}
