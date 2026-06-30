import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/streak/streak_celebration.dart';
import '../l10n/app_localizations.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root app: binds theme (light/dark/system) and locale (tr/en/system),
/// both driven by Riverpod + persisted in Hive, over a go_router shell.
class VaktiApp extends ConsumerWidget {
  const VaktiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
      builder: (context, child) =>
          StreakCelebrationListener(child: child ?? const SizedBox.shrink()),
    );
  }
}
