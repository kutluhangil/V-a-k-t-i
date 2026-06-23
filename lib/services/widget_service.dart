import 'package:home_widget/home_widget.dart';

import '../data/models/tip.dart';

/// Bridges the daily tip into the native home screen widgets (§8).
/// Writes the data both platforms read, then asks them to redraw.
class WidgetService {
  const WidgetService();

  static const appGroupId = 'group.com.vakti.app';
  static const _androidName = 'VaktiWidgetProvider';
  static const _iOSName = 'VaktiWidget';

  Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  Future<void> updateFromTip(Tip tip, String lang) async {
    await HomeWidget.setAppGroupId(appGroupId);
    await Future.wait([
      HomeWidget.saveWidgetData<String>('emoji', tip.emoji),
      HomeWidget.saveWidgetData<String>('title', tip.title.of(lang)),
      HomeWidget.saveWidgetData<String>('primary', tip.primary.of(lang)),
      HomeWidget.saveWidgetData<String>('secondary', tip.secondary.of(lang)),
    ]);
    await HomeWidget.updateWidget(androidName: _androidName, iOSName: _iOSName);
  }
}

const widgetService = WidgetService();
