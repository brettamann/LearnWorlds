// CardRevealOverlay — the moment a creature card is found.
//
// This is the one beat in the reward loop that is allowed to be theatrical.
// Everything else in the round-pass celebration is deliberately quick and
// non-blocking (see specs/shared/activity-progress-bar.md and the KeeperAside
// work), because a modal every five taps is what made the game drag. A card is
// different: it happens roughly once a sitting, it is the thing that changes
// her world rather than a counter, and Appendix A of the engagement plan is
// specific that what sustains a child is surprise in the reward *presentation*.
//
// It speaks, and it waits.
//
// It used to do neither. The card came up, showed a name in text a pre-reader
// cannot read, and took itself away after five seconds — so the entire content
// of the reward was a picture she got no name for and might not have finished
// looking at. Both halves of that are fixed here:
//
//   - **The name is spoken.** Enqueued rather than spoken outright, because
//     this beat lands while the keeper is still finishing the round;
//     NarrationPlayer's queue is what lets it wait its turn instead of cutting
//     the keeper off mid-word. That constraint is why the reveal was silent
//     for so long.
//   - **It waits for a tap**, with a pulsing hand for a prompt and, if she
//     doesn't take it, the words spoken a few seconds later. She decides when
//     she is done looking at it.
//
// There is still a fallback dismiss, at half a minute rather than five
// seconds. A five-year-old who wanders off mid-reveal must not come back to a
// game that is stuck, and that hazard did not go away just because the card
// got more patient.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/creature_card_catalog.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../providers/collection_provider.dart';
import '../../theme/app_colors.dart';
import 'reveal_card.dart';

/// How long before the card gives up waiting and takes itself away.
const Duration _kFallbackDismiss = Duration(seconds: 30);

/// How long after the card lands before the tap prompt is spoken. Long enough
/// that a child who taps straight away never hears it.
const Duration _kNudgeAfter = Duration(seconds: 6);

class CardRevealOverlay extends ConsumerStatefulWidget {
  const CardRevealOverlay({super.key});

  @override
  ConsumerState<CardRevealOverlay> createState() => _CardRevealOverlayState();
}

class _CardRevealOverlayState extends ConsumerState<CardRevealOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in;
  Timer? _fallback;
  Timer? _nudge;
  String? _showing;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      duration: const Duration(milliseconds: 620),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _nudge?.cancel();
    _in.dispose();
    super.dispose();
  }

  void _open(String cardId) {
    _showing = cardId;
    _in.forward(from: 0);
    ref.read(feedbackEngineProvider).celebrate();

    final card = creatureCardById(cardId);
    if (card != null) {
      // Enqueued, not spoken: the keeper is very likely mid-line behind this.
      ref.narration.say(
        cardRevealLine(card),
        cueId: 'card-reveal:${card.id}',
        speaker: kKeeperSpeaker,
        // The card already shows the name in bigger type than the caption
        // bar would.
        caption: false,
        queue: true,
      );
    }

    _nudge?.cancel();
    _nudge = Timer(_kNudgeAfter, () {
      if (!mounted || _showing == null) return;
      ref.narration.say(
        kCardTapToContinueLine,
        cueId: 'card-reveal:nudge',
        caption: false,
        queue: true,
      );
    });

    _fallback?.cancel();
    _fallback = Timer(_kFallbackDismiss, _close);
  }

  void _close() {
    _fallback?.cancel();
    _nudge?.cancel();
    if (!mounted) return;
    _showing = null;
    ref.read(pendingCardRevealProvider.notifier).dismiss();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingCardRevealProvider, (previous, next) {
      if (next == null || next == _showing) return;
      _open(next);
    });

    final pending = ref.watch(pendingCardRevealProvider);
    final card = pending == null ? null : creatureCardById(pending);
    if (card == null) return const SizedBox.shrink();

    final accent = _rarityColor(card.rarity);
    return RevealCardStage(
      animation: _in,
      onTap: _close,
      child: RevealCardFace(
        eyebrow: 'A new friend!',
        spriteAsset: card.spriteAsset,
        title: card.displayName,
        accent: accent,
        footer: TapAnywherePrompt(accent: accent),
      ),
    );
  }
}

Color _rarityColor(CardRarity r) => switch (r) {
      // Warm across the board — specs/shared/art-direction.md wants reward
      // signals warm rather than loud, so rarity reads as a shift in metal
      // rather than a jump in volume.
      CardRarity.common => const Color(0xFF8FA96B),
      CardRarity.uncommon => const Color(0xFF4E9AC4),
      CardRarity.rare => AppColors.treasureGold,
    };
