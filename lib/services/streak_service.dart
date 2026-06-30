import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/local_store.dart';

/// Daily streak (günlük seri): consecutive days the app was opened.
/// Pure, deterministic, offline — no backend, no analytics (§14).
class StreakState {
  final int current;
  final int best;
  final Set<String> activeDays;
  final Set<int> celebratedMilestones;

  const StreakState({
    required this.current,
    required this.best,
    this.activeDays = const {},
    this.celebratedMilestones = const {},
  });

  static const zero = StreakState(current: 0, best: 0);
}

/// Pure streak math, isolated so it can be unit-tested without Hive.
class StreakService {
  const StreakService();

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Computes the next streak count given the last recorded day.
  /// - same day  -> unchanged (idempotent)
  /// - yesterday -> +1
  /// - gap / first ever -> reset to 1
  int nextCount({
    required String? lastDayKey,
    required int currentCount,
    required DateTime today,
  }) {
    if (lastDayKey == dayKey(today)) return currentCount.clamp(1, 1 << 30);
    final yesterday = today.subtract(const Duration(days: 1));
    if (lastDayKey == dayKey(yesterday)) return currentCount + 1;
    return 1;
  }

  static const List<int> milestones = [3, 7, 30, 100];

  /// Largest milestone reached ([<= current]) that has not been celebrated yet,
  /// or null. Returning the largest means an upgrade with an existing streak
  /// celebrates once (for the highest passed milestone), not once per threshold.
  int? pendingMilestone({
    required int current,
    required Set<int> celebrated,
  }) {
    int? hit;
    for (final m in milestones) {
      if (m <= current && !celebrated.contains(m)) hit = m;
    }
    return hit;
  }

  /// Unique day keys within the last [windowDays] days (inclusive), ascending.
  List<String> pruneDays(
    Iterable<String> days, {
    required DateTime today,
    int windowDays = 120,
  }) {
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: windowDays));
    final kept = <String>{};
    for (final d in days) {
      final parsed = DateTime.tryParse(d);
      if (parsed == null) continue;
      if (!parsed.isBefore(cutoff)) kept.add(d);
    }
    final sorted = kept.toList()..sort();
    return sorted;
  }
}

const streakService = StreakService();

/// App-wide streak state, persisted in [LocalStore]. Call [recordToday] once
/// on app open (and after midnight rollovers) to advance the streak.
class StreakController extends Notifier<StreakState> {
  LocalStore get _store => LocalStore.instance;

  @override
  StreakState build() {
    final days = (_store.get<List<dynamic>>(LocalStore.kStreakDays) ?? const [])
        .map((e) => e.toString())
        .toSet();
    final celebrated =
        (_store.get<List<dynamic>>(LocalStore.kStreakMilestones) ?? const [])
            .map((e) => int.parse(e.toString()))
            .toSet();
    return StreakState(
      current: _store.get<int>(LocalStore.kStreakCount, defaultValue: 0) ?? 0,
      best: _store.get<int>(LocalStore.kStreakBest, defaultValue: 0) ?? 0,
      activeDays: days,
      celebratedMilestones: celebrated,
    );
  }

  Future<void> recordToday([DateTime? now]) async {
    final today = now ?? DateTime.now();
    final todayKey = StreakService.dayKey(today);
    final last = _store.get<String>(LocalStore.kStreakLastDate);
    if (last == todayKey) return; // already counted today

    final next = streakService.nextCount(
      lastDayKey: last,
      currentCount: state.current,
      today: today,
    );
    final best = next > state.best ? next : state.best;
    final days = streakService
        .pruneDays({...state.activeDays, todayKey}, today: today)
        .toSet();

    state = StreakState(
      current: next,
      best: best,
      activeDays: days,
      celebratedMilestones: state.celebratedMilestones,
    );
    await _store.set(LocalStore.kStreakCount, next);
    await _store.set(LocalStore.kStreakBest, best);
    await _store.set(LocalStore.kStreakLastDate, todayKey);
    await _store.set(LocalStore.kStreakDays, days.toList());
  }

  /// Marks every milestone at or below [milestone] celebrated so smaller
  /// thresholds never pop later, and persists.
  Future<void> celebrate(int milestone) async {
    final celebrated = {
      ...state.celebratedMilestones,
      ...StreakService.milestones.where((m) => m <= milestone),
    };
    state = StreakState(
      current: state.current,
      best: state.best,
      activeDays: state.activeDays,
      celebratedMilestones: celebrated,
    );
    await _store.set(LocalStore.kStreakMilestones, celebrated.toList());
  }
}

final streakProvider = NotifierProvider<StreakController, StreakState>(
  StreakController.new,
);
