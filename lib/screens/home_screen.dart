import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';
import '../data/models/confession.dart';
import '../providers/confessions_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/selected_date_provider.dart';
import '../services/auth_service.dart';
import 'account_cloud_backup_screen.dart';
import 'settings_screen.dart';
import '../widgets/details_card.dart';
import '../widgets/legend_widget.dart';
import '../widgets/renovo_calendar_widget.dart';
import 'confession_form_sheet.dart';

/// Main Calendar & Details screen of Renovo.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(notificationServiceProvider);
    ref.listen(notificationServiceProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notifications locales indisponibles : $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    });
    ref.listen(confessionsProvider, (previous, next) {
      final confessions = next.asData?.value;
      if (confessions == null) return;
      _rescheduleReminders(ref, context, confessions);
    });

    final surfaceContainer = isDark
        ? AppTheme.darkSurfaceContainer
        : AppTheme.lightSurfaceContainer;
    final outlineColor = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: _NavigationDrawer(authState: authState),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: InkWell(
          key: const ValueKey('open-navigation-drawer'),
          onTap: () => scaffoldKey.currentState?.openDrawer(),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_rounded, size: 24, color: onSurface),
                const SizedBox(width: 8),
                Text(
                  'Renovo',
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: 'Aujourd’hui',
              child: InkWell(
                key: const ValueKey('select-today'),
                onTap: () {
                  final today = RenovoDateUtils.normalizeDate(DateTime.now());
                  ref.read(selectedDateProvider.notifier).selectDate(today);
                  ref.read(focusedDayProvider.notifier).setFocusedDay(today);
                },
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: surfaceContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: outlineColor, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.today_outlined, size: 18, color: onSurface),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: 'Compte & Sauvegarde',
              child: InkWell(
                key: const ValueKey('open-account-from-avatar'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountCloudBackupScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: surfaceContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: outlineColor, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: _UserAvatar(authState: authState, size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalendarLegendWidget(),
              SizedBox(height: 8),
              RenovoCalendarWidget(),
              SizedBox(height: 4),
              DetailsCard(),
              // Guarantees ample scrolling space so FAB never occludes any card content
              SizedBox(height: 96),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouvel enregistrement',
        backgroundColor: AppTheme.liturgicalIndigo,
        foregroundColor: const Color(0xFFFAF8F5),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 24),
        onPressed: () {
          final selectedDate = RenovoDateUtils.normalizeDate(
            ref.read(selectedDateProvider),
          );
          final today = RenovoDateUtils.normalizeDate(DateTime.now());
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => ConfessionFormSheet(
              initialDate: selectedDate.isAfter(today) ? today : selectedDate,
            ),
          );
        },
      ),
    );
  }
}

void _rescheduleReminders(
  WidgetRef ref,
  BuildContext context,
  List<Confession> confessions,
) {
  unawaited(() async {
    try {
      final service = await ref.read(notificationServiceProvider.future);
      await service.rescheduleReminders(confessions: confessions);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription('while rescheduling confession reminders'),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de reprogrammer les rappels : $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }());
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({required this.authState});

  final AsyncValue<User?> authState;

  @override
  Widget build(BuildContext context) {
    final user = authState.asData?.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppTheme.darkSurfaceContainer
        : AppTheme.lightSurfaceContainer;
    final cardSurface = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final foreground = isDark
        ? AppTheme.darkOnSurface
        : AppTheme.lightOnSurface;
    final foregroundVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final connected = user != null;
    final statusLabel = connected
        ? 'Synchro cloud active'
        : authState.hasError
        ? 'Connexion indisponible'
        : authState.isLoading
        ? 'Vérification en cours'
        : 'Hors ligne • stockage local';
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : user == null
        ? 'Mode invité'
        : user.email ?? 'Compte Renovo';

    return Drawer(
      width: 304,
      backgroundColor: surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.liturgicalIndigo,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.church,
                      size: 21,
                      color: AppTheme.antiqueGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Renovo',
                          style: GoogleFonts.lora(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                        Text(
                          'Suivi spirituel personnel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: foregroundVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer le tiroir',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: foregroundVariant),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardSurface,
                border: Border.all(color: outline),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _UserAvatar(authState: authState, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: foreground,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user?.email ??
                                  'Vos données restent sur cet appareil',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: foregroundVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: connected
                          ? AppTheme.sageTint
                          : (isDark
                                ? AppTheme.darkSurfaceContainerLow
                                : AppTheme.lightSurfaceContainerLow),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          connected ? Icons.circle : Icons.cloud_off,
                          size: connected ? 8 : 13,
                          color: connected
                              ? AppTheme.sageEmerald
                              : foregroundVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.plusJakartaSans(
                              color: connected
                                  ? AppTheme.onSageTint
                                  : foregroundVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _DrawerDestination(
              icon: Icons.calendar_month_outlined,
              label: 'Calendrier',
              selected: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerDestination(
              icon: Icons.cloud_done_outlined,
              label: 'Compte & Sauvegarde',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountCloudBackupScreen(),
                  ),
                );
              },
            ),
            _DrawerDestination(
              icon: Icons.settings_outlined,
              label: 'Paramètres',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  Divider(color: outline),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Renovo • v2.1.0',
                      style: GoogleFonts.plusJakartaSans(
                        color: foregroundVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerDestination extends StatelessWidget {
  const _DrawerDestination({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? AppTheme.darkOnSurface
        : AppTheme.lightOnSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: isDark
            ? AppTheme.darkPrimaryContainer
            : AppTheme.lightPrimaryContainer,
        selectedColor: isDark
            ? AppTheme.darkOnPrimaryContainer
            : AppTheme.lightOnPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, size: 20, color: selected ? null : foreground),
        title: Text(label),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: selected ? null : foreground,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.authState, required this.size});

  final AsyncValue<User?> authState;
  final double size;

  @override
  Widget build(BuildContext context) {
    final user = authState.asData?.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBackground = isDark
        ? AppTheme.darkPrimaryContainer
        : AppTheme.lightPrimaryContainer;
    final avatarForeground = isDark
        ? AppTheme.darkOnPrimaryContainer
        : AppTheme.lightOnPrimaryContainer;
    final initials = _userInitials(user?.displayName, user?.email);
    final photoUrl = user?.photoURL;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: avatarBackground,
            child: photoUrl == null || photoUrl.isEmpty
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.w600,
                      color: avatarForeground,
                    ),
                  )
                : ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: size * 0.32,
                            fontWeight: FontWeight.w600,
                            color: avatarForeground,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (user != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: BoxDecoration(
                  color: AppTheme.sageEmerald,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkSurfaceContainer
                        : AppTheme.lightSurfaceContainer,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  size: size * 0.25,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _userInitials(String? displayName, String? email) {
  final value = displayName?.trim().isNotEmpty == true
      ? displayName!.trim()
      : email?.split('@').first ?? '';
  final parts = value.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final initials = parts.take(2).map((part) => part.substring(0, 1)).join();
  return initials.isEmpty ? '?' : initials.toUpperCase();
}
