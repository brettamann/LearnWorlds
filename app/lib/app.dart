// CritMathApp — the root widget. Wires routing, theme, and global providers.
// See specs/shared/project-bootstrap.md for the routing strategy and
// specs/shared/map-screens.md for the home → region map → activity flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/screens/activity_screen.dart';
import 'ui/screens/home_map_screen.dart';
import 'ui/screens/lesson_screen.dart';
import 'ui/screens/reward_gift_screen.dart';
import 'ui/screens/sanctuary_cutscene_screen.dart';
import 'ui/screens/sanctuary_map_screen.dart';
import 'ui/screens/settings_screen.dart';

class CritMathApp extends ConsumerWidget {
  const CritMathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_appRouterProvider);
    return MaterialApp.router(
      title: 'CritMath',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

final _appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeMapScreen(),
      ),
      GoRoute(
        path: '/sanctuary',
        builder: (context, state) => const SanctuaryMapScreen(),
      ),
      GoRoute(
        path: '/sanctuary/cutscene',
        builder: (context, state) => const SanctuaryCutsceneScreen(),
      ),
      GoRoute(
        path: '/activity/:id',
        builder: (context, state) => ActivityScreen(
          activityId: state.pathParameters['id']!,
          launchExtra: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: '/lesson/:id',
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          return LessonScreen(
            lessonId: state.pathParameters['id']!,
            subModeOverride: extra?['subMode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/reward/k-mystery-egg-gift',
        builder: (context, state) => const RewardGiftScreen(),
      ),
    ],
  );
});
