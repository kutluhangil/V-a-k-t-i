import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controllers/locale_controller.dart';
import '../../app/controllers/theme_controller.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/daily_tip_service.dart';
import '../../widgets/vakti_screen_title.dart';
import '../../widgets/vakti_segmented.dart';
import 'settings_providers.dart';

/// Settings tab: language, theme, daily reminder, widget info, legal, about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notif = ref.watch(notificationSettingsProvider);

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          VaktiScreenTitle(l.settingsTitle),
          const SizedBox(height: 28),

          // Language
          _GroupLabel(l.settingsLanguage),
          VaktiSegmented<String>(
            selected: locale?.languageCode ?? 'system',
            onChanged: (v) => ref
                .read(localeProvider.notifier)
                .setLocale(v == 'system' ? null : Locale(v)),
            segments: [
              VaktiSegment('tr', l.languageTr),
              VaktiSegment('en', l.languageEn),
              VaktiSegment('system', l.languageSystem),
            ],
          ),
          const SizedBox(height: 28),

          // Theme
          _GroupLabel(l.settingsTheme),
          VaktiSegmented<ThemeMode>(
            selected: themeMode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).setThemeMode(v),
            segments: [
              VaktiSegment(ThemeMode.light, l.settingsThemeLight),
              VaktiSegment(ThemeMode.dark, l.settingsThemeDark),
              VaktiSegment(ThemeMode.system, l.settingsThemeSystem),
            ],
          ),
          const SizedBox(height: 28),

          // Notifications
          _GroupLabel(l.settingsNotifications),
          _Row(
            icon: Icons.notifications_none,
            title: l.settingsDailyReminder,
            trailing: Switch(
              value: notif.enabled,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.saffron,
              onChanged: (v) => _toggleReminder(context, ref, v),
            ),
          ),
          if (notif.enabled)
            _Row(
              icon: Icons.schedule,
              title: l.settingsReminderTime,
              onTap: () => _pickTime(context, ref, notif.hour, notif.minute),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.saffron.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _fmt(notif.hour, notif.minute),
                  style: AppTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.saffronDeep,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          Divider(color: theme.dividerColor, height: 32),

          _Row(
            icon: Icons.grid_view_outlined,
            title: l.settingsWidget,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _info(context, l.settingsWidget, l.widgetInfoBody),
          ),
          _Row(
            icon: Icons.gavel_outlined,
            title: l.settingsLegal,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _info(context, l.disclaimerTitle, l.disclaimerBody),
          ),

          const SizedBox(height: 16),

          // About block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.favorite_border, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settingsAbout,
                      style: AppTypography.titleL.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l.appTagline}\n${l.aboutBody}',
                      style: AppTypography.bodyM.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'VAKTİ V1.0.0',
              style: AppTypography.labelCaps.copyWith(
                color: theme.dividerColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              l.appTagline,
              style: AppTypography.caption.copyWith(color: theme.dividerColor),
            ),
          ),
        ],
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

/// A settings row: leading icon, title, optional trailing widget.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppTypography.bodyL)),
            ?trailing,
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelCaps.copyWith(color: muted),
      ),
    );
  }
}
