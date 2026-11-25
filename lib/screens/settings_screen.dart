import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/confession_frequency.dart';
import '../providers/frequency_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _quickFrequencies = [1, 2, 3, 4, 6, 8];
  bool _isTestingReminder = false;

  @override
  Widget build(BuildContext context) {
    final frequency = ref.watch(confessionFrequencyWeeksProvider);
    final reminders = ref.watch(reminderSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final weeks = frequency.asData?.value ?? ConfessionFrequency.defaultWeeks;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppTheme.darkSurface : AppTheme.alabaster;
    final foreground = isDark
        ? AppTheme.darkOnSurface
        : AppTheme.lightOnSurface;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Text(
          'Paramètres',
          style: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            color: foreground,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFrequencyCard(frequency, weeks),
                  const SizedBox(height: 16),
                  _buildReminderCard(reminders),
                  const SizedBox(height: 16),
                  _buildAppearanceCard(themeMode),
                  const SizedBox(height: 24),
                  Text(
                    'Renovo • Version 2.1.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? AppTheme.darkOnSurfaceVariant
                          : AppTheme.lightOnSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vos données restent privées et sécurisées.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? AppTheme.darkOnSurfaceVariant
                          : AppTheme.lightOnSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyCard(AsyncValue<int> frequency, int weeks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? AppTheme.darkOnSurface
        : AppTheme.lightOnSurface;
    final foregroundVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final lowSurface = isDark
        ? AppTheme.darkSurfaceContainerLow
        : AppTheme.lightSurfaceContainerLow;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final selectedContainer = isDark
        ? AppTheme.darkPrimaryContainer
        : AppTheme.lightPrimaryContainer;
    final selectedForeground = isDark
        ? AppTheme.darkOnPrimaryContainer
        : AppTheme.lightOnPrimaryContainer;
    final canEdit = frequency.asData != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rythme de confession',
              style: GoogleFonts.lora(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Définissez l’intervalle souhaité entre deux confessions.',
              style: GoogleFonts.plusJakartaSans(
                color: foregroundVariant,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (frequency.hasError) ...[
              const SizedBox(height: 8),
              Text(
                'Fréquence indisponible : ${frequency.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _quickFrequencies)
                  ChoiceChip(
                    label: Text(
                      option == 3 ? '3 sem. (Recommandé)' : '$option sem.',
                    ),
                    selected: weeks == option,
                    onSelected: canEdit
                        ? (selected) {
                            if (selected) _setFrequency(option);
                          }
                        : null,
                    selectedColor: selectedContainer,
                    backgroundColor: lowSurface,
                    labelStyle: TextStyle(
                      color: weeks == option ? selectedForeground : foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: weeks == option ? AppTheme.antiqueGold : outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: outline),
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('frequency-decrement'),
                    tooltip: 'Réduire d’une semaine',
                    onPressed: canEdit && weeks > ConfessionFrequency.minWeeks
                        ? () => _setFrequency(weeks - 1)
                        : null,
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.darkSurfaceContainer
                          : AppTheme.lightSurfaceContainer,
                      side: BorderSide(color: outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      _frequencyLabel(weeks),
                      key: const ValueKey('frequency-label'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('frequency-increment'),
                    tooltip: 'Augmenter d’une semaine',
                    onPressed: canEdit && weeks < ConfessionFrequency.maxWeeks
                        ? () => _setFrequency(weeks + 1)
                        : null,
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.darkSurfaceContainer
                          : AppTheme.lightSurfaceContainer,
                      side: BorderSide(color: outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _frequencyLabel(int weeks) {
    final days = weeks * 7;
    if (weeks == 1) return 'Chaque semaine ($days jours)';
    return 'Toutes les $weeks semaines ($days jours)';
  }

  Future<void> _setFrequency(int weeks) async {
    try {
      await ref
          .read(confessionFrequencyWeeksProvider.notifier)
          .setFrequencyWeeks(weeks);
    } catch (error) {
      if (mounted) {
        _showMessage('Impossible d’enregistrer le rythme : $error', true);
      }
    }
  }

  Widget _buildReminderCard(AsyncValue<ReminderPreferences> settings) {
    final preferences = settings.asData?.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? AppTheme.darkOnSurface
        : AppTheme.lightOnSurface;
    final foregroundVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.liturgicalIndigo;
    final lowSurface = isDark
        ? AppTheme.darkSurfaceContainerLow
        : AppTheme.lightSurfaceContainerLow;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rappels & Notifications',
                    style: GoogleFonts.lora(
                      color: foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (preferences == null && settings.hasError)
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  )
                else if (preferences == null)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch.adaptive(
                    value: preferences.enabled,
                    onChanged: _setRemindersEnabled,
                  ),
              ],
            ),
            if (settings.hasError) ...[
              const SizedBox(height: 8),
              Text(
                'Préférences de rappel indisponibles : ${settings.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: preferences == null
                  ? null
                  : () => _pickReminderTime(context, preferences),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                backgroundColor: isDark
                    ? AppTheme.darkSurface
                    : AppTheme.lightSurface,
                side: BorderSide(color: outline),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('Heure des rappels')),
                  Icon(Icons.schedule, color: primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    preferences == null
                        ? '--:--'
                        : DateFormat('HH:mm').format(
                            DateTime(
                              2000,
                              1,
                              1,
                              preferences.hour,
                              preferences.minute,
                            ),
                          ),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _reminderSummaryLine(
              foregroundVariant,
              AppTheme.antiqueGold,
              'Avant l’échéance : 7 jours • 3 jours • 24h avant',
            ),
            const SizedBox(height: 6),
            _reminderSummaryLine(
              foregroundVariant,
              foregroundVariant.withValues(alpha: 0.6),
              'Après l’échéance : 24h • 72h après (puis marquée non effectuée)',
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isTestingReminder ? null : _sendTestNotification,
                icon: _isTestingReminder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active_outlined, size: 16),
                label: const Text('Tester une notification'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  backgroundColor: lowSurface,
                  side: BorderSide(color: outline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reminderSummaryLine(Color textColor, Color markerColor, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _setRemindersEnabled(bool enabled) async {
    try {
      await ref.read(reminderSettingsProvider.notifier).setEnabled(enabled);
      if (enabled && mounted) _showMessage('Rappels activés.');
    } catch (error) {
      if (mounted) {
        _showMessage('Impossible de modifier les rappels : $error', true);
      }
    }
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    ReminderPreferences preferences,
  ) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: preferences.hour,
        minute: preferences.minute,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selectedTime == null) return;

    try {
      await ref
          .read(reminderSettingsProvider.notifier)
          .setTime(hour: selectedTime.hour, minute: selectedTime.minute);
    } catch (error) {
      if (mounted) {
        _showMessage('Impossible d’enregistrer l’heure : $error', true);
      }
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isTestingReminder = true);
    try {
      final service = await ref.read(notificationServiceProvider.future);
      await service.sendTestNotification();
      if (mounted) _showMessage('Notification de test envoyée.');
    } catch (error) {
      if (mounted) _showMessage('Envoi du test impossible : $error', true);
    } finally {
      if (mounted) setState(() => _isTestingReminder = false);
    }
  }

  Widget _buildAppearanceCard(ThemeMode mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final unselectedBackground = isDark
        ? AppTheme.darkSurfaceContainerLow
        : AppTheme.lightSurfaceContainerLow;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Apparence',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Système')),
                ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                _setThemeMode(selection.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? AppTheme.liturgicalIndigo
                      : unselectedBackground;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? AppTheme.alabaster
                      : foregroundVariant;
                }),
                side: WidgetStateProperty.resolveWith((states) {
                  return BorderSide(
                    color: states.contains(WidgetState.selected)
                        ? AppTheme.liturgicalIndigo
                        : outline,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    try {
      await ref.read(themeModeProvider.notifier).setThemeMode(mode);
    } catch (error) {
      if (mounted) {
        _showMessage('Impossible d’enregistrer le thème : $error', true);
      }
    }
  }

  void _showMessage(String message, [bool isError = false]) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : AppTheme.sageEmerald,
        ),
      );
  }
}
