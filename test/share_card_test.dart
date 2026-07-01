import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/content_pillar.dart';
import 'package:vakti/data/models/localized_text.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/widgets/share_card.dart';

Tip _tip() => const Tip(
      id: 't1',
      pillar: ContentPillar.wellness,
      category: 'sleep',
      emoji: '🌙',
      title: LocalizedText(tr: 'Uyku başlığı', en: 'Sleep title'),
      primaryLabel: LocalizedText(tr: 'NE ZAMAN', en: 'WHEN'),
      primary: LocalizedText(tr: 'Akşam', en: 'Evening'),
      secondaryLabel: LocalizedText(tr: 'NEDEN', en: 'WHY'),
      secondary: LocalizedText(tr: 'Çünkü', en: 'Because it helps'),
    );

void main() {
  test('format sizes are exact', () {
    expect(ShareFormat.post.size, const Size(1080, 1350));
    expect(ShareFormat.story.size, const Size(1080, 1920));
    expect(ShareFormat.square.size, const Size(1080, 1080));
  });

  for (final format in ShareFormat.values) {
    testWidgets('ShareCard renders $format without overflow', (tester) async {
      tester.view.physicalSize = format.size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: FittedBox(
            child: SizedBox.fromSize(
              size: format.size,
              child: ShareCard(tip: _tip(), lang: 'en', format: format),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Sleep title'), findsOneWidget);
      expect(find.textContaining('Evening'), findsOneWidget);
      expect(find.textContaining('Because it helps'), findsOneWidget);
    });
  }
}
