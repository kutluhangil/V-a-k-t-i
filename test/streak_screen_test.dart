import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/features/streak/streak_screen.dart';
import 'package:vakti/l10n/app_localizations.dart';
import 'package:vakti/services/streak_service.dart';

Widget _host(StreakState state) {
  return ProviderScope(
    overrides: [
      streakProvider.overrideWith(() => _FakeStreak(state)),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('tr')],
      home: StreakScreen(),
    ),
  );
}

class _FakeStreak extends StreakController {
  _FakeStreak(this._state);
  final StreakState _state;
  @override
  StreakState build() => _state;
}

void main() {
  testWidgets('renders current count and milestone badges', (tester) async {
    await tester.pumpWidget(_host(const StreakState(
      current: 8,
      best: 12,
      activeDays: {},
      celebratedMilestones: {3, 7},
    )));
    await tester.pumpAndSettle();

    expect(find.text('8 days'), findsOneWidget); // hero count (streakDays)
    expect(find.text('MILESTONES'), findsOneWidget); // _GroupLabel uppercases
    expect(find.text('22 days to 30'), findsOneWidget); // next target: 30-8=22
  });
}
