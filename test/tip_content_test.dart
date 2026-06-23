import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/category.dart';
import 'package:vakti/data/models/content_pillar.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/data/repositories/tip_repository.dart';

/// Content + schema tests (blueprint §15). Reads the bundled asset directly
/// from disk so it runs as a plain unit test (no Flutter binding needed).
void main() {
  late TipRepository repo;
  late List<Tip> tips;

  setUpAll(() {
    final raw = File('assets/data/tips.json').readAsStringSync();
    final list = json.decode(raw) as List<dynamic>;
    tips = list.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList();
    repo = TipRepository(tips);
  });

  test('repository returns at least 60 tips', () {
    expect(repo.count, greaterThanOrEqualTo(60));
  });

  test('every tip has tr and en filled in all localized fields', () {
    for (final t in tips) {
      for (final lt in [
        t.title,
        t.primary,
        t.secondary,
        t.primaryLabel,
        t.secondaryLabel,
      ]) {
        expect(lt.tr.trim(), isNotEmpty, reason: '${t.id} tr empty');
        expect(lt.en.trim(), isNotEmpty, reason: '${t.id} en empty');
      }
    }
  });

  test('every category has at least 8 tips', () {
    for (final cat in kCategories) {
      expect(
        repo.byCategory(cat.id).length,
        greaterThanOrEqualTo(8),
        reason: '${cat.id} has fewer than 8 tips',
      );
    }
  });

  test('every tip references a known category', () {
    for (final t in tips) {
      expect(
        kCategoryById.containsKey(t.category),
        isTrue,
        reason: '${t.id} has unknown category ${t.category}',
      );
    }
  });

  test('tip category pillar matches the tip pillar', () {
    for (final t in tips) {
      expect(
        categoryById(t.category)!.pillar,
        t.pillar,
        reason: '${t.id} pillar/category mismatch',
      );
    }
  });

  test('ids are unique', () {
    final ids = tips.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('both pillars are present', () {
    expect(repo.byPillar(ContentPillar.wellness), isNotEmpty);
    expect(repo.byPillar(ContentPillar.communication), isNotEmpty);
  });

  test('content avoids banned absolute/medical claims', () {
    // Blueprint §13: no "cures / guarantees / treats" style language.
    final banned = [
      'garanti',
      'tedavi eder',
      'iyileştirir',
      'cures',
      'guarantee',
    ];
    for (final t in tips) {
      final blob = [
        t.title.tr,
        t.title.en,
        t.secondary.tr,
        t.secondary.en,
      ].join(' ').toLowerCase();
      for (final word in banned) {
        expect(
          blob.contains(word),
          isFalse,
          reason: '${t.id} contains banned claim "$word"',
        );
      }
    }
  });
}
