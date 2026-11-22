import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/confession_repository.dart';
import '../providers/confessions_provider.dart';

class BackUpConfessionsModal extends ConsumerStatefulWidget {
  const BackUpConfessionsModal({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<BackUpConfessionsModal> createState() =>
      _BackUpConfessionsModalState();
}

class _BackUpConfessionsModalState
    extends ConsumerState<BackUpConfessionsModal> {
  bool _isMerging = false;
  bool _didMerge = false;
  Object? _error;

  Future<void> _mergeAndSync() async {
    setState(() {
      _isMerging = true;
      _error = null;
    });

    try {
      await FirestoreConfessionRepository(uid: widget.uid)
          .migrateLocalToCloud(widget.uid);
      ref.invalidate(confessionsProvider);
      ref.invalidate(parishesProvider);
      if (mounted) setState(() => _didMerge = true);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _isMerging = false);
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
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkPrimaryContainer
                            : AppTheme.lightPrimaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: outline),
                      ),
                      child: Icon(
                        _didMerge ? Icons.cloud_done : Icons.cloud_sync,
                        size: 28,
                        color: iconColor,
                      ),
                    ),
                    if (!_didMerge)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.antiqueGold,
                            shape: BoxShape.circle,
                            border: Border.all(color: surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _didMerge
                    ? 'Sauvegarde terminée'
                    : 'Sauvegarder vos confessions ?',
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
                _didMerge
                    ? 'Vos confessions locales ont été fusionnées dans votre '
                          'compte Google.'
                    : 'Fusionnez vos confessions enregistrées localement dans '
                          'votre compte Google pour ne jamais les perdre lors '
                          'd’un changement de téléphone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurfaceVariant, height: 1.5),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'La sauvegarde a échoué : $_error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isMerging
                      ? null
                      : _didMerge
                      ? () => Navigator.of(context).pop(true)
                      : _mergeAndSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.liturgicalIndigo,
                    foregroundColor: AppTheme.onLiturgicalIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isMerging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _didMerge ? 'Terminé' : 'Fusionner et synchroniser',
                        ),
                ),
              ),
              if (!_didMerge) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isMerging
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Ignorer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
