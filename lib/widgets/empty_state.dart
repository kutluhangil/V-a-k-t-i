import 'package:flutter/material.dart';

import '../app/theme/app_typography.dart';
import 'time_arc.dart';

/// A calm, centered empty-state (used by Favorites and any empty list).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand "time arc" motif framing the emoji.
            SizedBox(
              height: 96,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const TimeArc(position: 0.5, width: 150, animate: true),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(emoji, style: const TextStyle(fontSize: 40)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleL,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTypography.bodyM.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
