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
import '../l10n/app_localizations.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// QA/screenshot hook: `--dart-define=SKIP_ONBOARDING=true` skips first-run
/// onboarding. Never true in a normal release build.
const _skipOnboarding = bool.fromEnvironment('SKIP_ONBOARDING');

/// App navigation: a bottom-nav shell (Feed · Browse · Favorites · Settings)
/// with the category detail pushed inside the Browse branch, and the single-tip
/// detail pushed full-screen over the shell (§6.3, §7.4).
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/tip/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => DetailScreen(tipId: state.pathParameters['id']!),
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dynamic_feed_outlined),
            selectedIcon: const Icon(Icons.dynamic_feed),
            label: l.tabFeed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: l.tabBrowse,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: l.tabFavorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.tabSettings,
          ),
        ],
      ),
    );
  }
}
