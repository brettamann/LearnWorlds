// Where two catalogs name the same picture, they have to agree.
//
// `wheres_buddy_words.dart` states the rule this enforces: "a landmark whose
// name argues with its picture is worse for a pre-reader than one with no
// picture at all - she has the picture and the spoken word and nothing else
// to go on." Whether a name argues with a *picture* is not something a test
// can see. Whether two names for the same picture argue with each other is.
//
// That is not a weaker check than it sounds, because it is how both of the
// real ones were found. The fountain was "the unicorn fountain" over a
// fountain with no unicorn on it - the decor tray, drawing the same file,
// called it "Star Fountain". The toadstools were "the giant mushroom",
// singular and giant, over three ordinary ones - and the decor tray, again
// drawing the same file, called them "Toadstools". A picture with one name is
// only as right as whoever typed it; a picture with two names has already
// disagreed with itself.
//
// The rule is a shared noun, not equality, because the acceptable cases are
// all one name containing the other's head: "the pond" and "Lily Pond", or
// "gryphon" and "Baby Gryphon" - a keepsake card is allowed a fancier name
// for the same creature. "Toadstools" and "giant mushroom" share nothing,
// which is exactly the shape of the bug.

import 'package:critmath/data/build_a_habitat_blueprints.dart';
import 'package:critmath/data/creature_card_catalog.dart';
import 'package:critmath/data/flat_or_solid_shapes.dart';
import 'package:critmath/data/parade_species.dart';
import 'package:critmath/data/sanctuary_decor_catalog.dart';
import 'package:critmath/data/wheres_buddy_landmarks.dart';
import 'package:critmath/data/wheres_buddy_words.dart';
import 'package:flutter_test/flutter_test.dart';

/// One catalog's name for one sprite.
typedef _Naming = ({String name, String catalog});

/// Lowercased words, with the articles and the plural 's' taken off, so that
/// "the toadstools" and "Toadstool" would match and "the pond" and "Lily
/// Pond" do.
List<String> _words(String name) => name
    .toLowerCase()
    .split(RegExp(r'[^a-z]+'))
    .where((w) => w.isNotEmpty && w != 'the' && w != 'a')
    .map(_singular)
    .toList();

/// Crude de-pluralisation. It only has to make "toadstools" and "toadstool"
/// the same word, not survive "geese".
String _singular(String w) {
  if (w.endsWith('es') && w.length > 4) return w.substring(0, w.length - 2);
  if (w.endsWith('s') && w.length > 3) return w.substring(0, w.length - 1);
  return w;
}

/// The last word - the thing being named, as opposed to what kind of it.
String _head(String name) {
  final w = _words(name);
  return w.isEmpty ? name.toLowerCase() : w.last;
}

Map<String, List<_Naming>> _namings() {
  final out = <String, List<_Naming>>{};
  void add(String asset, String name, String catalog) {
    out.putIfAbsent(asset, () => <_Naming>[]).add((
      name: name,
      catalog: catalog,
    ));
  }

  for (final d in kSanctuaryDecor) {
    add(d.spriteAsset, d.displayName, 'sanctuary_decor_catalog');
  }
  for (final lm in kWheresBuddyLandmarks) {
    add(
      lm.spriteAsset,
      kWheresBuddyLandmarkNames[lm.id] ?? lm.id,
      'wheres_buddy_words',
    );
  }
  for (final s in kParadeSpecies) {
    add(s.spriteAsset, s.singular, 'parade_species');
  }
  for (final c in kCreatureCards) {
    add(c.spriteAsset, c.displayName, 'creature_card_catalog');
  }
  for (final s in <FlatOrSolidShape>[...kFlatShapes, ...kSolidShapes]) {
    add(s.assetPath, s.displayName, 'flat_or_solid_shapes');
  }
  for (final bp in kHabitatBlueprints) {
    for (final p in bp.roof) {
      add(p.placedAsset, p.kind, 'build_a_habitat_blueprints');
    }
  }
  return out;
}

void main() {
  group('a picture named twice', () {
    test('is named the same thing both times', () {
      final offenders = <String>[];
      for (final entry in _namings().entries) {
        final heads = entry.value.map((n) => _head(n.name)).toSet();
        if (heads.length < 2) continue;
        offenders.add(
          '${entry.key.split('/').last}: '
          '${entry.value.map((n) => '"${n.name}" (${n.catalog})').join(' vs ')}',
        );
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'one picture, two names that share no noun. She has the '
            'picture and the spoken word and nothing else to go on, so the '
            'two have to be talking about the same thing.',
      );
    });

    test('and there is more than one picture to check', () {
      // The check above passes vacuously if the catalogs stop overlapping -
      // a rename that moves a landmark onto its own sprite would silently
      // retire the guard rather than trip it.
      final shared = _namings().values.where((v) => v.length > 1).length;
      expect(shared, greaterThanOrEqualTo(12));
    });
  });
}
