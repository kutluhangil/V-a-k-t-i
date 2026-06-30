import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/streak_service.dart';
import '../../widgets/time_arc.dart';

/// Shows the full-screen milestone celebration. Returns when dismissed.
Future<void> showStreakCelebration(BuildContext context, int milestone) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'streak-celebration',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, _) => _CelebrationSheet(milestone: milestone),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    ),
  );
}

class _CelebrationSheet extends StatelessWidget {
  const _CelebrationSheet({required this.milestone});
  final int milestone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TimeArc(position: 0.5, animate: true),
                const SizedBox(height: 20),
                const Text('🔥', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  l.streakCelebrationTitle(milestone),
                  textAlign: TextAlign.center,
                  style: AppTypography.titleL,
                ),
                const SizedBox(height: 8),
                Text(
                  l.streakCelebrationBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyM,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.streakCelebrateDismiss),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Watches the streak provider and presents the celebration once per crossed
/// milestone, then marks it celebrated. Wraps the app's router output.
class StreakCelebrationListener extends ConsumerStatefulWidget {
  const StreakCelebrationListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<StreakCelebrationListener> createState() =>
      _StreakCelebrationListenerState();
}

class _StreakCelebrationListenerState
    extends ConsumerState<StreakCelebrationListener> {
  bool _showing = false;

  Future<void> _maybeCelebrate(StreakState s) async {
    if (_showing) return;
    final milestone = streakService.pendingMilestone(
      current: s.current,
      celebrated: s.celebratedMilestones,
    );
    if (milestone == null) return;
    _showing = true;
    // Persist first so a restart mid-celebration won't re-fire.
    await ref.read(streakProvider.notifier).celebrate(milestone);
    if (!mounted) {
      _showing = false;
      return;
    }
    // Present over the ROOT navigator: this listener sits above the router's
    // Navigator, so its own context has none. rootNavigatorKey does. Fetched
    // after the await so no BuildContext is held across the async gap.
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      _showing = false;
      return;
    }
    await showStreakCelebration(ctx, milestone);
    _showing = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StreakState>(streakProvider, (_, next) {
      _maybeCelebrate(next);
    });
    // Also check the initial state (recordToday in main runs before first build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeCelebrate(ref.read(streakProvider));
    });
    return widget.child;
  }
}
