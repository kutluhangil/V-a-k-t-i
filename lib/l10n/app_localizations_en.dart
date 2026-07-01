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
  String get landingIntro =>
      'Designed to help you find your own rhythm in the pace of modern life. At the meeting point of wellness and communication — a moment of time made for you.';

  @override
  String get landingWellnessBody =>
      'From nutrition to sleep, discover the calm your body needs through your daily rituals.';

  @override
  String get landingCommBody =>
      'Boundaries, emotions, and deeper bonds. Strengthen the dialogue with yourself and the people around you.';

  @override
  String get landingChipWellness1 => 'Support Digestion';

  @override
  String get landingChipWellness2 => 'Energy Flow';

  @override
  String get landingChipComm1 => 'Emotional Intelligence';

  @override
  String get landingChipComm2 => 'Setting Boundaries';

  @override
  String get landingCta => 'Begin the journey';

  @override
  String get landingSubtext =>
      'Completely ad-free, personal, and always with you.';

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
  String get feedTodayBadge => 'Today\'s Card';

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
  String get favoritesSegment => 'Favorites';

  @override
  String get collectionsSegment => 'Collections';

  @override
  String get newCollection => 'New collection';

  @override
  String get collectionNameHint => 'Collection name';

  @override
  String get renameCollection => 'Rename';

  @override
  String get deleteCollection => 'Delete';

  @override
  String get addToCollection => 'Add to collection';

  @override
  String get collectionsEmptyTitle => 'No collections yet';

  @override
  String get collectionsEmptyBody => 'Create a list to group tips your way.';

  @override
  String get collectionEmptyTitle => 'This collection is empty';

  @override
  String get collectionEmptyBody => 'Add tips from any card.';

  @override
  String get createAction => 'Create';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get saveAction => 'Save';

  @override
  String collectionCount(int count) {
    return '$count tips';
  }

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
  String get settingsStreak => 'Daily streak';

  @override
  String get settingsInterests => 'Your interests';

  @override
  String get settingsInterestsHint =>
      'Topics you pick rise to the top of your feed';

  @override
  String streakDays(int count) {
    return '$count days';
  }

  @override
  String streakBest(int count) {
    return 'Best: $count';
  }

  @override
  String get streakNone => 'Start today';

  @override
  String get streakScreenTitle => 'Your streak';

  @override
  String get streakGridTitle => 'Last 90 days';

  @override
  String get streakMilestonesTitle => 'Milestones';

  @override
  String streakNextTarget(int remaining, int target) {
    return '$remaining days to $target';
  }

  @override
  String get streakAllMilestones => 'All milestones reached 🎉';

  @override
  String get streakRule => 'Open Vakti once a day to keep your streak going.';

  @override
  String streakCelebrationTitle(int days) {
    return '$days-day streak!';
  }

  @override
  String get streakCelebrationBody => 'You showed up. Keep the rhythm going.';

  @override
  String get streakCelebrateDismiss => 'Continue';

  @override
  String get searchHint => 'Search tips';

  @override
  String get searchEmptyTitle => 'No results';

  @override
  String get searchEmptyBody => 'Try another word.';

  @override
  String get searchPrompt => 'When and why — start searching.';

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
  String get relatedTitle => 'Related cards';

  @override
  String get shareFormatTitle => 'Share as';

  @override
  String get shareFormatPost => 'Post';

  @override
  String get shareFormatStory => 'Story';

  @override
  String get shareFormatSquare => 'Square';

  @override
  String get popularLabel => 'Popular';

  @override
  String get recentSearchesLabel => 'Recent searches';

  @override
  String get clearAll => 'Clear';

  @override
  String tipsLoaded(int count) {
    return '$count tips loaded';
  }
}
