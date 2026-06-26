import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'data/sources/asset_tip_source.dart';
import 'data/sources/local_store.dart';
import 'services/daily_tip_service.dart';
import 'services/notification_service.dart';
import 'services/reminder_copy.dart';
import 'services/streak_service.dart';
import 'services/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.instance.init();

  // Shared Riverpod container so the streak recorded at startup is the same
  // state the UI reads this session.
  final container = ProviderContainer();
  await container.read(streakProvider.notifier).recordToday();

  // Native-only startup (notifications, home widget, background work).
  // Skipped on web — these plugins have no web implementation and would
  // throw UnimplementedError / UnsupportedError before the first frame.
  if (!kIsWeb) {
    await notificationService.init();
    notificationService.onSelectTip = _routeToTip;

    await _bootstrapDailyOutputs();

    // Widget tap (vakti://tip) -> refresh + open the tip.
    HomeWidget.registerInteractivityCallback(_widgetBackgroundCallback);
    HomeWidget.widgetClicked.listen((_) => _routeToTip(null));

    if (Platform.isAndroid) {
      try {
        await Workmanager().initialize(_workmanagerCallback);
        await Workmanager().registerPeriodicTask(
          'vakti-daily',
          'vakti-daily-refresh',
          frequency: const Duration(hours: 24),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      } catch (_) {}
    }

    // If launched by tapping a notification, open that tip after first frame.
    final payload = await notificationService.launchPayload();
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _routeToTip(payload));
    }
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const VaktiApp()),
  );
}

@pragma('vm:entry-point')
Future<void> _widgetBackgroundCallback(Uri? uri) async {
  await _refreshWidget();
}

@pragma('vm:entry-point')
void _workmanagerCallback() {
  Workmanager().executeTask((_, _) async {
    await _refreshWidget();
    return true;
  });
}

String _currentLang() {
  final stored = LocalStore.instance.get<String>(LocalStore.kLocale);
  final code = stored ?? PlatformDispatcher.instance.locale.languageCode;
  return code == 'tr' ? 'tr' : 'en';
}

Future<void> _refreshWidget() async {
  try {
    final tips = await const AssetTipSource().load();
    final tip = dailyTipService.pick(tips, DateTime.now());
    final streak =
        LocalStore.instance.get<int>(
          LocalStore.kStreakCount,
          defaultValue: 0,
        ) ??
        0;
    await widgetService.updateFromTip(tip, _currentLang(), streak: streak);
  } catch (_) {}
}

Future<void> _bootstrapDailyOutputs() async {
  await _refreshWidget();

  final enabled =
      LocalStore.instance.get<bool>(
        LocalStore.kNotificationsEnabled,
        defaultValue: false,
      ) ??
      false;
  if (!enabled) return;

  try {
    final hour =
        LocalStore.instance.get<int>(
          LocalStore.kNotificationHour,
          defaultValue: 9,
        ) ??
        9;
    final minute =
        LocalStore.instance.get<int>(
          LocalStore.kNotificationMinute,
          defaultValue: 0,
        ) ??
        0;
    final lang = _currentLang();
    final copy = reminderCopy(lang);
    final tips = await const AssetTipSource().load();
    final tip = dailyTipService.pick(tips, DateTime.now());
    await notificationService.scheduleDaily(
      hour: hour,
      minute: minute,
      title: copy.title,
      body: reminderBodyForTip(lang, tip.title.of(lang)),
      payload: tip.id,
    );
  } catch (_) {}
}

void _routeToTip(String? tipId) {
  appRouter.go('/feed');
  if (tipId != null && tipId.isNotEmpty) {
    appRouter.push('/tip/$tipId');
  }
}
