import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../data/models/confession.dart';
import '../providers/confessions_provider.dart';
import '../services/auth_service.dart';
import 'annual_share_card.dart';
import 'customize_share_card_modal.dart';

String buildAnnualConfessionsCsv(List<Confession> confessions) {
  final rows = <String>[
    'Date;Jour;Paroisse;Statut;Notes',
    for (final confession in confessions)
      [
        _csvField(DateFormat('dd/MM/yyyy', 'fr_FR').format(confession.normalizedDate)),
        _csvField(DateFormat('EEEE', 'fr_FR').format(confession.normalizedDate)),
        _csvField(confession.parish),
        _csvField('Effectuée'),
        _csvField(confession.notes ?? ''),
      ].join(';'),
  ];
  return '\uFEFF${rows.join('\r\n')}';
}

String _csvField(String value) => '"${value.replaceAll('"', '""')}"';

class AnnualReportSection extends ConsumerStatefulWidget {
  const AnnualReportSection({super.key});

  @override
  ConsumerState<AnnualReportSection> createState() =>
      _AnnualReportSectionState();
}

class _AnnualReportSectionState extends ConsumerState<AnnualReportSection> {
  late int _selectedYear = DateTime.now().year;
  bool _isExporting = false;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final confessions = ref.watch(confessionsProvider);

    return confessions.when(
      data: (items) => _buildReport(items, currentYear),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Impossible de charger le bilan annuel : $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildReport(List<Confession> confessions, int currentYear) {
    final completed = confessions
        .where((confession) => confession.isCompleted)
        .toList();
    final oldestYear = completed.isEmpty
        ? currentYear
        : completed
              .map((confession) => confession.normalizedDate.year)
              .reduce((first, next) => first < next ? first : next);
    final minYear = oldestYear > currentYear ? currentYear : oldestYear;
    final selectedYear = _selectedYear > currentYear
        ? currentYear
        : _selectedYear;
    final yearConfessions =
        completed.where((confession) {
          final date = confession.normalizedDate;
          return !date.isBefore(DateTime(selectedYear)) &&
              date.isBefore(DateTime(selectedYear + 1));
        }).toList()..sort(
          (first, next) => first.normalizedDate.compareTo(next.normalizedDate),
        );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;
    final onSurfaceVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final yearLabel =
        '${yearConfessions.length} confession'
        '${yearConfessions.length == 1 ? '' : 's'} effectuée'
        '${yearConfessions.length == 1 ? '' : 's'} en $selectedYear';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bilan annuel',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _YearSelector(
                  year: selectedYear,
                  canGoBack: selectedYear > minYear,
                  canGoForward: selectedYear < currentYear,
                  onPrevious: () => setState(() {
                    if (_selectedYear > minYear) _selectedYear--;
                  }),
                  onNext: () => setState(() {
                    if (_selectedYear < currentYear) _selectedYear++;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.sageTint,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle,
                        color: AppTheme.sageEmerald,
                        size: 9,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          yearLabel,
                          style: const TextStyle(
                            color: AppTheme.onSageTint,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _AnnualReportCard(
              year: selectedYear,
              confessions: yearConfessions,
              isDark: isDark,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
              outline: outline,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isExporting
                        ? null
                        : () => _openShareCardCustomizer(
                            selectedYear,
                            yearConfessions,
                          ),
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: const Text(
                      'Exporter en image',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.liturgicalIndigo,
                      foregroundColor: AppTheme.onLiturgicalIndigo,
                      minimumSize: const Size(0, 44),
                      maximumSize: const Size(double.infinity, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting
                        ? null
                        : () => _exportCsv(selectedYear, yearConfessions),
                    icon: const Icon(Icons.table_view_outlined, size: 16),
                    label: const Text(
                      'Exporter en CSV',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppTheme.darkPrimary
                          : AppTheme.liturgicalIndigo,
                      minimumSize: const Size(0, 44),
                      maximumSize: const Size(double.infinity, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isExporting) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 10),
              Text(
                _feedback!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _feedbackIsError
                      ? Theme.of(context).colorScheme.error
                      : AppTheme.sageEmerald,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(int year, List<Confession> confessions) async {
    await _runExport(() async {
      final directory = await getTemporaryDirectory();
      final filename = 'renovo_confessions_$year.csv';
      final file = File(path.join(directory.path, filename));
      final contents = utf8.encode(buildAnnualConfessionsCsv(confessions));
      await file.writeAsBytes(contents, flush: true);
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'text/csv', name: filename),
      ], subject: 'Renovo — Confessions $year');
      return 'Le fichier $filename est prêt au partage.';
    });
  }

  Future<void> _openShareCardCustomizer(
    int year,
    List<Confession> confessions,
  ) async {
    final customization = await showModalBottomSheet<ShareCardCustomization>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomizeShareCardModal(selectedYear: year),
    );
    if (!mounted || customization == null) return;

    final user = ref.read(authStateProvider).asData?.value;
    await _runExport(() async {
      final bytes = await captureAnnualShareCard(
        context: context,
        card: AnnualShareCard(
          pseudo: customization.pseudo,
          showEmail: customization.showEmail,
          selectedYear: year,
          confessions: confessions,
          user: user,
        ),
        profilePhotoUrl: user?.photoURL,
      );
      final directory = await getTemporaryDirectory();
      final filename = 'renovo_bilan_$year.png';
      final file = File(path.join(directory.path, filename));
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png', name: filename),
      ], subject: 'Renovo — Bilan $year');
      return 'L’image $filename est prête au partage.';
    });
  }

  Future<void> _runExport(Future<String> Function() export) async {
    setState(() {
      _isExporting = true;
      _feedback = null;
      _feedbackIsError = false;
    });
    try {
      final message = await export();
      if (mounted) setState(() => _feedback = message);
    } catch (error) {
      if (mounted) {
        setState(() {
          _feedback = 'Export impossible : $error';
          _feedbackIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

}

class _YearSelector extends StatelessWidget {
  const _YearSelector({
    required this.year,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final int year;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border.all(color: outline),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const ValueKey('annual-year-previous'),
            tooltip: 'Année précédente',
            onPressed: canGoBack ? onPrevious : null,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: const Icon(Icons.chevron_left, size: 19),
          ),
          Text(
            '$year',
            style: TextStyle(
              color: onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            key: const ValueKey('annual-year-next'),
            tooltip: 'Année suivante',
            onPressed: canGoForward ? onNext : null,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: const Icon(Icons.chevron_right, size: 19),
          ),
        ],
      ),
    );
  }
}

class _AnnualReportCard extends StatelessWidget {
  const _AnnualReportCard({
    required this.year,
    required this.confessions,
    required this.isDark,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
  });

  static const _months = [
    'Janv.',
    'Févr.',
    'Mars',
    'Avr.',
    'Mai',
    'Juin',
    'Juil.',
    'Août',
    'Sept.',
    'Oct.',
    'Nov.',
    'Déc.',
  ];

  final int year;
  final List<Confession> confessions;
  final bool isDark;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.filled(12, 0);
    for (final confession in confessions) {
      counts[confession.normalizedDate.month - 1]++;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border.all(color: outline),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Renovo — Bilan $year',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${confessions.length} confession'
            '${confessions.length == 1 ? '' : 's'} effectuée'
            '${confessions.length == 1 ? '' : 's'}',
            style: TextStyle(color: onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: outline),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) =>
                _MonthCell(label: _months[index], count: counts[index]),
          ),
        ],
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkOutline
        : AppTheme.lightOutline;

    return Semantics(
      label: '$label : $count confession${count == 1 ? '' : 's'}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var dot = 0; dot < 2; dot++) ...[
                if (dot > 0) const SizedBox(width: 4),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: count > dot ? AppTheme.sageEmerald : outline,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              if (count > 2) ...[
                const SizedBox(width: 3),
                Text(
                  '+${count - 2}',
                  style: const TextStyle(
                    color: AppTheme.sageEmerald,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
