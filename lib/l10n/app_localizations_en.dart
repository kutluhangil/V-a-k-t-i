// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vakti';

  @override
  String get appTagline => 'The right thing, at the right time.';

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabBrowse => 'Browse';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get tabSettings => 'Settings';

  @override
  String get pillarAll => 'All';

  @override
  String get pillarWellness => 'Wellness';

  @override
  String get pillarCommunication => 'Communication';

  @override
  String get saveTip => 'Save';

  @override
  String get savedTip => 'Saved';

  @override
  String get shareTip => 'Share';

  @override
  String get dailyTipLabel => 'Today\'s tip';

  @override
  String get browseTitle => 'Browse';

  @override
  String get browseAllInCategory => 'All tips';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmptyTitle => 'Nothing saved yet';

  @override
  String get favoritesEmptyBody => 'Tap the heart on a card to keep it here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDailyReminder => 'Daily reminder';

  @override
  String get settingsReminderTime => 'Reminder time';

  @override
  String get settingsWidget => 'Home screen widget';

  @override
  String get settingsLegal => 'Disclaimer & legal';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsRateApp => 'Rate the app';

  @override
  String get languageTr => 'Türkçe';

  @override
  String get languageEn => 'English';

  @override
  String get languageSystem => 'System';

  @override
  String get dailyReminderTitle => 'Today\'s tip is ready 🌅';

  @override
  String get dailyReminderBody =>
      'A small, well-timed idea is waiting for you.';

  @override
  String get disclaimerTitle => 'Good to know';

  @override
  String get disclaimerBody =>
      'Content in Vakti is for general information only and is not a substitute for professional medical, psychological, or parenting advice. For important health or child-related decisions, please consult a qualified professional.';

  @override
  String get onboarding1Title => 'The right thing, at the right time';

  @override
  String get onboarding1Body =>
      'Small, useful ideas — each one tells you when and why.';

  @override
  String get onboarding2Title => 'Two quiet columns';

  @override
  String get onboarding2Body =>
      'Wellness for everyday wellbeing, Communication for calmer moments with your child.';

  @override
  String get onboarding3Title => 'Make it yours';

  @override
  String get onboarding3Body => 'Choose your language and start reading.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingAgree => 'I understand';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get notifDenied =>
      'Allow notifications in system settings to get reminders.';

  @override
  String get widgetInfoBody =>
      'Add the Vakti widget to your home screen to see today\'s tip at a glance.';

  @override
  String get aboutBody => 'Free, ad-free, offline. Made with care.';

  @override
  String tipsLoaded(int count) {
    return '$count tips loaded';
  }
}
