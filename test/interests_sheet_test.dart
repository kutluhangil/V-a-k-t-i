import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/features/settings/settings_screen.dart';
import 'package:vakti/l10n/app_localizations.dart';

Widget _host() => ProviderScope(
      child: const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SettingsScreen()),
      ),
    );

void main() {
  setUp(() => LocalStore.instance.initInMemory());

  testWidgets('interests sheet scrolls without overflow on a short screen',
      (tester) async {
    // Small phone height where all 11 chips previously overflowed the sheet.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(const Locale('tr'));

    // Open the interests editor.
    final tile = find.text(l.settingsInterests);
    await tester.scrollUntilVisible(tile, 200);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    // Sheet is up. A RenderFlex overflow (the old bug) surfaces as a thrown
    // FlutterError captured by takeException; assert none happened and the
    // chips rendered.
    expect(tester.takeException(), isNull);
    expect(find.byType(FilterChip), findsWidgets);
  });
}
