import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/services/streak_service.dart';

void main() {
  const s = StreakService();
  final today = DateTime(2026, 6, 26);

  String key(DateTime d) => StreakService.dayKey(d);

  test('first ever open starts at 1', () {
    expect(s.nextCount(lastDayKey: null, currentCount: 0, today: today), 1);
  });

  test('same day is idempotent', () {
    expect(
      s.nextCount(lastDayKey: key(today), currentCount: 3, today: today),
      3,
    );
  });

  test('consecutive day increments', () {
    final yesterday = today.subtract(const Duration(days: 1));
    expect(
      s.nextCount(lastDayKey: key(yesterday), currentCount: 3, today: today),
      4,
    );
  });

  test('a skipped day resets to 1', () {
    final twoAgo = today.subtract(const Duration(days: 2));
    expect(
      s.nextCount(lastDayKey: key(twoAgo), currentCount: 9, today: today),
      1,
    );
  });

  test('dayKey is zero-padded and stable', () {
    expect(StreakService.dayKey(DateTime(2026, 1, 5)), '2026-01-05');
  });

  group('milestones', () {
    test('pendingMilestone returns largest uncelebrated <= current', () {
      expect(s.pendingMilestone(current: 7, celebrated: {}), 7);
      expect(s.pendingMilestone(current: 10, celebrated: {}), 7);
      expect(s.pendingMilestone(current: 30, celebrated: {3, 7}), 30);
    });

    test('pendingMilestone is null when none crossed or all celebrated', () {
      expect(s.pendingMilestone(current: 2, celebrated: {}), isNull);
      expect(s.pendingMilestone(current: 7, celebrated: {3, 7}), isNull);
    });

    test('milestones are the agreed thresholds', () {
      expect(StreakService.milestones, [3, 7, 30, 100]);
    });
  });

  group('pruneDays', () {
    test('drops days older than the window, dedupes, sorts ascending', () {
      final days = [
        key(today),
        key(today.subtract(const Duration(days: 5))),
        key(today.subtract(const Duration(days: 5))), // dup
        key(today.subtract(const Duration(days: 200))), // out of window
      ];
      final pruned = s.pruneDays(days, today: today);
      expect(pruned, [
        key(today.subtract(const Duration(days: 5))),
        key(today),
      ]);
    });
  });
}
