import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';
import '../providers/selected_date_provider.dart';
import '../providers/theme_provider.dart';
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
