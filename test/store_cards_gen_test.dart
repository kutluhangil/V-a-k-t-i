import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/app/theme/app_colors.dart';
import 'package:vakti/widgets/time_arc.dart';

const _outDir = 'store_assets/android';
const _size = Size(1080, 1920);

class _Msg {
  const _Msg(this.headlineTr, this.headlineEn, this.subTr, this.subEn);
  final String headlineTr, headlineEn, subTr, subEn;
}

const _messages = <_Msg>[
  _Msg(
    'Doğru bilgi, doğru vakitte',
    'The right thing, at the right time',
    'Küçük, yararlı fikirler — her biri ne zaman ve neden.',
    'Small, useful ideas — each with a when and a why.',
  ),
  _Msg(
    'Ne zaman ve neden',
    'When, and why',
    'Her kart tam olarak ne yapacağını ve nedenini söyler.',
    'Every card tells you exactly what to do, and why.',
  ),
  _Msg(
    'Sağlıklı Yaşam & İletişim',
    'Wellness & Communication',
    'İki sakin sütun: günlük iyilik ve daha sakin anlar.',
    'Two quiet columns: everyday wellbeing and calmer moments.',
  ),
  _Msg(
    'Reklamsız · Çevrimdışı · Ücretsiz',
    'Ad-free · Offline · Free',
    'Hesap yok, takip yok. Her şey cihazında.',
    'No account, no tracking. Everything on your device.',
  ),
  _Msg(
    'Seri · Koleksiyon · Favoriler',
    'Streak · Collections · Favorites',
    'Alışkanlığını sürdür, sevdiklerini sakla.',
    'Keep your habit going, save the ones you love.',
  ),
];

class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.dark,
  });

  final String headline;
  final String subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.ink : AppColors.paper;
    final fg = dark ? AppColors.paper : AppColors.ink;
    return SizedBox.fromSize(
      size: _size,
      child: Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(96, 200, 96, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TimeArc(
                position: 0.5,
                width: 360,
                dotColor: AppColors.saffron,
                arcColor: fg.withValues(alpha: 0.25),
              ),
            ),
            const Spacer(),
            Text(
              headline,
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
                fontSize: 96,
                height: 1.05,
                color: fg,
              ),
            ),
            const SizedBox(height: 28),
            Container(width: 120, height: 6, color: AppColors.saffron),
            const SizedBox(height: 28),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 44,
                height: 1.35,
                color: fg.withValues(alpha: 0.85),
              ),
            ),
            const Spacer(flex: 2),
            Text(
              'Vakti',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
                fontSize: 52,
                color: fg.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _render(WidgetTester tester, Widget card, String path) async {
  final key = GlobalKey();
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: key,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: SizedBox.fromSize(size: _size, child: card),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate store cards (TR + EN)', (tester) async {
    Directory(_outDir).createSync(recursive: true);
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final dark = i.isOdd;
      await _render(
        tester,
        StoreCard(headline: m.headlineTr, subtitle: m.subTr, dark: dark),
        '$_outDir/store_${i + 1}_tr.png',
      );
      await _render(
        tester,
        StoreCard(headline: m.headlineEn, subtitle: m.subEn, dark: dark),
        '$_outDir/store_${i + 1}_en.png',
      );
    }
    for (var i = 1; i <= _messages.length; i++) {
      for (final lang in ['tr', 'en']) {
        final f = File('$_outDir/store_${i}_$lang.png');
        expect(f.existsSync(), isTrue);
        expect(f.lengthSync(), greaterThan(0));
      }
    }
  });
}
