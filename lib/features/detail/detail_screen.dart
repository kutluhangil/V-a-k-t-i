import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/category.dart';
import '../../data/models/tip.dart';
import '../../data/repositories/tip_repository.dart';
import '../../widgets/pill_badge.dart';
import '../../widgets/time_arc.dart';
import '../../widgets/tip_actions.dart';

/// Full single-card detail view — encyclopedic layout (§7.4).
/// Top: hero image + badge + title. Below: WHEN/WHY summary, then rich
/// background sections (origin, how to use, fun fact, countries).
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.tipId});

  final String tipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(tipRepositoryProvider);

    return Scaffold(
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          final tip = repo.byId(tipId);
          if (tip == null) return const Center(child: Text('—'));
          return _DetailBody(tip: tip);
        },
      ),
    );
  }
}

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.tip});
  final Tip tip;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final category = categoryById(tip.category);
    final tint = category?.color ?? AppColors.saffron;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = Color.alphaBlend(
      tint.withValues(alpha: 0.06),
      theme.colorScheme.surface,
    );

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        // ── Sticky app bar ──────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          expandedHeight: 0,
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TipActions(tip: tip, axis: Axis.horizontal),
            const SizedBox(width: 8),
          ],
        ),

        SliverToBoxAdapter(
          child: Container(
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero image (parallax) ──────────────────────────────
                  _ParallaxHero(
                    tip: tip,
                    tint: tint,
                    isDark: isDark,
                    controller: _scroll,
                  ),
                  const SizedBox(height: 20),

                  // ── Category badge ─────────────────────────────────────
                  if (category != null)
                    PillBadge(
                      label: category.title.of(lang),
                      color: tint,
                      emoji: tip.emoji,
                    ),
                  const SizedBox(height: 12),

                  // ── Title ──────────────────────────────────────────────
                  Text(
                    tip.title.of(lang),
                    style: AppTypography.titleXL.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── WHEN / WHY summary ─────────────────────────────────
                  _SummaryRow(tip: tip, lang: lang, tint: tint),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),

        // ── Detail sections (only if detail data exists) ──────────────
        if (tip.detail != null)
          SliverToBoxAdapter(
            child: _DetailSections(tip: tip, lang: lang, tint: tint),
          ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// ─── Hero fallback (no image) ─────────────────────────────────────────────────

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({
    required this.tip,
    required this.tint,
    required this.isDark,
  });
  final Tip tip;
  final Color tint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.alphaBlend(
        tint.withValues(alpha: 0.12),
        isDark ? AppColors.darkBg : AppColors.paper,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TimeArc(position: arcPositionForTip(tip), width: 180),
            const SizedBox(height: 16),
            Text(tip.emoji, style: const TextStyle(fontSize: 56)),
          ],
        ),
      ),
    );
  }
}

// ─── WHEN / WHY two-column summary ───────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.tip,
    required this.lang,
    required this.tint,
  });
  final Tip tip;
  final String lang;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;
    final accentLabel = Color.alphaBlend(
      tint.withValues(alpha: 0.9),
      theme.colorScheme.onSurface,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(
            label: tip.primaryLabel.of(lang),
            value: tip.primary.of(lang),
            accentColor: accentLabel,
            muted: muted,
            style: AppTypography.bodyL,
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 16),
          _InfoLine(
            label: tip.secondaryLabel.of(lang),
            value: tip.secondary.of(lang),
            accentColor: accentLabel,
            muted: muted,
            style: AppTypography.bodyM,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.muted,
    required this.style,
  });
  final String label;
  final String value;
  final Color accentColor;
  final Color? muted;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(color: accentColor),
        ),
        const SizedBox(height: 6),
        Text(value, style: style),
      ],
    );
  }
}

// ─── Encyclopedic detail sections ────────────────────────────────────────────

class _DetailSections extends StatelessWidget {
  const _DetailSections({
    required this.tip,
    required this.lang,
    required this.tint,
  });
  final Tip tip;
  final String lang;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final detail = tip.detail!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sectionBg = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    final sections = <Widget>[];

    // ── Origin / History ─────────────────────────────────────────────
    if (detail.origin != null) {
      sections.add(
        _Section(
          icon: '📍',
          titleTr: 'Köken & Tarihçe',
          titleEn: 'Origin & History',
          body: detail.origin!.of(lang),
          tint: tint,
          bg: sectionBg,
          divider: theme.dividerColor,
        ),
      );
    }

    // ── Countries / Basis ────────────────────────────────────────────
    if (detail.countries != null && detail.countries!.isNotEmpty) {
      sections.add(
        _CountriesSection(
          countries: detail.countries!,
          tint: tint,
          lang: lang,
          bg: sectionBg,
          divider: theme.dividerColor,
        ),
      );
    }

    // ── How to use ───────────────────────────────────────────────────
    if (detail.howToUse != null) {
      sections.add(
        _Section(
          icon: '✋',
          titleTr: 'Nasıl Kullanılır',
          titleEn: 'How to Use',
          body: detail.howToUse!.of(lang),
          tint: tint,
          bg: sectionBg,
          divider: theme.dividerColor,
        ),
      );
    }

    // ── Fun fact ─────────────────────────────────────────────────────
    if (detail.funFact != null) {
      sections.add(
        _FunFactSection(
          body: detail.funFact!.of(lang),
          tint: tint,
          bg: sectionBg,
          divider: theme.dividerColor,
        ),
      );
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (int i = 0; i < sections.length; i++) ...[
            sections[i],
            if (i < sections.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.titleTr,
    required this.titleEn,
    required this.body,
    required this.tint,
    required this.bg,
    required this.divider,
  });
  final String icon;
  final String titleTr;
  final String titleEn;
  final String body;
  final Color tint;
  final Color bg;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final title = lang == 'tr' ? titleTr : titleEn;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTypography.labelCaps.copyWith(
                  color: Color.alphaBlend(
                    tint.withValues(alpha: 0.85),
                    theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTypography.bodyM.copyWith(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountriesSection extends StatelessWidget {
  const _CountriesSection({
    required this.countries,
    required this.tint,
    required this.lang,
    required this.bg,
    required this.divider,
  });
  final List<String> countries;
  final Color tint;
  final String lang;
  final Color bg;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = lang == 'tr' ? 'Nerede Bulunur' : 'Where It\'s Found';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTypography.labelCaps.copyWith(
                  color: Color.alphaBlend(
                    tint.withValues(alpha: 0.85),
                    theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in countries)
                _CountryChip(label: c, tint: tint),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({required this.label, required this.tint});
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tint.withValues(alpha: 0.10),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Color.alphaBlend(
            tint.withValues(alpha: 0.25),
            theme.dividerColor,
          ),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _FunFactSection extends StatelessWidget {
  const _FunFactSection({
    required this.body,
    required this.tint,
    required this.bg,
    required this.divider,
  });
  final String body;
  final Color tint;
  final Color bg;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final title = lang == 'tr' ? 'Biliyor Muydun?' : 'Did You Know?';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(tint.withValues(alpha: 0.08), bg),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color.alphaBlend(
            tint.withValues(alpha: 0.30),
            divider,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTypography.labelCaps.copyWith(color: tint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTypography.bodyM.copyWith(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// The detail hero image with a scroll-driven parallax. Keeps the rounded card
/// framing; the image lags on scroll-up and zooms gently on pull-down. Falls
/// back to [_HeroFallback] when the asset is missing, and to a static image
/// when the platform requests reduced motion.
class _ParallaxHero extends StatelessWidget {
  const _ParallaxHero({
    required this.tip,
    required this.tint,
    required this.isDark,
    required this.controller,
  });

  final Tip tip;
  final Color tint;
  final bool isDark;
  final ScrollController controller;

  static const _maxShift = 48.0;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/cards/${tip.id}.webp',
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) =>
          _HeroFallback(tip: tip, tint: tint, isDark: isDark),
    );

    if (MediaQuery.of(context).disableAnimations) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(aspectRatio: 1.4, child: image),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w / 1.4;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: w,
            height: h,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final offset = controller.hasClients ? controller.offset : 0.0;
                final p = heroParallax(offset, _maxShift);
                return OverflowBox(
                  minWidth: w,
                  maxWidth: w,
                  minHeight: h,
                  maxHeight: h + _maxShift,
                  alignment: Alignment.bottomCenter,
                  child: Transform.translate(
                    offset: Offset(0, p.dy),
                    child: Transform.scale(
                      scale: p.scale,
                      child: SizedBox(
                        width: w,
                        height: h + _maxShift,
                        child: image,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Translate (`dy`) and `scale` for the detail hero image given the scroll
/// offset. Scrolling up (offset > 0) lags the image behind the frame; pulling
/// down (offset < 0) zooms it in gently. Pure — unit-testable.
({double dy, double scale}) heroParallax(double scrollOffset, double maxShift) {
  if (scrollOffset >= 0) {
    return (dy: (scrollOffset * 0.3).clamp(0.0, maxShift), scale: 1.0);
  }
  return (dy: 0.0, scale: (1.0 - scrollOffset * 0.0015).clamp(1.0, 1.12));
}
