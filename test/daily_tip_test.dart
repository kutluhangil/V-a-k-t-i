import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/services/daily_tip_service.dart';

/// Seed-determinism tests for the daily tip (§15).
void main() {
  late List<Tip> tips;

  setUpAll(() {
    final raw = File('assets/data/tips.json').readAsStringSync();
    final list = json.decode(raw) as List<dynamic>;
    tips = list.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList();
  });

  const service = DailyTipService();

  test('same date always yields the same tip', () {
    final a = service.pick(tips, DateTime(2026, 6, 23));
    final b = service.pick(tips, DateTime(2026, 6, 23, 18, 30));
    expect(a.id, b.id);
  });

  test('pick matches the documented seed formula', () {
    final date = DateTime(2026, 6, 23);
    final seed = int.parse('20260623');
    expect(service.pick(tips, date).id, tips[seed % tips.length].id);
  });

  test('different days move through the catalog', () {
    final ids = <String>{};
    for (var d = 1; d <= 20; d++) {
      ids.add(service.pick(tips, DateTime(2026, 1, d)).id);
    }
    // Not all identical — the seed actually varies the selection.
    expect(ids.length, greaterThan(1));
  });
}
