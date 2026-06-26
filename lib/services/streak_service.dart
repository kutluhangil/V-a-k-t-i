import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/local_store.dart';

/// Daily streak (günlük seri): consecutive days the app was opened.
/// Pure, deterministic, offline — no backend, no analytics (§14).
class StreakState {
  final int current;
  final int best;

  const StreakState({required this.current, required this.best});

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
}

const streakService = StreakService();

/// App-wide streak state, persisted in [LocalStore]. Call [recordToday] once
/// on app open (and after midnight rollovers) to advance the streak.
class StreakController extends Notifier<StreakState> {
  LocalStore get _store => LocalStore.instance;

  @override
  StreakState build() => StreakState(
    current: _store.get<int>(LocalStore.kStreakCount, defaultValue: 0) ?? 0,
    best: _store.get<int>(LocalStore.kStreakBest, defaultValue: 0) ?? 0,
  );

  Future<void> recordToday([DateTime? now]) async {
    final today = now ?? DateTime.now();
    final last = _store.get<String>(LocalStore.kStreakLastDate);
    if (last == StreakService.dayKey(today)) return; // already counted today

    final next = streakService.nextCount(
      lastDayKey: last,
      currentCount: state.current,
      today: today,
    );
    final best = next > state.best ? next : state.best;

    state = StreakState(current: next, best: best);
    await _store.set(LocalStore.kStreakCount, next);
    await _store.set(LocalStore.kStreakBest, best);
    await _store.set(LocalStore.kStreakLastDate, StreakService.dayKey(today));
  }
}

final streakProvider = NotifierProvider<StreakController, StreakState>(
  StreakController.new,
);
