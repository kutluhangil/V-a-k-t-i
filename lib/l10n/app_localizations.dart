import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vakti'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'The right thing, at the right time.'**
  String get appTagline;

  /// No description provided for @landingIntro.
  ///
  /// In en, this message translates to:
  /// **'Designed to help you find your own rhythm in the pace of modern life. At the meeting point of wellness and communication — a moment of time made for you.'**
  String get landingIntro;

  /// No description provided for @landingWellnessBody.
  ///
  /// In en, this message translates to:
  /// **'From nutrition to sleep, discover the calm your body needs through your daily rituals.'**
  String get landingWellnessBody;

  /// No description provided for @landingCommBody.
  ///
  /// In en, this message translates to:
  /// **'Boundaries, emotions, and deeper bonds. Strengthen the dialogue with yourself and the people around you.'**
  String get landingCommBody;

  /// No description provided for @landingChipWellness1.
  ///
  /// In en, this message translates to:
  /// **'Support Digestion'**
  String get landingChipWellness1;

  /// No description provided for @landingChipWellness2.
  ///
  /// In en, this message translates to:
  /// **'Energy Flow'**
  String get landingChipWellness2;

  /// No description provided for @landingChipComm1.
  ///
  /// In en, this message translates to:
  /// **'Emotional Intelligence'**
  String get landingChipComm1;

  /// No description provided for @landingChipComm2.
  ///
  /// In en, this message translates to:
  /// **'Setting Boundaries'**
  String get landingChipComm2;

  /// No description provided for @landingCta.
  ///
  /// In en, this message translates to:
  /// **'Begin the journey'**
  String get landingCta;

  /// No description provided for @landingSubtext.
  ///
  /// In en, this message translates to:
  /// **'Completely ad-free, personal, and always with you.'**
  String get landingSubtext;

  /// No description provided for @tabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get tabFeed;

  /// No description provided for @tabBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get tabBrowse;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @pillarAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pillarAll;

  /// No description provided for @pillarWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get pillarWellness;

  /// No description provided for @pillarCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get pillarCommunication;

  /// No description provided for @saveTip.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveTip;

  /// No description provided for @savedTip.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTip;

  /// No description provided for @shareTip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareTip;

  /// No description provided for @dailyTipLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tip'**
  String get dailyTipLabel;

  /// No description provided for @feedTodayBadge.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Card'**
  String get feedTodayBadge;

  /// No description provided for @browseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseTitle;

  /// No description provided for @browseAllInCategory.
  ///
  /// In en, this message translates to:
  /// **'All tips'**
  String get browseAllInCategory;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a card to keep it here.'**
  String get favoritesEmptyBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsDailyReminder;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get settingsReminderTime;

  /// No description provided for @settingsWidget.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get settingsWidget;

  /// No description provided for @settingsLegal.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer & legal'**
  String get settingsLegal;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get settingsRateApp;

  /// No description provided for @settingsStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily streak'**
  String get settingsStreak;

  /// No description provided for @settingsInterests.
  ///
  /// In en, this message translates to:
  /// **'Your interests'**
  String get settingsInterests;

  /// No description provided for @settingsInterestsHint.
  ///
  /// In en, this message translates to:
  /// **'Topics you pick rise to the top of your feed'**
  String get settingsInterestsHint;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String streakDays(int count);

  /// No description provided for @streakBest.
  ///
  /// In en, this message translates to:
  /// **'Best: {count}'**
  String streakBest(int count);

  /// No description provided for @streakNone.
  ///
  /// In en, this message translates to:
  /// **'Start today'**
  String get streakNone;

  /// No description provided for @streakScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your streak'**
  String get streakScreenTitle;

  /// No description provided for @streakGridTitle.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get streakGridTitle;

  /// No description provided for @streakMilestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get streakMilestonesTitle;

  /// No description provided for @streakNextTarget.
  ///
  /// In en, this message translates to:
  /// **'{remaining} days to {target}'**
  String streakNextTarget(int remaining, int target);

  /// No description provided for @streakAllMilestones.
  ///
  /// In en, this message translates to:
  /// **'All milestones reached 🎉'**
  String get streakAllMilestones;

  /// No description provided for @streakRule.
  ///
  /// In en, this message translates to:
  /// **'Open Vakti once a day to keep your streak going.'**
  String get streakRule;

  /// No description provided for @streakCelebrationTitle.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak!'**
  String streakCelebrationTitle(int days);

  /// No description provided for @streakCelebrationBody.
  ///
  /// In en, this message translates to:
  /// **'You showed up. Keep the rhythm going.'**
  String get streakCelebrationBody;

  /// No description provided for @streakCelebrateDismiss.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get streakCelebrateDismiss;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tips'**
  String get searchHint;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another word.'**
  String get searchEmptyBody;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'When and why — start searching.'**
  String get searchPrompt;

  /// No description provided for @languageTr.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTr;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @dailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tip is ready 🌅'**
  String get dailyReminderTitle;

  /// No description provided for @dailyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'A small, well-timed idea is waiting for you.'**
  String get dailyReminderBody;

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'Content in Vakti is for general information only and is not a substitute for professional medical, psychological, or parenting advice. For important health or child-related decisions, please consult a qualified professional.'**
  String get disclaimerBody;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'The right thing, at the right time'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Small, useful ideas — each one tells you when and why.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Two quiet columns'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Wellness for everyday wellbeing, Communication for calmer moments with your child.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Choose your language and start reading.'**
  String get onboarding3Body;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @onboardingAgree.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get onboardingAgree;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @notifDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in system settings to get reminders.'**
  String get notifDenied;

  /// No description provided for @widgetInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Add the Vakti widget to your home screen to see today\'s tip at a glance.'**
  String get widgetInfoBody;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Free, ad-free, offline. Made with care.'**
  String get aboutBody;

  /// No description provided for @tipsLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count} tips loaded'**
  String tipsLoaded(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
