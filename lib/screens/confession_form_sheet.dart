import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';
import '../data/models/confession.dart';
import '../providers/confessions_provider.dart';

/// Modal bottom sheet for adding or editing an effective confession.
/// Replicates the Stitch "Nouvelle confession" design with 24px top corners,
/// date selector pill, church icon parish input with quick-select chips,
/// spiritual notes with privacy hint, and full keyboard-aware scrolling.
class ConfessionFormSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final Confession? confessionToEdit;

  const ConfessionFormSheet({
    super.key,
    this.initialDate,
    this.confessionToEdit,
  });

  @override
  ConsumerState<ConfessionFormSheet> createState() => _ConfessionFormSheetState();
}

class _ConfessionFormSheetState extends ConsumerState<ConfessionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _parishController;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.confessionToEdit != null) {
      _selectedDate = widget.confessionToEdit!.date;
      _parishController = TextEditingController(text: widget.confessionToEdit!.parish);
      _notesController = TextEditingController(text: widget.confessionToEdit!.notes ?? '');
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _parishController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _parishController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = RenovoDateUtils.normalizeDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final parish = _parishController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    try {
      if (widget.confessionToEdit != null) {
        final updated = widget.confessionToEdit!.copyWith(
          date: _selectedDate,
          parish: parish,
          notes: notes,
        );
        await ref.read(confessionsProvider.notifier).updateConfession(updated);
      } else {
        await ref.read(confessionsProvider.notifier).addConfession(
              date: _selectedDate,
              parish: parish,
              notes: notes,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.confessionToEdit != null
                  ? 'Confession mise à jour.'
                  : 'Confession enregistrée.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l’enregistrement : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceContainer = isDark ? AppTheme.darkSurfaceContainer : AppTheme.lightSurfaceContainer;
    final outlineColor = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;
    final onSurfaceVariant = isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.lightOnSurfaceVariant;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final onPrimary = isDark ? AppTheme.darkOnPrimary : AppTheme.lightOnPrimary;
    final surfaceLow = isDark ? AppTheme.darkSurfaceContainerLow : AppTheme.lightSurfaceContainerLow;

    final parishesAsync = ref.watch(parishesProvider);
    final existingParishes = parishesAsync.asData?.value ?? [];
    final quickParishes = existingParishes.isNotEmpty
        ? existingParishes.take(4).toList()
        : const ['St Joseph', 'Cathédrale', 'Notre-Dame'];

    final isEditing = widget.confessionToEdit != null;

    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: outlineColor, width: 1),
          left: BorderSide(color: outlineColor, width: 1),
          right: BorderSide(color: outlineColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: outlineColor,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Sheet Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Modifier la confession' : 'Nouvelle confession',
                      style: GoogleFonts.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                        color: onSurface,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: outlineColor, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date Selector Pill
                Text(
                  'Date',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: outlineColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            RenovoDateUtils.formatFullFrenchDate(_selectedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Parish Input
                Text(
                  'Paroisse',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _parishController,
                  decoration: const InputDecoration(
                    hintText: 'Nom de l’église ou paroisse',
                    prefixIcon: Icon(Icons.church_outlined, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez saisir le nom de la paroisse';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Quick-select Parish Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: quickParishes.map((name) {
                    final isSelected = _parishController.text.trim() == name;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _parishController.text = name;
                        });
                      },
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppTheme.darkPrimaryContainer : AppTheme.lightPrimaryContainer)
                              : surfaceLow,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isSelected ? primaryColor : outlineColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: isSelected
                                ? (isDark ? AppTheme.darkOnPrimaryContainer : AppTheme.lightOnPrimaryContainer)
                                : onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Spiritual Notes Input
                Text(
                  'Notes spirituelles (optionnel)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Pénitence, intention ou parole reçue…',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Privé et conservé uniquement sur votre appareil.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Full-width Save Button
                SizedBox(
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
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onPrimary,
                            ),
                          )
                        : Text(
                            isEditing ? 'Mettre à jour' : 'Enregistrer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
