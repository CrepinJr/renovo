import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';
import '../data/models/confession.dart';
import '../data/repositories/confession_repository.dart';
import '../providers/confessions_provider.dart';
import '../providers/predictions_provider.dart';
import '../providers/selected_date_provider.dart';
import '../screens/confession_form_sheet.dart';

/// Contextual details card matching the Google Stitch design:
/// Elevated stationery card with 20px corners, pill indicators (Emerald for completed,
/// Antique Gold for predicted, Surface low for empty), full French date, and actions.
class DetailsCard extends ConsumerWidget {
  const DetailsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final confessionsMap = ref.watch(confessionsMapProvider);
    final predictionsSet = ref.watch(predictionsSetProvider);

    final normalized = RenovoDateUtils.normalizeDate(selectedDate);
    final confession = confessionsMap[normalized];
    final isPredicted = predictionsSet.contains(normalized);
    final today = RenovoDateUtils.normalizeDate(DateTime.now());
    final isFutureDate = normalized.isAfter(today);

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
        width: double.infinity,
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Pill
            if (confession != null)
              _buildPill(
                backgroundColor: isDark ? const Color(0xFF003824) : AppTheme.sageTint,
                textColor: isDark ? const Color(0xFF6EE7B7) : AppTheme.onSageTint,
                dotColor: AppTheme.sageEmerald,
                label: 'Confession effectuée',
              )
            else if (isPredicted)
              _buildPill(
                backgroundColor: isDark ? const Color(0xFF442C00) : AppTheme.goldTint,
                textColor: isDark ? const Color(0xFFFDE68A) : AppTheme.onGoldTint,
                dotColor: AppTheme.antiqueGold,
                label: 'Prochaine confession prévue',
              )
            else
              _buildPill(
                backgroundColor: isDark
                    ? AppTheme.darkSurfaceContainerLow
                    : AppTheme.lightSurfaceContainerLow,
                textColor: onSurfaceVariant,
                dotColor: onSurfaceVariant,
                label: 'Aucune confession enregistrée',
              ),

            const SizedBox(height: 12),

            // French Date Headline
            Text(
              RenovoDateUtils.formatFullFrenchDate(selectedDate),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: onSurface,
              ),
            ),

            const SizedBox(height: 4),

            // Helper text
            Text(
              confession != null
                  ? 'Enregistrée dans votre suivi personnel'
                  : 'Rythme automatique de 3 semaines',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: onSurfaceVariant,
              ),
            ),

            // Details for Confession
            if (confession != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: outlineColor, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.church_outlined, size: 18, color: onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            confession.parish,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (confession.notes != null && confession.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_outlined, size: 18, color: onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              confession.notes!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!isFutureDate) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditSheet(context, confession),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      onPressed: () => _confirmDelete(context, ref, confession),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ] else if (isPredicted && !isFutureDate) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openAddSheet(context, initialDate: selectedDate),
                  child: Text(
                    'Marquer comme effectuée',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ] else if (!isFutureDate) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddSheet(context, initialDate: selectedDate),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Ajouter une confession pour ce jour'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required Color backgroundColor,
    required Color textColor,
    required Color dotColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openAddSheet(BuildContext context, {required DateTime initialDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConfessionFormSheet(initialDate: initialDate),
    );
  }

  void _openEditSheet(BuildContext context, Confession confession) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConfessionFormSheet(confessionToEdit: confession),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Confession confession,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la confession ?'),
        content: Text(
          'Voulez-vous supprimer l’enregistrement du ${RenovoDateUtils.formatShortDate(confession.date)} à ${confession.parish} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        (confession.id != null || confession.remoteId != null)) {
      final status = await ref
          .read(confessionsProvider.notifier)
          .deleteConfession(confession);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == ConfessionWriteStatus.pending
                  ? 'Suppression en attente de synchronisation.'
                  : 'Confession supprimée.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
