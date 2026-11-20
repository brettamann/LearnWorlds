// CollectionScreen — the Sanctuary Creature Cards album.
//
// The empty slots are the point. A gallery of what she has is a receipt; a
// gallery with six silhouettes in it is a reason to play another round. Every
// card in the set is always on screen, found or not, which is the same
// deliberate exception to specs/shared/ui-affordances.md's "missing buttons,
// not disabled buttons" rule that the Buddy shop takes: in a collection, the
// gap is the content.
//
// No text a pre-reader has to decode: an unfound card is a black silhouette of
// the exact sprite she'll see when she finds it, so the shape itself is the
// clue. Names sit under found cards only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/creature_card_catalog.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../navigation/routes.dart';
import '../../providers/collection_provider.dart';
import '../../theme/app_colors.dart';
import '../widgets/music_bed_scope.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found = ref.watch(cardCollectionProvider);
    final total = kCreatureCards.length;

    // Reached from the Sanctuary map and returning straight to it, so it is
    // inside the visit rather than outside it.
    return MusicBedScope(
      child: Scaffold(
        backgroundColor: const Color(0xFF2E2A24),
        appBar: AppBar(
          title: const Text('Creature Cards'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to the Sanctuary',
            onPressed: () => context.go(Routes.sanctuary),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  '${found.length} / $total',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Wrap(
                spacing: 18,
                runSpacing: 18,
                alignment: WrapAlignment.center,
                children: [
                  for (final card in kCreatureCards)
                    _AlbumSlot(
                      key: ValueKey('card-${card.id}'),
                      card: card,
                      found: found.contains(card.id),
                      onTap: () => _speak(ref, card, found.contains(card.id)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Say the creature's name, or say it hasn't been found yet.
///
/// `speak` rather than `speakWithoutCaption`: the name is exactly what she
/// came here for, so the caption bar showing it is a feature.
void _speak(WidgetRef ref, CreatureCard card, bool found) {
  ref.narration.say(
    found ? cardFoundLine(card) : kCardNotFoundLine,
    cueId: 'collection:card-${card.id}',
    speaker: kKeeperSpeaker,
  );
}

class _AlbumSlot extends StatelessWidget {
  const _AlbumSlot({
    super.key,
    required this.card,
    required this.found,
    required this.onTap,
  });

  final CreatureCard card;
  final bool found;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sprite = Image.asset(card.spriteAsset, fit: BoxFit.contain);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 180,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: found ? AppColors.parchment : const Color(0xFF3A352D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: found ? AppColors.treasureGold : AppColors.emptySlot,
            width: found ? 4 : 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 130,
              child: found
                  ? sprite
                  // The same sprite, blacked out. A generic "?" would tell her
                  // nothing; a silhouette tells her what she is looking for.
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF241F1A),
                        BlendMode.srcIn,
                      ),
                      child: sprite,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              found ? card.displayName : '?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: found ? 20 : 26,
                fontWeight: FontWeight.w800,
                color: found ? AppColors.parchmentInk : const Color(0xFF6A6154),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
