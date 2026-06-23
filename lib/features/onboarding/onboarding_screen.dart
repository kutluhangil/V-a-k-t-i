import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/controllers/locale_controller.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/sources/local_store.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/time_arc.dart';

/// First-run onboarding: welcome, the two pillars, language + disclaimer (§7.1).
/// Shown once; sets `onboardingDone` in Hive on completion.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await LocalStore.instance.set(LocalStore.kOnboardingDone, true);
    if (mounted) context.go('/feed');
  }

  void _next() {
    if (_index >= 2) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(l.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _Page(
                    hero: const TimeArc(position: 0.5, width: 180),
                    title: l.onboarding1Title,
                    body: l.onboarding1Body,
                  ),
                  _Page(
                    hero: const Text('📜  💬', style: TextStyle(fontSize: 44)),
                    title: l.onboarding2Title,
                    body: l.onboarding2Body,
                  ),
                  _LanguagePage(l: l),
                ],
              ),
            ),
            _Dots(index: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _index >= 2 ? l.onboardingStart : l.onboardingNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.hero, required this.title, required this.body});

  final Widget hero;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          hero,
          const SizedBox(height: 40),
          Text(
            title,
            style: AppTypography.titleXL,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: AppTypography.bodyL.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LanguagePage extends ConsumerWidget {
  const _LanguagePage({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    final selected = ref.watch(localeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l.onboarding3Title,
            style: AppTypography.titleXL,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l.onboarding3Body,
            style: AppTypography.bodyL.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'tr', label: Text(l.languageTr)),
              ButtonSegment(value: 'en', label: Text(l.languageEn)),
              ButtonSegment(value: 'system', label: Text(l.languageSystem)),
            ],
            selected: {selected?.languageCode ?? 'system'},
            onSelectionChanged: (s) => ref
                .read(localeProvider.notifier)
                .setLocale(s.first == 'system' ? null : Locale(s.first)),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.saffron.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.saffron.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              l.disclaimerBody,
              style: AppTypography.caption.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.saffron
                  : Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
