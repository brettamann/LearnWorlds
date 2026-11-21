// LandscapeGate — CritMath is a landscape game, and says so when it isn't.
//
// Every scene in this game is composed wide: the meadow, the map, the shelves
// on either side of the playfield. Rotate an iPad to portrait and the whole
// thing has to squeeze into a box two-thirds the width, which makes the
// creatures small and the taps fiddly for exactly the child who can least
// afford either.
//
// The obvious fix does not work on the platform this ships on:
//
//   - `SystemChrome.setPreferredOrientations` is a real lock on iOS and
//     Android *native*. On web it does nothing.
//   - The web app manifest has an `orientation` field. iOS Safari ignores it,
//     including for a page added to the home screen. Chrome on Android
//     honours it; Safari does not.
//
// So on the device she will actually hold, the only lock available is asking.
// This is that ask: not an error, not a scold, just a picture of a tablet
// turning. It costs nothing when the game is already the right way round.
//
// Deliberately not spoken. Audio is gated behind a first user gesture on every
// browser, and this can be the first thing on screen — a narration call here
// would be silently dropped, which is worse than staying quiet.

import 'package:flutter/material.dart';

class LandscapeGate extends StatelessWidget {
  const LandscapeGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Taller than wide. A desktop window resized to portrait gets the same
    // prompt, which is the right answer there too.
    if (size.width >= size.height) return child;
    return const _RotatePrompt();
  }
}

class _RotatePrompt extends StatefulWidget {
  const _RotatePrompt();

  @override
  State<_RotatePrompt> createState() => _RotatePromptState();
}

class _RotatePromptState extends State<_RotatePrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF2E3A2C),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _turn,
              builder: (context, _) {
                // Rocks a quarter-turn and holds, rather than spinning: the
                // gesture being asked for is a rotation to landscape, not a
                // pirouette.
                final t = Curves.easeInOut.transform(
                  (_turn.value * 2).clamp(0.0, 1.0),
                );
                final hold = _turn.value > 0.75 ? 1.0 : t;
                return Transform.rotate(
                  angle: -hold * 1.5708,
                  child: Icon(
                    Icons.tablet_mac,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            // For the adult in the room. She cannot read it, which is why the
            // picture above does the work.
            const Text(
              'Turn me sideways to play',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
