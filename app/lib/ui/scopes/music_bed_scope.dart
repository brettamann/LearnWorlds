// MusicBedScope — "this screen is inside the Sanctuary, keep the music going."
//
// SfxEngine owns the bed and screens claim and release it (see the ownership
// note in sfx_engine.dart). Doing that by hand costs a stateful widget, an
// eagerly-read engine reference for dispose, and two lifecycle overrides —
// which is fine inside a runner that already has all three, and is exactly why
// the maps and the album never got music at all. The child could stand on the
// Sanctuary map for two minutes in silence because adding six lines to a
// StatelessWidget meant converting it first.
//
// Wrapping is one line, so there is no longer a reason for a screen inside the
// Sanctuary to be silent.
//
// The runners, the lesson and the gift screen still claim by hand. They work,
// and they were written before this existed; migrating them is a tidy-up, not
// a fix.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sfx_catalog.dart';
import '../../platform/sfx_engine.dart';

class MusicBedScope extends ConsumerStatefulWidget {
  const MusicBedScope({
    super.key,
    this.bed = kDefaultMusicBed,
    required this.child,
  });

  /// Key into [kMusicBeds]. Unknown keys fall back rather than going silent.
  final String bed;

  final Widget child;

  @override
  ConsumerState<MusicBedScope> createState() => _MusicBedScopeState();
}

class _MusicBedScopeState extends ConsumerState<MusicBedScope> {
  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfx;

  @override
  void initState() {
    super.initState();
    _sfx = ref.read(sfxEngineProvider);
    // Claimed in initState rather than a post-frame callback so the claim
    // lands in the same frame the previous screen's release was scheduled in.
    // The grace window is long enough either way; this just makes the handoff
    // not depend on it.
    unawaited(_sfx!.startMusicBed(widget.bed));
  }

  @override
  void didUpdateWidget(MusicBedScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bed != widget.bed) {
      // switch, not start: this is one claim changing its mind. A second
      // startMusicBed would leave the engine's claim count permanently high
      // and the bed could never stop.
      unawaited(ref.read(sfxEngineProvider).switchMusicBed(widget.bed));
    }
  }

  @override
  void dispose() {
    // Release, not stop: whatever screen comes next gets the grace window to
    // claim the same bed, and if it does the child hears no seam at all.
    _sfx?.releaseMusicBed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
