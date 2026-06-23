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
