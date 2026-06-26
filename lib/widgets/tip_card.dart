import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_typography.dart';
import '../data/models/category.dart';
import '../data/models/content_pillar.dart';
import '../data/models/tip.dart';
import 'pill_badge.dart';
import 'time_arc.dart';

/// The core editorial tip card. Used full-screen in the feed and (later) in the
/// detail / share views. Flat surface, tint ground, thin border, time arc.
class TipCard extends StatelessWidget {
  const TipCard({
    super.key,
    required this.tip,
    this.padding = const EdgeInsets.fromLTRB(28, 28, 28, 28),
    this.onTap,
  });

  final Tip tip;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final category = categoryById(tip.category);
    final tint = category?.color ?? AppColors.saffron;
    final muted = theme.textTheme.bodySmall?.color;

    // Communication titles are full sentences — give them a smaller scale.
    final titleStyle = tip.pillar == ContentPillar.wellness
        ? AppTypography.titleXL
        : AppTypography.titleL;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            tint.withValues(alpha: 0.06),
            theme.colorScheme.surface,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: _content(
                    context,
                    lang,
                    category,
                    tint,
                    muted,
                    titleStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    String lang,
    Category? category,
    Color tint,
    Color? muted,
    TextStyle titleStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHero(tip: tip, tint: tint),
        const SizedBox(height: 20),
        if (category != null)
          PillBadge(
            label: category.title.of(lang),
            color: tint,
            emoji: tip.emoji,
          ),
        const SizedBox(height: 16),
        Text(tip.title.of(lang), style: titleStyle),
        const SizedBox(height: 24),
        _Line(
          label: tip.primaryLabel.of(lang),
          value: tip.primary.of(lang),
          valueStyle: AppTypography.bodyL,
          tint: tint,
          muted: muted,
        ),
        const SizedBox(height: 16),
        _Line(
          label: tip.secondaryLabel.of(lang),
          value: tip.secondary.of(lang),
          valueStyle: AppTypography.bodyM,
          tint: tint,
          muted: muted,
        ),
        const Spacer(),
      ],
    );
  }
}

/// Card hero zone. Shows the per-card watercolor illustration
/// (`assets/images/cards/<tip.id>.png`) when present; otherwise falls back to
/// the signature time-arc + emoji so cards without art still read as Vakti.
class _CardHero extends StatelessWidget {
  const _CardHero({required this.tip, required this.tint});

  final Tip tip;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Image.asset(
          'assets/images/cards/${tip.id}.webp',
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // No illustration yet -> keep the branded placeholder.
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TimeArc(position: arcPositionForTip(tip), animate: true),
          const SizedBox(height: 20),
          Text(tip.emoji, style: const TextStyle(fontSize: 44)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.tint,
    required this.muted,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;
  final Color tint;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(
            color: Color.alphaBlend(
              tint.withValues(alpha: 0.9),
              Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}
