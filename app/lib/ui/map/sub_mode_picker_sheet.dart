// SubModePickerSheet — the modal bottom sheet shown when the kid taps a
// Sanctuary node with more than one sub-mode available. Each option is a
// square card: the sub-mode's symbol, a short label, and a hint chip ("New!"
// for the next un-cleared sub-mode, "Replay" for one she has already done,
// "Challenge!" for the optional final check).
//
// This is the one screen in the game that asks her to *choose*, and it is the
// only one where the read-aloud model the rest of the app uses does not fit.
// Everywhere else, ReadAloudGate speaks a control's name on the tap that acts,
// which is right when the control does what it says. Here the whole point is
// knowing before you commit, and speak-on-tap tells her what she picked after
// she has picked it. The gate has a second affordance for that — hovering
// narrates without acting — and it is no use at all to the child this is
// built for: she plays on a touchscreen, where nothing hovers.
//
// So the sheet reads itself out. It asks the question, then names each option
// in turn with that card lit, the way an adult reads a menu to a child who
// cannot read it. Three things make that safe rather than annoying:
//
//   - It is not a gate. Every card is live from the first frame; she can tap
//     straight through it and usually will, from the second visit onwards.
//   - Any touch anywhere on the sheet stops it. Deciding is the signal that
//     she is done listening.
//   - The lit card is the same amber the game already uses to mean "this
//     one", so the highlight is a word she has been taught elsewhere.
//
// The read-through is the slowest thing in the app on purpose — six options
// is about thirteen seconds if she lets it run to the end. Worth watching on
// a real device: if she interrupts it every single time, that is the feature
// working, but if she sits through it looking bored, shorten it before
// cutting it.
//
// Labels are drawn from data/sub_mode_picker_data.dart, which the recording
// script enumerates. A label typed inline here would speak in the browser's
// synth voice instead — see the note in data/map_labels.dart for what that
// sounds like next to rendered narration.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sub_mode_picker_data.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_player.dart';
import '../../models/activity.dart';
import '../../providers/read_aloud_settings_provider.dart';
import '../common/read_aloud_gate.dart';
import 'sub_mode_symbol.dart';

/// One sub-mode + its derived picker state.
class SubModePickerEntry {
  const SubModePickerEntry({
    required this.subMode,
    required this.isCompleted,
    required this.isNext,
    this.isChallenge = false,
  });

  final SubMode subMode;

  /// Already cleared at least once — appears with a "Replay" chip.
  final bool isCompleted;

  /// First un-completed sub-mode — appears with a "New!" chip.
  final bool isNext;

  /// Optional final-check entry, unlocked after every regular sub-mode is
  /// done. Shown with a "Challenge!" chip; the kid can skip it forever and
  /// the activity still counts as fully complete.
  final bool isChallenge;
}

/// What a card is called, and what it says when the sheet names it.
///
/// One function rather than one lookup in the card and another in the
/// read-through: the voice and the caption saying different things is the
/// exact confusion this screen exists to remove.
String pickerLabelFor({required String activityId, required String subModeId}) {
  final option = pickerOptionFor(activityId: activityId, subModeId: subModeId);
  if (option != null) return option.label;
  // A backstop, not a design. `sub_mode_picker_test.dart` asserts every
  // sub-mode the picker can reach has an entry, because a card with a grey
  // question mark on it says nothing to a pre-reader, and a raw sub-mode id
  // spoken aloud says less — it also has no recorded clip, so it would arrive
  // in the browser's voice.
  final words = subModeId.replaceAll('-', ' ');
  if (words.isEmpty) return words;
  return words[0].toUpperCase() + words.substring(1);
}

/// Shows the picker. Resolves to the chosen `SubMode.id`, or null if the
/// kid dismisses without picking.
Future<String?> showSubModePicker(
  BuildContext context, {
  required String activityId,
  required String activityDisplayName,
  required List<SubModePickerEntry> entries,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => SubModePickerSheet(
      activityId: activityId,
      activityDisplayName: activityDisplayName,
      entries: entries,
    ),
  );
}

/// The sheet body. Public so a test can mount it without driving a route.
class SubModePickerSheet extends ConsumerStatefulWidget {
  const SubModePickerSheet({
    super.key,
    required this.activityId,
    required this.activityDisplayName,
    required this.entries,
  });

  final String activityId;
  final String activityDisplayName;
  final List<SubModePickerEntry> entries;

  @override
  ConsumerState<SubModePickerSheet> createState() => _SubModePickerSheetState();
}

class _SubModePickerSheetState extends ConsumerState<SubModePickerSheet> {
  /// Breath between one name ending and the next beginning. Without it the
  /// options run together into one long sentence.
  static const Duration _gap = Duration(milliseconds: 260);

  /// Which card is being named right now, or null when nothing is.
  int? _spotlight;

  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The sheet arriving. Silent before this — `Sfx.whoosh` existed for it
    // and had no call site anywhere in the app.
    ref.read(feedbackEngineProvider).whoosh();
    // After the first frame, so the sheet is on screen as the question starts
    // rather than a beat behind it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startReadThrough();
    });
  }

  @override
  void dispose() {
    // The timer outlives the widget otherwise, and `flutter_test` fails any
    // test torn down with one pending — which is how this class of bug is
    // usually found here.
    _tick?.cancel();
    super.dispose();
  }

  /// Ask, then name each option in turn.
  ///
  /// Skipped entirely when read-aloud is off. A travelling highlight with no
  /// voice under it is not a quieter version of this feature — it is a light
  /// moving across the screen for no stated reason.
  void _startReadThrough() {
    if (!ref.read(readAloudGateEnabledProvider)) return;
    // `speak`, not `enqueue`: the line that would be in flight is the map
    // node's own name, spoken by the ReadAloudGate on the tap that opened this
    // sheet. Waiting that out would put a second of silence in front of the
    // question, and the node's name is the one thing here she already knows —
    // she just touched it.
    _say(kSubModePickerQuestion, 'picker:question');
    _scheduleStep(0, narrationSpokenEstimate(kSubModePickerQuestion) + _gap);
  }

  /// A self-rescheduling chain rather than `NarrationPlayer.enqueue`, for one
  /// concrete reason: the queue holds two lines and silently drops the rest,
  /// and this screen has up to six things to say. The queue is sized for a
  /// beat with something to add; a menu being read out is not that.
  ///
  /// Paced on `narrationSpokenEstimate`, which is generous — a rendered clip
  /// usually finishes early and leaves the card lit in silence for a moment
  /// before the next. That is the harmless direction to be wrong in: the
  /// alternative is a name starting over the top of the one before it.
  void _scheduleStep(int index, Duration after) {
    _tick = Timer(after, () {
      if (!mounted) return;
      if (index >= widget.entries.length) {
        setState(() => _spotlight = null);
        return;
      }
      final entry = widget.entries[index];
      final label = pickerLabelFor(
        activityId: widget.activityId,
        subModeId: entry.subMode.id,
      );
      setState(() => _spotlight = index);
      _say(label, 'picker:${widget.activityId}:${entry.subMode.id}');
      _scheduleStep(index + 1, narrationSpokenEstimate(label) + _gap);
    });
  }

  /// She has touched something, so stop reading at her.
  ///
  /// Only the chain is cancelled, never the player: this fires on pointer-down
  /// and the ReadAloudGate under her finger is about to speak the name of the
  /// card she chose. Clearing here would cut that off before it started.
  void _stopReadThrough() {
    if (_tick == null && _spotlight == null) return;
    _tick?.cancel();
    _tick = null;
    if (_spotlight != null) setState(() => _spotlight = null);
  }

  void _say(String text, String cueId) {
    ref.narration.say(text, cueId: cueId, caption: false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Translucent, not deferToChild: the touch that means "stop reading at
      // me, I have decided" is just as likely to land on the padding beside a
      // card as on the card. Translucent sees it either way and still lets it
      // through to whatever is underneath.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _stopReadThrough(),
      child: SafeArea(
        // Bounded, and scrollable inside those bounds. The sheet sizes itself
        // to its content, and its content is a Wrap whose row count depends
        // on how many sub-modes the node has and how wide the screen is - six
        // cards over three rows on a narrow one. Unbounded, that overflows,
        // and a Flutter overflow is a striped bar and a card she can see and
        // cannot reach: the failure this project treats as worse than a wrong
        // answer, because it is indistinguishable from the app being broken.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    kSubModePickerQuestion,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.activityDisplayName,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (var i = 0; i < widget.entries.length; i++)
                        _OptionCard(
                          activityId: widget.activityId,
                          entry: widget.entries[i],
                          isSpotlit: _spotlight == i,
                          onTap: () => Navigator.of(
                            context,
                          ).pop(widget.entries[i].subMode.id),
                        ),
                    ],
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.activityId,
    required this.entry,
    required this.isSpotlit,
    required this.onTap,
  });

  final String activityId;
  final SubModePickerEntry entry;

  /// True while the sheet is saying this card's name.
  final bool isSpotlit;

  final VoidCallback onTap;

  // Sized by looking at it. At 96 the two-element Where's Buddy scenes did
  // not read - a Buddy at half the box is a 34-pixel Buddy once BoxFit and
  // his transparent margin come out - and the three habitat frames were three
  // sixty-pixel polygons to tell apart. Four of these still fit a row on a
  // tablet, which is the widest picker the game has.
  static const double _cardWidth = 176;
  static const double _spriteSize = 118;

  @override
  Widget build(BuildContext context) {
    final option = pickerOptionFor(
      activityId: activityId,
      subModeId: entry.subMode.id,
    );
    final label = pickerLabelFor(
      activityId: activityId,
      subModeId: entry.subMode.id,
    );
    final chipLabel = entry.isChallenge
        ? 'Challenge!'
        : entry.isNext
        ? 'New!'
        : entry.isCompleted
        ? 'Replay'
        : null;
    final chipColor = entry.isChallenge
        ? Colors.deepPurple.shade100
        : entry.isNext
        ? Colors.green.shade100
        : Colors.amber.shade100;
    return SizedBox(
      width: _cardWidth,
      child: ReadAloudGate(
        label: label,
        cueId: 'picker:$activityId:${entry.subMode.id}',
        onTap: onTap,
        // Amber, and the same amber as the hint ladder's highlight and the
        // glowing landmark in Where's Buddy. The game has already taught her
        // that amber means "this one"; spending a second colour on the same
        // idea here would be teaching it twice.
        //
        // A ring, not only a glow. The first version was the glow alone,
        // which is what the playfield uses - and there it works, because what
        // is behind it is a meadow. This sheet is near-white, and an amber
        // glow on a white card on a white sheet rendered as a faint grey rim.
        child: AnimatedScale(
          scale: isSpotlit ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSpotlit
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.amber.shade400.withValues(alpha: 0.75),
                        blurRadius: 26,
                        spreadRadius: 2,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Material(
              color: Colors.white,
              elevation: 2,
              // `shape` carries the radius; Material asserts if both are set.
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSpotlit ? Colors.amber.shade600 : Colors.transparent,
                  width: 4,
                ),
              ),
              child: InkWell(
                key: ValueKey('sub-mode-pick-${entry.subMode.id}'),
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: _spriteSize,
                        height: _spriteSize,
                        child: option == null
                            ? const Center(
                                child: Icon(
                                  Icons.help_outline,
                                  size: 56,
                                  color: Colors.black38,
                                ),
                              )
                            : SubModeSymbol(
                                symbol: option.symbol,
                                size: _spriteSize,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      if (chipLabel != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chipLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
