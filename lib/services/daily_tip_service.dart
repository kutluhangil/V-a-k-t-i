import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/tip.dart';
import '../data/repositories/tip_repository.dart';

/// Picks the "tip of the day" deterministically from the date, so every device,
/// the widget, and the notification all agree on the same card (§6.4).
class DailyTipService {
  const DailyTipService();

  Tip pick(List<Tip> tips, DateTime date) {
    assert(tips.isNotEmpty, 'no tips to pick from');
    final seed = int.parse(DateFormat('yyyyMMdd').format(date));
    return tips[seed % tips.length];
  }
}

const dailyTipService = DailyTipService();

/// Today's tip, or null while the repository is loading.
final dailyTipProvider = Provider<Tip?>((ref) {
  final repo = ref.watch(tipRepositoryProvider).asData?.value;
  if (repo == null) return null;
  return dailyTipService.pick(repo.all(), DateTime.now());
});
