import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../data/database/database_helper.dart';
import '../data/repositories/confession_repository.dart';
import '../services/auth_service.dart';

class SignOutConfirmationModal extends ConsumerStatefulWidget {
  const SignOutConfirmationModal({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<SignOutConfirmationModal> createState() =>
      _SignOutConfirmationModalState();
}

class _SignOutConfirmationModalState
    extends ConsumerState<SignOutConfirmationModal> {
  bool _isSigningOut = false;
  Object? _error;

  Future<void> _signOut({required bool keepLocalCopy}) async {
    setState(() {
      _isSigningOut = true;
      _error = null;
    });

    try {
      if (keepLocalCopy) {
        final cloudConfessions = await FirestoreConfessionRepository(
          uid: widget.uid,
        ).getAllConfessions();
        await LocalConfessionRepository().addConfessionsIfAbsent(
          cloudConfessions,
        );
      } else {
        await DatabaseHelper.instance.clearAllConfessions();
      }

      await ref.read(authServiceProvider).signOut();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppTheme.darkSurfaceContainer
        : AppTheme.lightSurfaceContainer;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;
    final onSurfaceVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final iconColor = isDark ? AppTheme.darkPrimary : AppTheme.liturgicalIndigo;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: outline),
            left: BorderSide(color: outline),
            right: BorderSide(color: outline),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: outline,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkPrimaryContainer
                      : AppTheme.lightPrimaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: outline),
                ),
                child: Icon(Icons.cloud_done, size: 26, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Se déconnecter du compte ?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vos données restent en sécurité dans votre compte Google. '
                'Que souhaitez-vous afficher sur cet appareil en mode local ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 20),
              _SignOutOption(
                title: 'Conserver une copie sur l’appareil',
                description:
                    'Vos confessions restent visibles dans le calendrier en mode local.',
                icon: Icons.smartphone,
                foregroundColor: AppTheme.onLiturgicalIndigo,
                backgroundColor: AppTheme.liturgicalIndigo,
                onTap: _isSigningOut
                    ? null
                    : () => _signOut(keepLocalCopy: true),
              ),
              const SizedBox(height: 12),
              _SignOutOption(
                title: 'Vider le calendrier local',
                description:
                    'Repartir d’un calendrier vierge sur ce téléphone. '
                    'Vos données seront restaurées à la prochaine connexion.',
                icon: Icons.restart_alt,
                foregroundColor: onSurface,
                backgroundColor: isDark
                    ? AppTheme.darkSurface
                    : AppTheme.alabaster,
                borderColor: outline,
                descriptionColor: onSurfaceVariant,
                onTap: _isSigningOut
                    ? null
                    : () => _signOut(keepLocalCopy: false),
              ),
              if (_isSigningOut) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Déconnexion impossible : $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSigningOut
                    ? null
                    : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: onSurfaceVariant),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutOption extends StatelessWidget {
  const _SignOutOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onTap,
    this.borderColor,
    this.descriptionColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;
  final Color? descriptionColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor == null ? null : Border.all(color: borderColor!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: foregroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: foregroundColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: descriptionColor ?? foregroundColor.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
