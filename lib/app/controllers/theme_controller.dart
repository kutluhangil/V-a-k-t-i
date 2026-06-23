import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/local_store.dart';

/// Light / dark / system theme selection, persisted in Hive.
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = LocalStore.instance.get<String>(LocalStore.kThemeMode);
    return _parse(raw);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode; // update UI first, then persist
    await LocalStore.instance.set(LocalStore.kThemeMode, mode.name);
  }

  ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
