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
  });

  final Tip tip;
  final EdgeInsets padding;

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

    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tint.withValues(alpha: 0.06),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - padding.vertical,
              ),
              child: IntrinsicHeight(
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
          );
        },
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
        Center(child: TimeArc(position: arcPositionForTip(tip))),
        const SizedBox(height: 20),
        if (category != null)
          PillBadge(
            label: category.title.of(lang),
            color: tint,
            emoji: tip.emoji,
          ),
        const Spacer(),
        Text(tip.emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
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
        const Spacer(flex: 2),
      ],
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
