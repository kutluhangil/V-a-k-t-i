import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/sources/local_store.dart';
import '../features/browse/browse_screen.dart';
import '../features/browse/category_detail_screen.dart';
import '../features/detail/detail_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/streak/streak_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import '../widgets/vakti_app_bar.dart';
import '../widgets/vakti_nav_bar.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// QA/screenshot hook: `--dart-define=SKIP_ONBOARDING=true` skips first-run
/// onboarding. Never true in a normal release build.
const _skipOnboarding = bool.fromEnvironment('SKIP_ONBOARDING');

/// App navigation: a bottom-nav shell (Feed · Browse · Favorites · Settings)
/// with the category detail pushed inside the Browse branch, and the single-tip
/// detail pushed full-screen over the shell (§6.3, §7.4).
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/feed',
  redirect: (context, state) {
    final done =
        _skipOnboarding ||
        (LocalStore.instance.get<bool>(
              LocalStore.kOnboardingDone,
              defaultValue: false,
            ) ??
            false);
    final atOnboarding = state.matchedLocation == '/onboarding';
    if (!done && !atOnboarding) return '/onboarding';
    if (done && atOnboarding) return '/feed';
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/tip/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, state) => DetailScreen(tipId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/streak',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const StreakScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ShellScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/feed', builder: (_, _) => const FeedScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/browse',
              builder: (_, _) => const BrowseScreen(),
              routes: [
                GoRoute(
                  path: ':categoryId',
                  builder: (_, state) => CategoryDetailScreen(
                    categoryId: state.pathParameters['categoryId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (_, _) => const FavoritesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int i) => navigationShell.goBranch(
    i,
    initialLocation: i == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      VaktiNavItem(icon: Icons.auto_awesome_outlined, label: l.tabFeed),
      VaktiNavItem(icon: Icons.explore_outlined, label: l.tabBrowse),
      VaktiNavItem(icon: Icons.favorite_border, label: l.tabFavorites),
      VaktiNavItem(icon: Icons.settings_outlined, label: l.tabSettings),
    ];
    return Scaffold(
      appBar: const VaktiAppBar(),
      drawer: _ShellDrawer(
        items: items,
        currentIndex: navigationShell.currentIndex,
        onSelect: _go,
      ),
      body: navigationShell,
      bottomNavigationBar: VaktiNavBar(
        items: items,
        currentIndex: navigationShell.currentIndex,
        onTap: _go,
      ),
    );
  }
}

/// Side drawer opened from the shared app bar's menu button.
class _ShellDrawer extends StatelessWidget {
  const _ShellDrawer({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<VaktiNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Vakti',
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 28),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++)
              ListTile(
                leading: Icon(items[i].icon),
                title: Text(items[i].label),
                selected: i == currentIndex,
                selectedColor: AppColors.saffronDeep,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(i);
                },
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l.appTagline,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
