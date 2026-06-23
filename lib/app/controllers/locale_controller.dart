import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/local_store.dart';

/// App locale. `null` means follow the system language.
/// Persisted in Hive so the choice survives restarts.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = LocalStore.instance.get<String>(LocalStore.kLocale);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale; // update UI first, then persist
    if (locale == null) {
      await LocalStore.instance.remove(LocalStore.kLocale);
    } else {
      await LocalStore.instance.set(LocalStore.kLocale, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// Convenience: the effective language code given the active platform locale.
String effectiveLanguageCode(Locale? selected, Locale platform) {
  final code = selected?.languageCode ?? platform.languageCode;
  return code == 'tr' ? 'tr' : 'en';
}
