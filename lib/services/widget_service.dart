import 'package:home_widget/home_widget.dart';

import '../data/models/category.dart';
import '../data/models/tip.dart';

// Short month names per language. Avoids intl's DateFormat locale-data init
// (which would throw offline without initializeDateFormatting).
const _monthsTr = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];
const _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Bridges the daily tip into the native home screen widgets (§8).
/// Writes the data the widget reads, then asks it to redraw.
class WidgetService {
  const WidgetService();

  static const appGroupId = 'group.com.vakti.app';
  static const _androidName = 'VaktiWidgetProvider';
  static const _iOSName = 'VaktiWidget';

  Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Pushes [tip] to the widget. [streak] (consecutive-day count) renders as a
  /// "🔥 N" chip when > 1; pass 0/1 to hide it.
  Future<void> updateFromTip(
    Tip tip,
    String lang, {
    int streak = 0,
    DateTime? date,
  }) async {
    final day = date ?? DateTime.now();
    final category = categoryById(tip.category)?.title.of(lang) ?? '';
    final months = lang == 'tr' ? _monthsTr : _monthsEn;
    final dateLabel = '${day.day} ${months[day.month - 1]}';
    final streakLabel = streak > 1 ? '🔥 $streak' : '';

    await HomeWidget.setAppGroupId(appGroupId);
    await Future.wait([
      HomeWidget.saveWidgetData<String>('emoji', tip.emoji),
      HomeWidget.saveWidgetData<String>('title', tip.title.of(lang)),
      HomeWidget.saveWidgetData<String>('primary', tip.primary.of(lang)),
      HomeWidget.saveWidgetData<String>('secondary', tip.secondary.of(lang)),
      HomeWidget.saveWidgetData<String>('category', category),
      HomeWidget.saveWidgetData<String>('date', dateLabel),
      HomeWidget.saveWidgetData<String>('streak', streakLabel),
    ]);
    await HomeWidget.updateWidget(androidName: _androidName, iOSName: _iOSName);
  }
}

const widgetService = WidgetService();
