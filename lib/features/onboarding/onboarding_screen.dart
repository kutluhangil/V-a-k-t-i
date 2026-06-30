import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/controllers/locale_controller.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/sources/local_store.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/time_arc.dart';

// Landing palette — always the "golden hour" ink theme, regardless of the
// app's light/dark setting, so the first impression is consistent and premium.
const _bg = Color(0xFF131314);
const _text = Color(0xFFE5E2E2);
const _muted = Color(0xFFC6C6CB);
const _warm = Color(0xFFD5C3B3);
const _cardBg = Color(0xFF181C23);
const _hairline = Color(0x1A9091A0);
const _chipBorder = Color(0xFF45474B);

/// First-run landing / welcome screen (§7.1). Editorial "golden hour" intro:
/// the brand, the two pillars, and the call to enter. Sets `onboardingDone`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _arcPosition = ValueNotifier(0.1);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _arcPosition.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    final ratio = (_scroll.offset / max).clamp(0.0, 1.0);
    _arcPosition.value = 0.1 + (ratio * 0.8);
  }

  Future<void> _enter() async {
    await LocalStore.instance.set(LocalStore.kOnboardingDone, true);
    if (mounted) context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Time-arc decoration spanning the top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              // One-shot "draw-in" entrance: the arc fades and settles down
              // from above on first build — the brand moment.
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (t - 1) * 24),
                    child: child,
                  ),
                ),
                child: Center(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _arcPosition,
                    builder: (context, pos, _) =>
                        TimeArc(position: pos, width: 460),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      // Brand
                      Text(
                        'Vakti',
                        style: AppTypography.titleXL.copyWith(
                          fontSize: 48,
                          color: _text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '“${l.appTagline}”',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleL.copyWith(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          color: _warm,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        l.landingIntro,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyL.copyWith(
                          color: _muted,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 40),

                      _PillarCard(
                        icon: Icons.spa,
                        title: l.pillarWellness,
                        image: 'assets/images/cards/w_ginger_tea.webp',
                        body: l.landingWellnessBody,
                        chips: [l.landingChipWellness1, l.landingChipWellness2],
                      ),
                      const SizedBox(height: 16),
                      _PillarCard(
                        icon: Icons.chat_bubble_outline,
                        title: l.pillarCommunication,
                        image: 'assets/images/cards/c_im_here.webp',
                        body: l.landingCommBody,
                        chips: [l.landingChipComm1, l.landingChipComm2],
                      ),

                      const SizedBox(height: 40),
                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _enter,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.saffron,
                            foregroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l.landingCta.toUpperCase(),
                            style: AppTypography.labelCaps.copyWith(
                              fontSize: 14,
                              letterSpacing: 2,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l.landingSubtext,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(color: _muted),
                      ),
                      const SizedBox(height: 40),
                      _Footer(
                        onLanguage: () => _toggleLanguage(
                          ref,
                          Localizations.localeOf(context),
                        ),
                        onLegal: () => _showLegal(context, l),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLanguage(WidgetRef ref, Locale current) {
    final next = current.languageCode == 'tr' ? 'en' : 'tr';
    ref.read(localeProvider.notifier).setLocale(Locale(next));
  }

  void _showLegal(BuildContext context, AppLocalizations l) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.disclaimerTitle),
        content: Text(l.disclaimerBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.onboardingAgree),
          ),
        ],
      ),
    );
  }
}

/// One of the two pillar bento cards.
class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.title,
    required this.image,
    required this.body,
    required this.chips,
  });

  final IconData icon;
  final String title;
  final String image;
  final String body;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.saffron, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.titleL.copyWith(
                  fontSize: 22,
                  color: _text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 168,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: _cardBg),
                  ),
                  // Bottom darkening so the editorial feel carries through.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Color(0x66131314), Color(0x00131314)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: AppTypography.bodyM.copyWith(color: _muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in chips) _Chip(c)],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF353435).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _chipBorder),
      ),
      child: Text(
        label,
        style: AppTypography.labelCaps.copyWith(
          fontSize: 12,
          letterSpacing: 0.2,
          color: _warm,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onLanguage, required this.onLegal});

  final VoidCallback onLanguage;
  final VoidCallback onLegal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onLanguage,
              icon: const Icon(Icons.public, color: Color(0xFF909095)),
              tooltip: 'TR / EN',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onLegal,
              icon: const Icon(Icons.favorite_border, color: Color(0xFF909095)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.auto_awesome, color: Color(0xFF909095)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '© 2024 VAKTI WELLNESS',
          style: AppTypography.labelCaps.copyWith(
            fontSize: 11,
            letterSpacing: 2,
            color: const Color(0xFF909095).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
