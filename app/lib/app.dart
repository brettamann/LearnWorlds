// CritMathApp — the root widget. Wires routing, theme, and global providers.
// See specs/shared/project-bootstrap.md for the routing strategy.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CritMathApp extends ConsumerWidget {
  const CritMathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_appRouterProvider);
    return MaterialApp.router(
      title: 'CritMath',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Theme + locale resolution wire in here as sprint 0 progresses.
    );
  }
}

// Skeleton router — full route table comes in sprint 0 per
// specs/shared/project-bootstrap.md.
final _appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderScreen(
          message: 'CritMath skeleton — routing not yet wired',
        ),
      ),
    ],
  );
});

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
