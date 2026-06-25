import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_typography.dart';

/// Large editorial page title with the signature "time arc" hairline + saffron
/// dot beneath it. Used at the top of each tab body for a consistent identity.
class VaktiScreenTitle extends StatelessWidget {
  const VaktiScreenTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleXL),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Container(height: 1, color: theme.dividerColor)),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.saffron,
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ],
    );
  }
}
