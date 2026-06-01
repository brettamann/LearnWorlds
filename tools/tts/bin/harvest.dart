// CLI entry point for the TTS harvester.
//
// Usage:
//   dart run bin/harvest.dart [--repo-root PATH] [--out PATH] [--locale CODE] [-v]
//
// Defaults assume the harvester is invoked from tools/tts/ and the repo root
// is two levels up.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:critmath_tts/harvester.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'repo-root',
      defaultsTo: '../..',
      help: 'Path to the CritMath repo root (default: ../..).',
    )
    ..addOption(
      'out',
      defaultsTo: 'harvest-manifest.json',
      help: 'Output manifest file (default: harvest-manifest.json).',
    )
    ..addOption(
      'locale',
      defaultsTo: 'en-US',
      help: 'Locale to harvest for (default: en-US).',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Print each walked file.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage.',
    );

  late final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stderr.writeln(parser.usage);
    exit(2);
  }

  if (results['help'] as bool) {
    stdout.writeln('CritMath TTS harvester\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final repoRoot = results['repo-root'] as String;
  final outPath = results['out'] as String;
  final locale = results['locale'] as String;
  final verbose = results['verbose'] as bool;

  final harvester = Harvester(
    repoRoot: repoRoot,
    locale: locale,
    verbose: verbose,
  );

  final result = await harvester.run();

  // Write manifest.
  final manifestJson = const JsonEncoder.withIndent('  ').convert(result.toJson());
  await File(outPath).writeAsString(manifestJson);

  // Summary to stdout.
  stdout.writeln('');
  stdout.writeln('Harvest complete.');
  stdout.writeln('  Locale:       $locale');
  stdout.writeln('  Total cues:   ${result.totalCues}');
  stdout.writeln('  Total chars:  ${result.totalChars}');
  stdout.writeln('  With slots:   ${result.cuesWithSlots} (need slot-fill expansion)');
  stdout.writeln('');

  stdout.writeln('By voice profile:');
  result.byVoice.forEach((voice, count) {
    final chars = result.charsByVoice[voice] ?? 0;
    stdout.writeln('  $voice: $count cues, $chars chars');
  });
  stdout.writeln('');

  stdout.writeln('By source category:');
  result.bySource.forEach((source, count) {
    stdout.writeln('  $source: $count cues');
  });
  stdout.writeln('');

  stdout.writeln('Per-lesson cue counts (top 10):');
  final lessonEntries = result.byLesson.entries.take(10);
  for (final entry in lessonEntries) {
    stdout.writeln('  ${entry.key}: ${entry.value}');
  }
  if (result.byLesson.length > 10) {
    stdout.writeln('  ... and ${result.byLesson.length - 10} more lessons.');
  }
  stdout.writeln('');

  if (result.duplicateCueIds.isNotEmpty) {
    stdout.writeln('⚠ Duplicate cue IDs detected (manifest will be unusable until fixed):');
    result.duplicateCueIds.forEach((cueId, count) {
      stdout.writeln('  $cueId × $count');
    });
    stdout.writeln('');
  }

  if (result.warnings.isNotEmpty) {
    stdout.writeln('Warnings (${result.warnings.length}):');
    for (final w in result.warnings) {
      stdout.writeln('  - $w');
    }
    stdout.writeln('');
  }

  if (result.errors.isNotEmpty) {
    stderr.writeln('Errors (${result.errors.length}):');
    for (final e in result.errors) {
      stderr.writeln('  - $e');
    }
    stderr.writeln('');
  }

  stdout.writeln('Manifest written to: $outPath');

  exit(result.errors.isEmpty ? 0 : 1);
}
