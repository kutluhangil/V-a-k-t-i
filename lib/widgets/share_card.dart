import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../data/models/category.dart';
import '../data/models/content_pillar.dart';
import '../data/models/tip.dart';
import 'time_arc.dart';

/// Aspect ratios offered when sharing a tip as an image.
enum ShareFormat {
  post(Size(1080, 1350)),
  story(Size(1080, 1920)),
  square(Size(1080, 1080));

  const ShareFormat(this.size);
  final Size size;
}

/// Per-format layout tuning so one card composition serves all three ratios.
class _CardMetrics {
  const _CardMetrics({
    required this.padding,
    required this.arcWidth,
    required this.emojiSize,
    required this.titleScale,
    required this.gapAfterTitle,
    required this.gapBetweenBlocks,
    required this.footerFlex,
  });

  final EdgeInsets padding;
  final double arcWidth;
  final double emojiSize;
  final double titleScale; // multiplied into the base title size
  final double gapAfterTitle;
  final double gapBetweenBlocks;
  final int footerFlex;

  /// Block value font sizes scale gently with the title (kept readable).
  double get blockScale => titleScale.clamp(0.85, 1.0);

  static _CardMetrics of(ShareFormat f) {
    switch (f) {
      case ShareFormat.post:
        return const _CardMetrics(
          padding: EdgeInsets.fromLTRB(96, 96, 96, 80),
          arcWidth: 280,
          emojiSize: 132,
          titleScale: 1.0,
          gapAfterTitle: 56,
          gapBetweenBlocks: 36,
          footerFlex: 2,
        );
      case ShareFormat.story:
        return const _CardMetrics(
          padding: EdgeInsets.fromLTRB(112, 260, 112, 240),
          arcWidth: 340,
          emojiSize: 148,
          titleScale: 1.0,
          gapAfterTitle: 64,
          gapBetweenBlocks: 44,
          footerFlex: 2,
        );
      case ShareFormat.square:
        return const _CardMetrics(
          padding: EdgeInsets.fromLTRB(80, 72, 80, 64),
          arcWidth: 200,
          emojiSize: 96,
          titleScale: 0.72,
          gapAfterTitle: 32,
          gapBetweenBlocks: 24,
          footerFlex: 1,
        );
    }
  }
}

/// A branded image rendered for sharing (§9.2), in one of three aspect ratios
/// ([ShareFormat]). Always dark "ink" ground for a consistent look regardless
/// of app theme, with a small "Vakti" watermark for organic growth.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.tip,
    required this.lang,
    this.format = ShareFormat.post,
  });

  final Tip tip;
  final String lang;
  final ShareFormat format;

  @override
  Widget build(BuildContext context) {
    final category = categoryById(tip.category);
    final isWellness = tip.pillar == ContentPillar.wellness;
    final m = _CardMetrics.of(format);
    final size = format.size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Watercolor hero art; falls back to a plain ink ground if missing.
          Image.asset(
            'assets/images/cards/${tip.id}.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: AppColors.ink),
          ),
          // Dark scrim: light at top (art shows) → heavy at bottom (text legible).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.ink.withValues(alpha: 0.35),
                  AppColors.ink.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Padding(
            padding: m.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: TimeArc(
                    position: arcPositionForTip(tip),
                    width: m.arcWidth,
                    dotColor: AppColors.saffron,
                    arcColor: AppColors.paper.withValues(alpha: 0.25),
                  ),
                ),
                const Spacer(),
                Text(tip.emoji, style: TextStyle(fontSize: m.emojiSize)),
                const SizedBox(height: 24),
                Text(
                  tip.title.of(lang),
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontWeight: FontWeight.w600,
                    fontSize: (isWellness ? 76 : 58) * m.titleScale,
                    height: 1.1,
                    color: AppColors.paper,
                  ),
                ),
                SizedBox(height: m.gapAfterTitle),
                _block(
                  tip.primaryLabel.of(lang),
                  tip.primary.of(lang),
                  44 * m.blockScale,
                ),
                SizedBox(height: m.gapBetweenBlocks),
                _block(
                  tip.secondaryLabel.of(lang),
                  tip.secondary.of(lang),
                  38 * m.blockScale,
                ),
                Spacer(flex: m.footerFlex),
                Row(
                  children: [
                    Text(
                      category?.emoji ?? '',
                      style: const TextStyle(fontSize: 36),
                    ),
                    const Spacer(),
                    Text(
                      'Vakti',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontWeight: FontWeight.w600,
                        fontSize: 40,
                        color: AppColors.paper.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(String label, String value, double valueSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 26,
            letterSpacing: 2,
            color: AppColors.saffron,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: valueSize,
            height: 1.3,
            color: AppColors.paper.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}
