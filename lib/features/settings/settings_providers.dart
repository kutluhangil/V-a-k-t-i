import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/local_store.dart';
import '../../services/notification_service.dart';

/// User notification preferences (off by default, §9.1).
class NotificationPrefs {
  final bool enabled;
  final int hour;
  final int minute;

  const NotificationPrefs({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  NotificationPrefs copyWith({bool? enabled, int? hour, int? minute}) =>
      NotificationPrefs(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

class NotificationSettingsController extends Notifier<NotificationPrefs> {
  LocalStore get _store => LocalStore.instance;

  @override
  NotificationPrefs build() => NotificationPrefs(
    enabled:
        _store.get<bool>(
          LocalStore.kNotificationsEnabled,
          defaultValue: false,
        ) ??
        false,
    hour: _store.get<int>(LocalStore.kNotificationHour, defaultValue: 9) ?? 9,
    minute:
        _store.get<int>(LocalStore.kNotificationMinute, defaultValue: 0) ?? 0,
  );

  /// Turns the daily reminder on/off. Returns false if the OS denied permission.
  Future<bool> setEnabled(
    bool value, {
    required String title,
    required String body,
    String? payload,
  }) async {
    if (value) {
      final granted = await notificationService.requestPermissions();
      if (!granted) return false;
      state = state.copyWith(enabled: true);
      await _store.set(LocalStore.kNotificationsEnabled, true);
      await notificationService.scheduleDaily(
        hour: state.hour,
        minute: state.minute,
        title: title,
        body: body,
        payload: payload,
      );
      return true;
    }
    state = state.copyWith(enabled: false);
    await _store.set(LocalStore.kNotificationsEnabled, false);
    await notificationService.cancelDaily();
    return true;
  }

  Future<void> setTime(
    int hour,
    int minute, {
    required String title,
    required String body,
    String? payload,
  }) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _store.set(LocalStore.kNotificationHour, hour);
    await _store.set(LocalStore.kNotificationMinute, minute);
    if (state.enabled) {
      await notificationService.scheduleDaily(
        hour: hour,
        minute: minute,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsController, NotificationPrefs>(
      NotificationSettingsController.new,
    );
