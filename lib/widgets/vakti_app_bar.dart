import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_typography.dart';

/// Shared top bar across the shell tabs: menu · "Vakti" wordmark · brand mark.
/// Flat, hairline divider underneath — matches the editorial settings design.
class VaktiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VaktiAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      titleSpacing: 4,
      leading: IconButton(
        icon: const Icon(Icons.menu, size: 24),
        onPressed: () => Scaffold.of(context).openDrawer(),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
      title: Text('Vakti', style: AppTypography.titleL.copyWith(fontSize: 22)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _BrandMark(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.dividerColor),
      ),
    );
  }
}

/// Small circular golden-hour brand mark (the "time arc" dot motif).
class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.saffron.withValues(alpha: 0.16),
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.55)),
      ),
      child: const Center(
        child: Icon(Icons.wb_twilight, size: 18, color: AppColors.saffronDeep),
      ),
    );
  }
}
