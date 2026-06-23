import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme/app_colors.dart';
import '../data/models/tip.dart';
import '../data/repositories/favorites_repository.dart';
import '../services/share_service.dart';

/// Save + share actions for a tip. Used as a vertical rail in the feed and a
/// row in the detail view.
class TipActions extends ConsumerWidget {
  const TipActions({super.key, required this.tip, this.axis = Axis.vertical});

  final Tip tip;
  final Axis axis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).contains(tip.id);
    final lang = Localizations.localeOf(context).languageCode;

    final buttons = <Widget>[
      _ActionButton(
        icon: isFav ? Icons.favorite : Icons.favorite_border,
        active: isFav,
        onTap: () => ref.read(favoritesProvider.notifier).toggle(tip.id),
      ),
      SizedBox(
        width: axis == Axis.vertical ? 0 : 12,
        height: axis == Axis.vertical ? 12 : 0,
      ),
      _ActionButton(
        icon: Icons.ios_share,
        active: false,
        onTap: () => shareService.shareTip(context, tip, lang),
      ),
    ];

    return axis == Axis.vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: buttons)
        : Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: CircleBorder(side: BorderSide(color: theme.dividerColor)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 22,
            color: active ? AppColors.saffronDeep : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
