import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/streak_service.dart';

/// Dedicated streak surface: hero count, 90-day activity grid, milestone badges.
class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(streakProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.streakScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Hero(current: s.current, best: s.best, l: l),
          const SizedBox(height: 28),
          _GroupLabel(l.streakGridTitle),
          const SizedBox(height: 12),
          _ActivityGrid(activeDays: s.activeDays),
          const SizedBox(height: 28),
          _GroupLabel(l.streakMilestonesTitle),
          const SizedBox(height: 12),
          _Milestones(current: s.current, l: l),
          const SizedBox(height: 24),
          Text(l.streakRule, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTypography.labelCaps);
}

class _Hero extends StatelessWidget {
  const _Hero({required this.current, required this.best, required this.l});
  final int current;
  final int best;
  final AppLocalizations l;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.saffron.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current < 1 ? l.streakNone : l.streakDays(current),
                  style: AppTypography.titleL.copyWith(fontSize: 26),
                ),
                if (best > current && best > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.streakBest(best),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.saffronDeep),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 90-day grid, weeks as columns. Active day = saffron fill, today outlined,
/// empty = soft border. Read-only.
class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid({required this.activeDays});
  final Set<String> activeDays;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 89));
    // Build columns of 7 (one week each), oldest -> newest.
    final cells = <DateTime>[
      for (var i = 0; i < 90; i++) start.add(Duration(days: i)),
    ];
    final columns = <List<DateTime>>[];
    for (var i = 0; i < cells.length; i += 7) {
      columns.add(cells.sublist(i, (i + 7).clamp(0, cells.length)));
    }
    final todayKey = StreakService.dayKey(today);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final col in columns)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                children: [
                  for (final day in col)
                    _Cell(
                      active: activeDays.contains(StreakService.dayKey(day)),
                      isToday: StreakService.dayKey(day) == todayKey,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.active, required this.isToday});
  final bool active;
  final bool isToday;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.saffron : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isToday
              ? AppColors.saffronDeep
              : Theme.of(context).dividerColor,
          width: isToday ? 1.6 : 1,
        ),
      ),
    );
  }
}

class _Milestones extends StatelessWidget {
  const _Milestones({required this.current, required this.l});
  final int current;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final next = StreakService.milestones
        .where((m) => m > current)
        .fold<int?>(null, (acc, m) => acc ?? m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final m in StreakService.milestones)
              _Badge(days: m, unlocked: current >= m),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          next == null
              ? l.streakAllMilestones
              : l.streakNextTarget(next - current, next),
          style: AppTypography.bodyM.copyWith(color: AppColors.saffronDeep),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.days, required this.unlocked});
  final int days;
  final bool unlocked;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.saffron.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppColors.saffron
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            size: 18,
            color: unlocked ? AppColors.saffronDeep : Theme.of(context).hintColor,
          ),
          const SizedBox(height: 4),
          Text(
            '$days',
            style: AppTypography.bodyM.copyWith(
              fontWeight: FontWeight.w700,
              color: unlocked ? AppColors.saffronDeep : null,
            ),
          ),
        ],
      ),
    );
  }
}
