import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// Clean horizontal legend pill matching the Google Stitch export.
class CalendarLegendWidget extends StatelessWidget {
  const CalendarLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceContainer = isDark
        ? AppTheme.darkSurfaceContainer
        : AppTheme.lightSurfaceContainer;
    final outlineColor = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: surfaceContainer,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: outlineColor, width: 1),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
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
                  const SizedBox(width: 5),
                  Text(
                    'Effectuée',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.antiqueGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Prévue (Samedi)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Non effectuée',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
