import 'package:hive_flutter/hive_flutter.dart';

/// Thin persistence wrapper. All on-device data goes through here:
/// user settings (locale, theme, onboarding, notifications) and favorites.
/// No personal data leaves the device (blueprint §14).
///
/// Backed by Hive in production. For widget tests it can run fully in memory
/// ([initInMemory]) — Hive writes scheduled under the test fake-async clock
/// never complete and would otherwise deadlock teardown.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const _settingsBox = 'settings';
  static const _favoritesBox = 'favorites';

  // Setting keys
  static const kLocale = 'locale'; // 'tr' | 'en' | absent (system)
  static const kThemeMode = 'themeMode'; // 'light' | 'dark' | 'system'
  static const kOnboardingDone = 'onboardingDone'; // bool
  static const kNotificationsEnabled = 'notificationsEnabled'; // bool
  static const kNotificationHour = 'notificationHour'; // int
  static const kNotificationMinute = 'notificationMinute'; // int
  static const kStreakCount = 'streakCount'; // int — current consecutive days
  static const kStreakBest = 'streakBest'; // int — best streak ever
  static const kStreakLastDate = 'streakLastDate'; // 'yyyy-MM-dd'
  static const kStreakDays = 'streakDays'; // List<String> active day keys (yyyy-MM-dd)
  static const kStreakMilestones = 'streakMilestones'; // List<int> celebrated thresholds
  static const kInterests = 'interests'; // List<String> category ids

  bool _memory = false;
  final Map<String, Object?> _memSettings = {};
  final Map<String, Object?> _memFavorites = {};

  late Box _settings;
  late Box _favorites;

  Future<void> init() async {
    _memory = false;
    await Hive.initFlutter();
    await _openBoxes();
  }

  /// Test-only: initialize Hive against a real directory (no path_provider).
  Future<void> initWithPath(String path) async {
    _memory = false;
    Hive.init(path);
    await _openBoxes();
  }

  /// Test-only: pure in-memory backing, no Hive.
  void initInMemory() {
    _memory = true;
    _memSettings.clear();
    _memFavorites.clear();
  }

  /// Test-only: wipe in-memory state between tests.
  void resetInMemory() {
    _memSettings.clear();
    _memFavorites.clear();
  }

  Future<void> _openBoxes() async {
    _settings = await Hive.openBox(_settingsBox);
    _favorites = await Hive.openBox(_favoritesBox);
  }

  /// Test-only: close all boxes so a later [initWithPath] starts fresh.
  Future<void> close() => Hive.close();

  // Generic settings access
  T? get<T>(String key, {T? defaultValue}) {
    if (_memory) return (_memSettings[key] as T?) ?? defaultValue;
    return _settings.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> set<T>(String key, T value) async {
    if (_memory) {
      _memSettings[key] = value;
      return;
    }
    await _settings.put(key, value);
  }

  Future<void> remove(String key) async {
    if (_memory) {
      _memSettings.remove(key);
      return;
    }
    await _settings.delete(key);
  }

  // Favorites (tip ids). Used from Phase 3 onward.
  List<String> get favoriteIds => _memory
      ? _memFavorites.keys.toList()
      : _favorites.keys.map((e) => e.toString()).toList();

  bool isFavorite(String id) =>
      _memory ? _memFavorites.containsKey(id) : _favorites.containsKey(id);

  Future<void> addFavorite(String id) async {
    final stamp = DateTime.now().toIso8601String();
    if (_memory) {
      _memFavorites[id] = stamp;
      return;
    }
    await _favorites.put(id, stamp);
  }

  Future<void> removeFavorite(String id) async {
    if (_memory) {
      _memFavorites.remove(id);
      return;
    }
    await _favorites.delete(id);
  }
}
