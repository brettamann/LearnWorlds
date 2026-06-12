// RewardGiftScreen — the in-lesson "Haddock hands you the mystery egg" beat.
// Fires once, immediately after the first Counting Parade round resolves,
// before the kid is offered any replay / challenge surface. The keeper
// stands beside an oversized stage-1 egg, narrates the gift, and a single
// Continue arrow hands off to the Sanctuary map.
//
// Routing rationale: hosting this as a route (`/reward/k-mystery-egg-gift`)
// rather than as a modal sheet on the activity screen means the kid can't
// dismiss it by backing out, the activity stack is fully torn down (the
// parade scene won't peek through), and the next-arrow behaviour matches
// the rest of the "you're done, go next" affordances in the game.
//
// At the moment this is the only reward gift screen so the dialogue +
// sprite are hard-coded. When other tracks land (Wundle Spark, Hero Badge)
// this widget should generalise to take a RewardTrack + first-stage
// presentation parameters.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../widgets/next_arrow_button.dart';

class RewardGiftScreen extends ConsumerStatefulWidget {
  const RewardGiftScreen({super.key});

  static const String kMysteryEggDialog =
      'I found this while you were counting, and it was all by itself! '
      "It needs someone to care for it. Keep it with you — maybe it'll "
      'hatch some day!';

  @override
  ConsumerState<RewardGiftScreen> createState() => _RewardGiftScreenState();
}

class _RewardGiftScreenState extends ConsumerState<RewardGiftScreen> {
  bool _narrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _narrateOnce());
  }

  void _narrateOnce() {
    if (_narrated || !mounted) return;
    _narrated = true;
    // Speech bubble already shows the line on screen — use the no-caption
    // variant so the bottom caption bar doesn't double up.
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          const NarrationLine(
            text: RewardGiftScreen.kMysteryEggDialog,
            cueId: 'reward:k-mystery-egg:gift',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  void _onContinue() {
    ref.read(narrationPlayerProvider.notifier).clear();
    context.go('/sanctuary');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Same meadow background as the lesson + parade so this scene
          // reads as a direct continuation rather than a separate place.
          Image.asset(
            AssetPaths.countingParadeMeadow,
            fit: BoxFit.cover,
          ),
          // Soft dim so the keeper + egg pop forward against the meadow.
          Container(color: Colors.black.withValues(alpha: 0.18)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Nicely counted!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 5,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Keeper portrait.
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Image.asset(
                              AssetPaths.sanctuaryKeeperMystic,
                              height: 320,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Speech bubble + the gift sprite together so the
                        // kid reads "Haddock is presenting THIS egg".
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SpeechBubble(
                                text: RewardGiftScreen.kMysteryEggDialog,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    AssetPaths.kMysteryEggStage(1),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: NextArrowButton(
                      key: const ValueKey('reward-gift-continue'),
                      onPressed: _onContinue,
                      label: 'Continue',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          height: 1.35,
          color: Colors.black87,
        ),
      ),
    );
  }
}
