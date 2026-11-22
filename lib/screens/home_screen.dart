import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';
import '../providers/selected_date_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'account_cloud_backup_screen.dart';
import '../widgets/details_card.dart';
import '../widgets/legend_widget.dart';
import '../widgets/renovo_calendar_widget.dart';
import 'confession_form_sheet.dart';

/// Main Calendar & Details screen of Renovo, calibrated to the Stitch design:
/// Lora headline-lg branding, pill icon utility buttons for Today and Theme toggle,
/// clean legend pill, monthly calendar card, details card, and compact circular FAB.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceContainer = isDark ? AppTheme.darkSurfaceContainer : AppTheme.lightSurfaceContainer;
    final outlineColor = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Renovo',
          style: GoogleFonts.lora(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
            color: onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _BackupStatusButton(
              authState: authState,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountCloudBackupScreen(),
                  ),
                );
              },
            ),
          ),
          // Today button (circular 36x36 outline container)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
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
                child: Icon(
                  Icons.today_outlined,
                  size: 18,
                  color: onSurface,
                ),
              ),
            ),
          ),
          // Theme switch button (circular 36x36 outline container)
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: InkWell(
              onTap: () {
                ref.read(themeModeProvider.notifier).toggleNext();
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
                child: Icon(
                  _getThemeIcon(themeMode),
                  size: 18,
                  color: onSurface,
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
          final selectedDate = ref.read(selectedDateProvider);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => ConfessionFormSheet(initialDate: selectedDate),
          );
        },
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}

class _BackupStatusButton extends StatelessWidget {
  const _BackupStatusButton({required this.authState, required this.onPressed});

  final AsyncValue<User?> authState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final user = authState.asData?.value;
    final isGuest = authState.hasValue && user == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final background = isDark
        ? AppTheme.darkSurfaceContainer
        : AppTheme.lightSurfaceContainer;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;

    return Semantics(
      button: true,
      label: user == null
          ? isGuest
                ? 'Statut de sauvegarde : Local'
                : authState.hasError
                ? 'Statut de sauvegarde indisponible'
                : 'Vérification du compte'
          : 'Compte connecté : ${user.email ?? user.displayName ?? ''}',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          height: 36,
          padding: isGuest
              ? const EdgeInsets.symmetric(horizontal: 12)
              : const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: outline),
          ),
          child: isGuest
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 15, color: foreground),
                    const SizedBox(width: 4),
                    Text(
                      'Local',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                )
              : user != null
              ? _SignedInStatusAvatar(user: user)
              : SizedBox(
                  width: 30,
                  height: 30,
                  child: authState.hasError
                      ? Icon(Icons.cloud_off, size: 15, color: foreground)
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        ),
                ),
        ),
      ),
    );
  }
}

class _SignedInStatusAvatar extends StatelessWidget {
  const _SignedInStatusAvatar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final initials = _userInitials(user.displayName, user.email);
    final photoUrl = user.photoURL;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBackground = isDark
        ? AppTheme.darkPrimaryContainer
        : AppTheme.lightPrimaryContainer;
    final avatarForeground = isDark
        ? AppTheme.darkOnPrimaryContainer
        : AppTheme.lightOnPrimaryContainer;
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: avatarBackground,
            child: photoUrl == null || photoUrl.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ).copyWith(color: avatarForeground),
                  )
                : ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ).copyWith(color: avatarForeground),
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 13,
              height: 13,
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
              child: const Icon(Icons.check, size: 9, color: Colors.white),
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
