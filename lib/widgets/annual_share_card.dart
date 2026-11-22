import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/theme/app_theme.dart';
import '../data/models/confession.dart';

class AnnualShareCard extends StatelessWidget {
  const AnnualShareCard({
    required this.pseudo,
    required this.showEmail,
    required this.selectedYear,
    required this.confessions,
    required this.user,
    super.key,
  });

  static const double cardWidth = 400;
  static const double cardHeight = 500;

  final String pseudo;
  final bool showEmail;
  final int selectedYear;
  final List<Confession> confessions;
  final User? user;

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

  @override
  Widget build(BuildContext context) {
    final yearConfessions = confessions
        .where(
          (confession) =>
              confession.isCompleted &&
              confession.normalizedDate.year == selectedYear,
        )
        .toList();
    final monthCounts = List<int>.filled(12, 0);
    for (final confession in yearConfessions) {
      monthCounts[confession.normalizedDate.month - 1]++;
    }
    final activeMonths = monthCounts.where((count) => count > 0).length;
    final totalLabel = yearConfessions.length == 1
        ? 'confession effectuée'
        : 'confessions effectuées';

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.liturgicalIndigo, Color(0xFF1B2847)],
                  transform: GradientRotation(155 * math.pi / 180),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned(
                    top: -80,
                    right: -80,
                    child: _GoldGlow(size: 288, opacity: 0.24),
                  ),
                  const Positioned(
                    bottom: -96,
                    left: -64,
                    child: _GoldGlow(size: 256, opacity: 0.14),
                  ),
                  const CustomPaint(painter: _SacredArchPainter()),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ProfileHeader(
                          pseudo: pseudo,
                          subtitle: showEmail && user?.email?.isNotEmpty == true
                              ? user!.email!
                              : 'Parcours spirituel • Renovo',
                          user: user,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppTheme.antiqueGold.withValues(
                                  alpha: 0.2,
                                ),
                                border: Border.all(
                                  color: AppTheme.antiqueGold.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                child: Text(
                                  'BILAN ANNUEL $selectedYear',
                                  style: const TextStyle(
                                    color: AppTheme.goldTint,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${yearConfessions.length}',
                              style: const TextStyle(
                                color: AppTheme.alabaster,
                                fontFamily: 'Lora',
                                fontSize: 44,
                                fontWeight: FontWeight.w600,
                                height: 1.05,
                                fontFeatures: [ui.FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              totalLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFEDEBF1),
                                fontFamily: 'Lora',
                                fontSize: 20,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$activeMonths mois actifs • Rythme de grâce',
                              style: const TextStyle(
                                color: AppTheme.antiqueGold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 12,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.65,
                              ),
                          itemBuilder: (context, index) => _ShareMonthTile(
                            month: _months[index],
                            count: monthCounts[index],
                          ),
                        ),
                        const _RenovoSignature(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Uint8List> captureAnnualShareCard({
  required BuildContext context,
  required AnnualShareCard card,
  required String? profilePhotoUrl,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
    try {
      await precacheImage(
        NetworkImage(profilePhotoUrl),
        context,
        onError: (error, stackTrace) {
          debugPrint('Share-card profile photo unavailable: $error');
        },
      ).timeout(const Duration(milliseconds: 1500));
    } on TimeoutException {
      debugPrint('Share-card profile photo preload timed out; using initials.');
    } catch (error, stackTrace) {
      debugPrint('Share-card profile photo preload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  final boundaryKey = GlobalKey();
  if (!overlay.mounted) {
    throw StateError('L’écran de partage a été fermé avant la capture.');
  }
  final entry = OverlayEntry(
    builder: (_) => Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -AnnualShareCard.cardWidth - 16,
          top: 0,
          child: RepaintBoundary(key: boundaryKey, child: card),
        ),
      ],
    ),
  );
  overlay.insert(entry);

  try {
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;

    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary || !renderObject.hasSize) {
      throw StateError('La carte partageable n’a pas pu être mise en page.');
    }

    final image = await renderObject.toImage(pixelRatio: 3.0);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Impossible de créer l’image du bilan annuel.');
      }
      return byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}

class _GoldGlow extends StatelessWidget {
  const _GoldGlow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          AppTheme.antiqueGold.withValues(alpha: opacity),
          AppTheme.antiqueGold.withValues(alpha: 0),
        ],
      ),
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.pseudo,
    required this.subtitle,
    required this.user,
  });

  final String pseudo;
  final String subtitle;
  final User? user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GoldRingAvatar(user: user, pseudo: pseudo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pseudo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.alabaster,
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xB3FAF8F5), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldRingAvatar extends StatelessWidget {
  const _GoldRingAvatar({required this.user, required this.pseudo});

  final User? user;
  final String pseudo;

  @override
  Widget build(BuildContext context) {
    final initials = _shareInitials(pseudo);
    final photoUrl = user?.photoURL;

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppTheme.antiqueGold,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: ColoredBox(
          color: AppTheme.liturgicalIndigo,
          child: photoUrl == null || photoUrl.isEmpty
              ? _ShareInitials(initials: initials)
              : Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : _ShareInitials(initials: initials),
                  errorBuilder: (context, error, stackTrace) =>
                      _ShareInitials(initials: initials),
                ),
        ),
      ),
    );
  }
}

class _ShareInitials extends StatelessWidget {
  const _ShareInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      initials,
      style: const TextStyle(
        color: AppTheme.alabaster,
        fontFamily: 'Lora',
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );
}

class _ShareMonthTile extends StatelessWidget {
  const _ShareMonthTile({required this.month, required this.count});

  final String month;
  final int count;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Semantics(
      label: '$month : $count confession${count == 1 ? '' : 's'}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.alabaster.withValues(alpha: active ? 0.15 : 0.1),
              border: Border.all(
                color: active
                    ? AppTheme.sageEmerald.withValues(alpha: 0.6)
                    : AppTheme.alabaster.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: TextStyle(
                    color: AppTheme.alabaster.withValues(
                      alpha: active ? 1 : 0.8,
                    ),
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < 2; index++) ...[
                      if (index > 0) const SizedBox(width: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: index < count
                              ? AppTheme.sageEmerald
                              : AppTheme.alabaster.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: index < count
                              ? [
                                  BoxShadow(
                                    color: AppTheme.sageEmerald.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                    if (count > 2) ...[
                      const SizedBox(width: 3),
                      Text(
                        '+${count - 2}',
                        style: const TextStyle(
                          color: AppTheme.goldTint,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenovoSignature extends StatelessWidget {
  const _RenovoSignature();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x26FAF8F5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomPaint(
                size: Size(24, 26),
                painter: _RenovoEmblemPainter(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Renovo',
                style: TextStyle(
                  color: AppTheme.alabaster,
                  fontFamily: 'Lora',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Flexible(
            child: Text(
              'Renouveau & Paix intérieure',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Color(0xBFFAF8F5), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SacredArchPainter extends CustomPainter {
  const _SacredArchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 320, size.height / 420);
    canvas.save();
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 420 * scale) / 2,
    );
    canvas.scale(scale);
    final paint = Paint()
      ..color = AppTheme.antiqueGold.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final outer = Path()
      ..moveTo(56, 390)
      ..lineTo(56, 176)
      ..cubicTo(56, 118.562, 102.562, 72, 160, 72)
      ..cubicTo(217.438, 72, 264, 118.562, 264, 176)
      ..lineTo(264, 390);
    final inner = Path()
      ..moveTo(84, 390)
      ..lineTo(84, 180)
      ..cubicTo(84, 138.026, 118.026, 104, 160, 104)
      ..cubicTo(201.974, 104, 236, 138.026, 236, 180)
      ..lineTo(236, 390);
    canvas.drawPath(outer, paint);
    canvas.drawPath(inner, paint..strokeWidth = 1);
    canvas.drawLine(const Offset(160, 28), const Offset(160, 60), paint);
    canvas.drawLine(const Offset(146, 42), const Offset(174, 42), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SacredArchPainter oldDelegate) => false;
}

class _RenovoEmblemPainter extends CustomPainter {
  const _RenovoEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 88, size.height / 96);
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()
      ..color = AppTheme.antiqueGold
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.8;
    canvas.drawLine(const Offset(44, 8), const Offset(44, 22), paint);
    canvas.drawLine(const Offset(38, 14), const Offset(50, 14), paint);
    final arch = Path()
      ..moveTo(23, 70)
      ..lineTo(23, 45)
      ..cubicTo(23, 33.402, 32.402, 24, 44, 24)
      ..cubicTo(55.598, 24, 65, 33.402, 65, 45)
      ..lineTo(65, 70);
    canvas.drawPath(arch, paint);
    final branch = Path()
      ..moveTo(27, 77)
      ..cubicTo(33.5, 81.5, 42, 82, 51, 79.5)
      ..cubicTo(55.5, 78.2, 59.5, 76, 62, 73.5);
    canvas.drawPath(branch, paint..strokeWidth = 2.4);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RenovoEmblemPainter oldDelegate) => false;
}

String _shareInitials(String value) {
  final names = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (names.isEmpty) return 'P';
  if (names.length == 1) {
    return String.fromCharCodes(names.first.runes.take(2)).toUpperCase();
  }
  final initials =
      String.fromCharCode(names[0].runes.first) +
      String.fromCharCode(names[1].runes.first);
  return initials.toUpperCase();
}
