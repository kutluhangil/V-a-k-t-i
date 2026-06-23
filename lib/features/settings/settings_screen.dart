import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controllers/locale_controller.dart';
import '../../app/controllers/theme_controller.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/daily_tip_service.dart';
import 'settings_providers.dart';

/// Settings tab: language, theme, daily reminder, widget info, legal, about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notif = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _GroupLabel(l.settingsLanguage),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'tr', label: Text(l.languageTr)),
                ButtonSegment(value: 'en', label: Text(l.languageEn)),
                ButtonSegment(value: 'system', label: Text(l.languageSystem)),
              ],
              selected: {locale?.languageCode ?? 'system'},
              onSelectionChanged: (s) => ref
                  .read(localeProvider.notifier)
                  .setLocale(s.first == 'system' ? null : Locale(s.first)),
            ),
            const SizedBox(height: 24),
            _GroupLabel(l.settingsTheme),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l.settingsThemeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l.settingsThemeDark),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l.settingsThemeSystem),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(s.first),
            ),
            const SizedBox(height: 24),
            _GroupLabel(l.settingsNotifications),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.settingsDailyReminder),
              value: notif.enabled,
              onChanged: (v) => _toggleReminder(context, ref, v),
            ),
            if (notif.enabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(l.settingsReminderTime),
                trailing: Text(
                  _fmt(notif.hour, notif.minute),
                  style: AppTypography.bodyL,
                ),
                onTap: () => _pickTime(context, ref, notif.hour, notif.minute),
              ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.widgets_outlined),
              title: Text(l.settingsWidget),
              onTap: () => _info(context, l.settingsWidget, l.widgetInfoBody),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: Text(l.settingsLegal),
              onTap: () => _info(context, l.disclaimerTitle, l.disclaimerBody),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.favorite_border),
              title: Text(l.settingsAbout),
              subtitle: Text('${l.appTagline}\n${l.aboutBody}'),
              isThreeLine: true,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _toggleReminder(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final payload = ref.read(dailyTipProvider)?.id;
    final ok = await ref
        .read(notificationSettingsProvider.notifier)
        .setEnabled(
          value,
          title: l.dailyReminderTitle,
          body: l.dailyReminderBody,
          payload: payload,
        );
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l.notifDenied)));
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    int hour,
    int minute,
  ) async {
    final l = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) return;
    final payload = ref.read(dailyTipProvider)?.id;
    await ref
        .read(notificationSettingsProvider.notifier)
        .setTime(
          picked.hour,
          picked.minute,
          title: l.dailyReminderTitle,
          body: l.dailyReminderBody,
          payload: payload,
        );
  }

  void _info(BuildContext context, String title, String body) {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.onboardingAgree),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelCaps.copyWith(color: muted),
      ),
    );
  }
}
