// CritMathApp — the root widget. Wires routing, theme, and global providers.
// See specs/shared/project-bootstrap.md for the routing strategy and
// specs/shared/map-screens.md for the home → region map → activity flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'activities/activity_launch.dart';
import 'navigation/routes.dart';
import 'ui/common/touch_target.dart';
import 'ui/scopes/audio_unlock_scope.dart';
import 'ui/scopes/landscape_gate.dart';
import 'ui/screens/activity_screen.dart';
import 'ui/screens/character_creator_screen.dart';
import 'ui/screens/collection_screen.dart';
import 'ui/screens/home_map_screen.dart';
import 'ui/screens/lesson_screen.dart';
import 'ui/screens/reward_gift_screen.dart';
import 'ui/screens/sanctuary_cutscene_screen.dart';
import 'ui/screens/sanctuary_map_screen.dart';
import 'ui/screens/settings_screen.dart';

/// The only theme this app sets, and it is about reach rather than looks.
///
/// Six screens put their way out - including the activity screen, which is
/// where she spends the round - behind an app-bar `IconButton`, and Material
/// sizes those at 40 logical pixels. That is about 8mm on the iPad this is
/// played on: under [kMinTouchTarget], and under Apple's own adult minimum of
/// 44 points. The toolbar grows with the button, because a 60-pixel target
/// does not fit a 56-pixel bar.
///
/// Named rather than written inline so a test can mount a screen under the
/// theme the child actually gets. A tap-target guard running against the
/// default theme would be measuring a different app.
final ThemeData critMathTheme = ThemeData(
  appBarTheme: const AppBarTheme(
    toolbarHeight: kMinTouchTarget + 8,
    // The leading slot is 56 wide by default, which caps the button's width
    // however big its own minimum is - so setting one without the other
    // leaves a target that is tall enough and still too narrow.
    leadingWidth: kMinTouchTarget + 8,
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
    ),
  ),
);

class CritMathApp extends ConsumerWidget {
  const CritMathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_appRouterProvider);
    return MaterialApp.router(
      title: 'CritMath',
      debugShowCheckedModeBanner: false,
      theme: critMathTheme,
      routerConfig: router,
      // Wraps every route: browsers gate audio behind a real user gesture, and
      // that gate has to be opened above the router so it catches whichever
      // screen the child happens to touch first.
      //
      // The landscape gate sits inside it rather than outside, so the very
      // first touch still counts as the audio unlock even if it lands on the
      // rotate prompt.
      builder: (context, child) => AudioUnlockScope(
        child: LandscapeGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

final _appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeMapScreen(),
      ),
      GoRoute(
        path: Routes.sanctuary,
        builder: (context, state) => const SanctuaryMapScreen(),
      ),
      GoRoute(
        path: Routes.sanctuaryCutscene,
        builder: (context, state) => const SanctuaryCutsceneScreen(),
      ),
      GoRoute(
        path: Routes.activityPattern,
        builder: (context, state) => ActivityScreen(
          activityId: state.pathParameters['id']!,
          launch: state.extra is ActivityLaunch
              ? state.extra! as ActivityLaunch
              : const ActivityLaunch(),
        ),
      ),
      GoRoute(
        path: Routes.lessonPattern,
        builder: (context, state) => LessonScreen(
          lessonId: state.pathParameters['id']!,
          subModeOverride: state.extra is LessonLaunch
              ? (state.extra! as LessonLaunch).subModeId
              : null,
        ),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.characterCreator,
        builder: (context, state) => const CharacterCreatorScreen(),
      ),
      // Same screen, storefront face. A separate route rather than a flag on
      // the creator so the shop is linkable and the back arrow behaves.
      GoRoute(
        path: Routes.buddyShop,
        builder: (context, state) => const CharacterCreatorScreen(
          mode: BuddyScreenMode.shop,
        ),
      ),
      GoRoute(
        path: Routes.collection,
        builder: (context, state) => const CollectionScreen(),
      ),
      GoRoute(
        path: Routes.eggGift,
        builder: (context, state) => const RewardGiftScreen(),
      ),
    ],
  );
});
