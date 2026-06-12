// SanctuaryCutsceneScreen — the story kickoff at the F0 anchor on the
// Sanctuary map. Keeper Haddock greets the kid; a baby dragon bounces beside
// him. Paged dialogue advances on each tap of the NextArrowButton; the final
// page marks F0 as explored and returns the kid to the map.
//
// Per specs/shared/ui-affordances.md the advance affordance is always the
// big amber wiggling arrow. Per specs/shared/activity-progress-bar.md we
// don't celebrate here (no reward yet — this is the framing scene).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../providers/exploration_provider.dart';
import '../../providers/save_provider.dart';
import '../widgets/caption_overlay.dart';
import '../widgets/next_arrow_button.dart';

/// Code of the Sanctuary's "story kickoff" anchor (the magenta `#FF00F0`).
/// Marked explored after this screen's final page advances.
const int kSanctuaryKickoffCode = 0xF0;

class SanctuaryCutsceneScreen extends ConsumerStatefulWidget {
  const SanctuaryCutsceneScreen({super.key});

  @override
  ConsumerState<SanctuaryCutsceneScreen> createState() =>
      _SanctuaryCutsceneScreenState();
}

class _SanctuaryCutsceneScreenState
    extends ConsumerState<SanctuaryCutsceneScreen> {
  int _page = 0;

  // Haddock's dialogue, broken into segments that flow naturally one at a
  // time. Keep each beat short — kids will tap through quickly.
  static const List<String> _pages = [
    'Well hello there, adventurer! I\'m Haddock.',
    'I\'m in charge of this mystical sanctuary.',
    'We have all sorts of creatures living here — from this cute little dragon to unicorns, mermaids, and more!',
    "Thing is, it's a lot for anyone to do.",
    'I need your help around the various parts of the sanctuary.',
    "You'll be my honorary keeper!",
    'Go ahead and follow me when you\'re ready!',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentPage());
  }

  void _speakCurrentPage() {
    if (!mounted) return;
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _pages[_page],
            cueId: 'sanctuary:kickoff-p$_page',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  void _advance() {
    if (_page < _pages.length - 1) {
      setState(() => _page++);
      _speakCurrentPage();
      return;
    }
    // Final page — mark explored and return to the map.
    ref.read(narrationPlayerProvider.notifier).clear();
    ref.read(explorationProvider.notifier).markCompleted(kSanctuaryKickoffCode);
    ref.read(saveCoordinatorProvider).persist();
    context.go('/sanctuary');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.countingParadeMeadow,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Image.asset(
                            AssetPaths.sanctuaryKeeperMystic,
                            height: 360,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: _BouncingDragon(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SpeechBubble(text: _pages[_page]),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: NextArrowButton(
                            key: const ValueKey('cutscene-next'),
                            onPressed: _advance,
                            label: _page < _pages.length - 1
                                ? 'Next'
                                : "Let's explore!",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Persistent back-to-Sanctuary affordance, same as the lesson
          // screen, so the kid can bail out mid-cutscene.
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: _BackButton(
                onPressed: () {
                  ref.read(narrationPlayerProvider.notifier).clear();
                  context.go('/sanctuary');
                },
              ),
            ),
          ),
          const CaptionOverlay(),
        ],
      ),
    );
  }
}

class _BouncingDragon extends StatefulWidget {
  const _BouncingDragon();

  @override
  State<_BouncingDragon> createState() => _BouncingDragonState();
}

class _BouncingDragonState extends State<_BouncingDragon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, child) {
        // Two bounces per cycle: jump up & down twice, with subtle wiggle.
        final t = _ctl.value;
        final bounce = math.sin(t * 4 * math.pi).abs();
        final wobble = math.sin(t * 2 * math.pi) * 0.06;
        final dy = -bounce * 28;
        final scaleY = 1.0 - bounce * 0.12;
        final scaleX = 1.0 + bounce * 0.10;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: wobble,
            child: Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        AssetPaths.countingParadeBabyDragon,
        width: 160,
        height: 160,
        fit: BoxFit.contain,
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
        color: Colors.white.withValues(alpha: 0.92),
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
          fontSize: 22,
          height: 1.35,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.white.withValues(alpha: 0.88),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_back,
            size: 28,
            color: Colors.black87,
            semanticLabel: 'Back to the Sanctuary',
          ),
        ),
      ),
    );
  }
}
