import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../data/models/category.dart';
import '../data/models/content_pillar.dart';
import '../data/models/tip.dart';
import 'time_arc.dart';

/// The 1080×1350 (4:5) branded image rendered for sharing (§9.2).
/// Always dark "ink" ground for a consistent look regardless of app theme,
/// with a small "Vakti" watermark for organic growth.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.tip, required this.lang});

  final Tip tip;
  final String lang;

  static const size = Size(1080, 1350);

  @override
  Widget build(BuildContext context) {
    final category = categoryById(tip.category);
    final isWellness = tip.pillar == ContentPillar.wellness;

    return Container(
      width: size.width,
      height: size.height,
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(96, 96, 96, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: TimeArc(
              position: arcPositionForTip(tip),
              width: 280,
              dotColor: AppColors.saffron,
              arcColor: AppColors.paper.withValues(alpha: 0.25),
            ),
          ),
          const Spacer(),
          Text(tip.emoji, style: const TextStyle(fontSize: 132)),
          const SizedBox(height: 24),
          Text(
            tip.title.of(lang),
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontWeight: FontWeight.w600,
              fontSize: isWellness ? 76 : 58,
              height: 1.1,
              color: AppColors.paper,
            ),
          ),
          const SizedBox(height: 56),
          _block(tip.primaryLabel.of(lang), tip.primary.of(lang), 44),
          const SizedBox(height: 36),
          _block(tip.secondaryLabel.of(lang), tip.secondary.of(lang), 38),
          const Spacer(flex: 2),
          Row(
            children: [
              Text(category?.emoji ?? '', style: const TextStyle(fontSize: 36)),
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
