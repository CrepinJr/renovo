import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../data/database/database_helper.dart';
import '../data/repositories/confession_repository.dart';
import '../providers/confessions_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/annual_report_section.dart';
import '../widgets/backup_confessions_modal.dart';
import '../widgets/sign_out_confirmation_modal.dart';

final lastSyncAtProvider = FutureProvider.family<DateTime?, String>(
  (ref, uid) => FirestoreConfessionRepository(uid: uid).getLastSyncedAt(),
);

class AccountCloudBackupScreen extends ConsumerStatefulWidget {
  const AccountCloudBackupScreen({super.key});

  @override
  ConsumerState<AccountCloudBackupScreen> createState() =>
      _AccountCloudBackupScreenState();
}

class _AccountCloudBackupScreenState
    extends ConsumerState<AccountCloudBackupScreen> {
  bool _isSigningIn = false;
  bool _isSyncing = false;

  Future<void> _signIn() async {
    setState(() => _isSigningIn = true);
    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw StateError('Google Sign-In completed without a Firebase user.');
      }

      if (await DatabaseHelper.instance.hasLocalConfessions() && mounted) {
        final didMerge = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BackUpConfessionsModal(uid: user.uid),
        );
        if (didMerge == true) {
          ref.invalidate(lastSyncAtProvider(user.uid));
        }
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Connexion impossible : $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _syncNow(User user) async {
    setState(() => _isSyncing = true);
    try {
      await FirestoreConfessionRepository(uid: user.uid).syncNow();
      ref.invalidate(confessionsProvider);
      ref.invalidate(parishesProvider);
      ref.invalidate(lastSyncAtProvider(user.uid));
      if (mounted) _showMessage('Synchronisation terminée.');
    } catch (error) {
      if (mounted) {
        _showMessage('Synchronisation impossible : $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppTheme.darkSurface : AppTheme.alabaster;
    final foreground = isDark
        ? AppTheme.darkOnSurface
        : AppTheme.lightOnSurface;
    final signedInUser = authState.asData?.value;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour au calendrier',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Text(
          'Compte & Sauvegarde',
          style: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            color: foreground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Changer le thème',
              onPressed: () =>
                  ref.read(themeModeProvider.notifier).toggleNext(),
              icon: Icon(_themeIcon(themeMode)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        authState.when(
                          data: (user) => user == null
                              ? _buildLocalCard(context)
                              : _buildConnectedCard(context, user),
                          loading: () => const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stackTrace) =>
                              _buildAuthError(context, error),
                        ),
                        const SizedBox(height: 24),
                        const AnnualReportSection(),
                      ],
                    ),
                  ),
                ),
                if (signedInUser != null)
                  _buildSignOutButton(context, signedInUser)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final lowSurface = isDark
        ? AppTheme.darkSurfaceContainerLow
        : AppTheme.lightSurfaceContainerLow;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: lowSurface,
                shape: BoxShape.circle,
                border: Border.all(color: outline),
              ),
              child: Icon(Icons.cloud_off, color: onSurfaceVariant, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              'Stockage local',
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vos dates de confession et notes spirituelles sont enregistrées '
              'uniquement sur ce téléphone. Connectez-vous pour sauvegarder et '
              'restaurer vos données en toute confidentialité.',
              style: TextStyle(color: onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSigningIn ? null : _signIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.liturgicalIndigo,
                  side: BorderSide(color: outline),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSigningIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleGLogo(),
                          SizedBox(width: 8),
                          Text('Continuer avec Google'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedCard(BuildContext context, User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final lastSync = ref.watch(lastSyncAtProvider(user.uid));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProfileAvatar(user: user, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName?.trim().isNotEmpty == true
                            ? user.displayName!.trim()
                            : 'Compte Google',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.sageTint,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.sageEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Synchro cloud active',
                      style: TextStyle(
                        color: AppTheme.onSageTint,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: outline, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Synchroniser maintenant',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastSync.when(
                          data: _lastSyncLabel,
                          loading: () => 'Chargement de la synchronisation…',
                          error: (error, stackTrace) =>
                              'Historique indisponible : $error',
                        ),
                        style: TextStyle(color: onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Synchroniser maintenant',
                  onPressed: _isSyncing ? null : () => _syncNow(user),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? AppTheme.darkSurfaceContainerLow
                        : AppTheme.lightSurfaceContainerLow,
                    side: BorderSide(color: outline),
                    foregroundColor: isDark
                        ? AppTheme.darkPrimary
                        : AppTheme.lightPrimary,
                  ),
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: TextButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SignOutConfirmationModal(uid: user.uid),
        ),
        icon: const Icon(Icons.logout, size: 16),
        label: const Text('Se déconnecter'),
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? AppTheme.darkOnSurfaceVariant
              : AppTheme.lightOnSurfaceVariant,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildAuthError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Impossible de vérifier l’état du compte : $error'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.invalidate(authStateProvider),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  String _lastSyncLabel(DateTime? date) {
    if (date == null) return 'Aucune synchronisation';
    final local = date.toLocal();
    final now = DateTime.now();
    if (now.difference(local) < const Duration(minutes: 1)) {
      return 'Dernière synchro à l’instant';
    }
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Dernière synchro à ${DateFormat('HH:mm', 'fr_FR').format(local)}';
    }
    return 'Dernière synchro le '
        '${DateFormat('d MMM yyyy à HH:mm', 'fr_FR').format(local)}';
  }

  IconData _themeIcon(ThemeMode mode) {
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

class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      color: Color(0xFF4285F4),
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, required this.size});

  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.displayName, user.email);
    final photoUrl = user.photoURL;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBackground = isDark
        ? AppTheme.darkPrimaryContainer
        : AppTheme.lightPrimaryContainer;
    final avatarForeground = isDark
        ? AppTheme.darkOnPrimaryContainer
        : AppTheme.lightOnPrimaryContainer;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: avatarBackground,
      child: photoUrl == null || photoUrl.isEmpty
          ? Text(
              initials,
              style: GoogleFonts.lora(
                fontSize: 20,
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
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: avatarForeground,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _initials(String? displayName, String? email) {
    final value = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : email?.split('@').first ?? '';
    final parts = value.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final result = parts.take(2).map((part) => part.substring(0, 1)).join();
    return result.isEmpty ? '?' : result.toUpperCase();
  }
}
