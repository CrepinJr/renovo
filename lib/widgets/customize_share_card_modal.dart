import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class ShareCardCustomization {
  const ShareCardCustomization({
    required this.pseudo,
    required this.showEmail,
  });

  final String pseudo;
  final bool showEmail;
}

class CustomizeShareCardModal extends ConsumerStatefulWidget {
  const CustomizeShareCardModal({required this.selectedYear, super.key});

  final int selectedYear;

  @override
  ConsumerState<CustomizeShareCardModal> createState() =>
      _CustomizeShareCardModalState();
}

class _CustomizeShareCardModalState
    extends ConsumerState<CustomizeShareCardModal> {
  static const _pseudoPreferenceKey = 'renovo_share_pseudo';

  late final TextEditingController _pseudoController;
  String? _savedPseudo;
  Object? _preferencesError;
  bool _preferencesLoaded = false;
  bool _pseudoEdited = false;
  bool _showEmail = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pseudoController = TextEditingController(text: 'Pèlerin');
    unawaited(_loadPreferences());
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_pseudoPreferenceKey)?.trim();
      final user = ref.read(authStateProvider).asData?.value;
      if (!mounted) return;
      setState(() {
        _savedPseudo = saved?.isNotEmpty == true ? saved : null;
        _pseudoController.text = _savedPseudo ?? _defaultPseudo(user);
        _preferencesLoaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preferencesError = error;
        _pseudoController.text = _defaultPseudo(
          ref.read(authStateProvider).asData?.value,
        );
        _preferencesLoaded = true;
      });
    }
  }

  void _updateFallbackPseudo(User? user) {
    if (!_preferencesLoaded || _savedPseudo != null || _pseudoEdited) return;
    final fallback = _defaultPseudo(user);
    if (_pseudoController.text == fallback) return;
    setState(() => _pseudoController.text = fallback);
  }

  String _defaultPseudo(User? user) {
    final displayName = user?.displayName?.trim();
    return displayName?.isNotEmpty == true ? displayName! : 'Pèlerin';
  }

  Future<void> _generateAndShare(User? user) async {
    if (_isSaving || !_preferencesLoaded) return;
    final pseudo = _pseudoController.text.trim().isEmpty
        ? 'Pèlerin'
        : _pseudoController.text.trim();

    setState(() {
      _isSaving = true;
      _preferencesError = null;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(_pseudoPreferenceKey, pseudo);
      if (!saved) {
        throw StateError('Le pseudo n’a pas pu être enregistré localement.');
      }
      if (mounted) {
        Navigator.of(context).pop(
          ShareCardCustomization(
            pseudo: pseudo,
            showEmail: user != null && _showEmail,
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _preferencesError = error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData(_updateFallbackPseudo);
    });
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkSurface : AppTheme.alabaster;
    final container = isDark
        ? AppTheme.darkSurfaceContainer
        : AppTheme.lightSurfaceContainer;
    final outline = isDark ? AppTheme.darkOutline : AppTheme.lightOutline;
    final onSurface = isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;
    final onSurfaceVariant = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.lightOnSurfaceVariant;
    final iconColor = isDark
        ? AppTheme.darkPrimary
        : AppTheme.liturgicalIndigo;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: outline,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Personnaliser la carte',
                        style: GoogleFonts.lora(
                          color: onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: container,
                        side: BorderSide(color: outline),
                        foregroundColor: onSurfaceVariant,
                      ),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: container,
                    border: Border.all(color: outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _ProfileRingAvatar(
                        user: user,
                        pseudo: _pseudoController.text,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bilan annuel ${widget.selectedYear}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user != null && _showEmail
                                  ? user.email ?? 'Parcours spirituel • Renovo'
                                  : 'Parcours spirituel • Renovo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pseudo affiché sur la carte',
                  style: TextStyle(
                    color: onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pseudoController,
                  enabled: _preferencesLoaded && !_isSaving,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => _pseudoEdited = true),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Surnom ou devise personnelle',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      size: 18,
                      color: onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: container,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: iconColor),
                    ),
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: container,
                      border: Border.all(color: outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Afficher mon adresse e-mail',
                                style: TextStyle(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Masquée par défaut pour préserver votre confidentialité',
                                style: TextStyle(
                                  color: onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _showEmail,
                          onChanged: _isSaving
                              ? null
                              : (value) => setState(() => _showEmail = value),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_preferencesError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Impossible d’enregistrer le pseudo : $_preferencesError',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: !_preferencesLoaded || _isSaving
                      ? null
                      : () => _generateAndShare(user),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Générer et partager'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.liturgicalIndigo,
                    foregroundColor: AppTheme.onLiturgicalIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

class _ProfileRingAvatar extends StatelessWidget {
  const _ProfileRingAvatar({
    required this.user,
    required this.pseudo,
    required this.size,
  });

  final User? user;
  final String pseudo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(pseudo);
    final photoUrl = user?.photoURL;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppTheme.antiqueGold,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: ColoredBox(
          color: AppTheme.liturgicalIndigo,
          child: photoUrl == null || photoUrl.isEmpty
              ? _InitialsAvatar(initials: initials)
              : Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                      ? child
                      : _InitialsAvatar(initials: initials),
                  errorBuilder: (context, error, stackTrace) =>
                      _InitialsAvatar(initials: initials),
                ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      initials,
      style: GoogleFonts.lora(
        color: AppTheme.alabaster,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final names = parts.toList();
  if (names.isEmpty) return 'P';
  if (names.length == 1) {
    final runes = names.first.runes.take(2).toList();
    return String.fromCharCodes(runes).toUpperCase();
  }
  return '${String.fromCharCode(names[0].runes.first)}'
          '${String.fromCharCode(names[1].runes.first)}'
      .toUpperCase();
}
