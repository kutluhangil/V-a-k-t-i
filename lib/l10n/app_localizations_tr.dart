// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Vakti';

  @override
  String get appTagline => 'Doğru bilgi, doğru vakitte.';

  @override
  String get landingIntro =>
      'Modern yaşamın hızında kendi ritminizi bulmanız için tasarlandı. Wellness ve iletişimin kesişim noktasında, size özel bir zaman dilimi.';

  @override
  String get landingWellnessBody =>
      'Beslenmeden uyku düzenine, günlük ritüellerinizle vücudunuzun ihtiyaç duyduğu huzuru keşfedin.';

  @override
  String get landingCommBody =>
      'Sınırlar, duygular ve derin bağlar. Kendinizle ve çevrenizle olan diyaloğunuzu güçlendirin.';

  @override
  String get landingChipWellness1 => 'Sindirimi Destekle';

  @override
  String get landingChipWellness2 => 'Enerji Akışı';

  @override
  String get landingChipComm1 => 'Duygusal Zeka';

  @override
  String get landingChipComm2 => 'Sınır Çizmek';

  @override
  String get landingCta => 'Yolculuğa Başla';

  @override
  String get landingSubtext =>
      'Tamamen reklamsız, size özel ve her zaman yanınızda.';

  @override
  String get tabFeed => 'Akış';

  @override
  String get tabBrowse => 'Gözat';

  @override
  String get tabFavorites => 'Favoriler';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get pillarAll => 'Tümü';

  @override
  String get pillarWellness => 'Sağlıklı Yaşam';

  @override
  String get pillarCommunication => 'İletişim';

  @override
  String get saveTip => 'Kaydet';

  @override
  String get savedTip => 'Kaydedildi';

  @override
  String get shareTip => 'Paylaş';

  @override
  String get dailyTipLabel => 'Günün bilgisi';

  @override
  String get browseTitle => 'Gözat';

  @override
  String get browseAllInCategory => 'Tüm bilgiler';

  @override
  String get favoritesTitle => 'Favoriler';

  @override
  String get favoritesEmptyTitle => 'Henüz bir şey kaydetmedin';

  @override
  String get favoritesEmptyBody => 'Bir kartı burada tutmak için kalbe dokun.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsDailyReminder => 'Günlük hatırlatma';

  @override
  String get settingsReminderTime => 'Hatırlatma saati';

  @override
  String get settingsWidget => 'Ana ekran widget\'ı';

  @override
  String get settingsLegal => 'Bilgilendirme ve yasal';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String get settingsRateApp => 'Uygulamayı değerlendir';

  @override
  String get settingsStreak => 'Günlük seri';

  @override
  String get settingsInterests => 'İlgi alanların';

  @override
  String get settingsInterestsHint => 'Seçtiğin konular akışta öne çıkar';

  @override
  String streakDays(int count) {
    return '$count gün';
  }

  @override
  String streakBest(int count) {
    return 'En iyi: $count';
  }

  @override
  String get streakNone => 'Bugün başla';

  @override
  String get streakScreenTitle => 'Serin';

  @override
  String get streakGridTitle => 'Son 90 gün';

  @override
  String get streakMilestonesTitle => 'Kilometre taşları';

  @override
  String streakNextTarget(int remaining, int target) {
    return '$target güne $remaining gün kaldı';
  }

  @override
  String get streakAllMilestones => 'Tüm hedefler tamam 🎉';

  @override
  String get streakRule => 'Serini sürdürmek için Vakti\'yi günde bir kez aç.';

  @override
  String streakCelebrationTitle(int days) {
    return '$days günlük seri!';
  }

  @override
  String get streakCelebrationBody => 'Buradasın. Ritmi koru.';

  @override
  String get streakCelebrateDismiss => 'Devam';

  @override
  String get searchHint => 'Bilgilerde ara';

  @override
  String get searchEmptyTitle => 'Sonuç yok';

  @override
  String get searchEmptyBody => 'Başka bir kelime dene.';

  @override
  String get searchPrompt => 'Ne zaman ve neden — aramaya başla.';

  @override
  String get languageTr => 'Türkçe';

  @override
  String get languageEn => 'English';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get dailyReminderTitle => 'Bugünün bilgisi hazır 🌅';

  @override
  String get dailyReminderBody =>
      'Doğru vakitte küçük bir fikir seni bekliyor.';

  @override
  String get disclaimerTitle => 'Bilmekte fayda var';

  @override
  String get disclaimerBody =>
      'Vakti\'deki içerikler yalnızca genel bilgilendirme amaçlıdır ve profesyonel tıbbi, psikolojik veya pedagojik tavsiye yerine geçmez. Sağlık veya çocuğunuzla ilgili önemli kararlarda lütfen uzmana danışın.';

  @override
  String get onboarding1Title => 'Doğru bilgi, doğru vakitte';

  @override
  String get onboarding1Body =>
      'Küçük, yararlı fikirler — her biri ne zaman ve neden olduğunu söyler.';

  @override
  String get onboarding2Title => 'İki sakin sütun';

  @override
  String get onboarding2Body =>
      'Günlük iyilik için Sağlıklı Yaşam, çocuğunuzla daha sakin anlar için İletişim.';

  @override
  String get onboarding3Title => 'Sana göre ayarla';

  @override
  String get onboarding3Body => 'Dilini seç ve okumaya başla.';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingStart => 'Başla';

  @override
  String get onboardingAgree => 'Anladım';

  @override
  String get onboardingSkip => 'Geç';

  @override
  String get notifDenied =>
      'Hatırlatma almak için sistem ayarlarından bildirimlere izin ver.';

  @override
  String get widgetInfoBody =>
      'Günün bilgisini bir bakışta görmek için ana ekranına Vakti widget\'ını ekle.';

  @override
  String get aboutBody => 'Ücretsiz, reklamsız, çevrimdışı. Özenle yapıldı.';

  @override
  String tipsLoaded(int count) {
    return '$count bilgi yüklendi';
  }
}
