// Where's Buddy's miss path, on the round shell: the cue again, the cue with a
// warm line, then the spec's demonstration - and the round is graded a miss.
//
// The second miss used to glue a warm line onto the prompt at runtime
// ("That one is different. Keep looking. Find Buddy - ..."), a sentence no
// catalog contained, so it could only ever be spoken in the synth voice. It is
// two recorded lines now; this checks everything said here is scripted.

import 'package:critmath/activities/sub_mode_ids.dart';
import 'package:critmath/activities/wheres_buddy/wheres_buddy_runner.dart';
import 'package:critmath/data/narration_script.dart';
import 'package:critmath/data/warm_lines.dart';
import 'package:critmath/data/wheres_buddy_words.dart';
import 'package:critmath/engines/mastery/round_outcome.dart';
import 'package:critmath/engines/narration/narration_line.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/common/answer_feedback.dart';
import 'package:critmath/ui/round/keeper_aside.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('three misses: cue, warm cue, demonstration, graded a miss', (
    tester,
  ) async {
    useViewSize(tester);
    final container = testContainer();
    addTearDown(container.dispose);
    final heard = <String>[];
    container.listen<NarrationLine?>(narrationPlayerProvider, (_, l) {
      if (l != null) heard.add(l.text);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: WheresBuddyRunner(
              subMode: WheresBuddyModes.findMode,
              skipIntro: true,
              onSequenceComplete: () {},
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester, count: 5);

    final round = wheresBuddyRoundsFor(WheresBuddyModes.findMode).first;
    final prompt = wheresBuddyRoundPrompt(round, placing: false);
    // Far corner of the clearing: nowhere near the first round's answer.
    final box = tester.getRect(find.byType(AnswerFeedback));
    final miss = Offset(box.right - 20, box.top + 20);
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(miss);
      // Long enough for a queued line to be reached.
      await pumpFrames(tester, count: 80);
    }

    expect(heard, contains(warmMissLine(1)));
    expect(heard.where((l) => l == prompt).length, greaterThanOrEqualTo(3));
    expect(heard, contains(wheresBuddyRoundRestate(round)));

    // The demonstration resolves the round itself, as a miss.
    await pumpFrames(tester, count: 20);
    expect(container.read(walletProvider), coinsFor(RoundResult.failure));
    expect(find.byType(KeeperAside), findsOneWidget);

    final scripted = <String>{
      for (final line in narrationScriptTexts()) narrationClipKey(line),
    };
    expect(
      heard.where((l) => !scripted.contains(narrationClipKey(l))),
      isEmpty,
    );
    await unmountAndDrain(tester);
  });
}
