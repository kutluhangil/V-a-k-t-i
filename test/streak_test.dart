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
}
