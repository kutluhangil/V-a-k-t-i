/// Localized daily-reminder text, mirrored from the ARB strings so it can be
/// used outside a widget context (app launch / background isolate).
class ReminderCopy {
  final String title;
  final String body;
  const ReminderCopy(this.title, this.body);
}

ReminderCopy reminderCopy(String lang) => lang == 'tr'
    ? const ReminderCopy(
        'Bugünün bilgisi hazır 🌅',
        'Doğru vakitte küçük bir fikir seni bekliyor.',
      )
    : const ReminderCopy(
        "Today's tip is ready 🌅",
        'A small, well-timed idea is waiting for you.',
      );

/// Reminder body that teases the actual tip of the day ("Bugün: Zencefil Çayı").
/// Falls back to the generic copy when no tip title is available.
String reminderBodyForTip(String lang, String? tipTitle) {
  if (tipTitle == null || tipTitle.isEmpty) return reminderCopy(lang).body;
  return lang == 'tr' ? 'Bugün: $tipTitle' : 'Today: $tipTitle';
}
