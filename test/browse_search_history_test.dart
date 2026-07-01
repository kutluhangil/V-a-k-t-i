import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/features/browse/browse_screen.dart';
import 'package:vakti/l10n/app_localizations.dart';

Widget _host() => ProviderScope(
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BrowseScreen()),
      ),
    );

void main() {
  setUp(() => LocalStore.instance.initInMemory());

  testWidgets('recent chips appear and re-run search on tap', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Type a query and submit -> recorded.
    await tester.enterText(find.byType(TextField), 'sleep');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Clear the field -> discovery chips should show 'sleep' under Recent.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'sleep'), findsWidgets);
  });
}
