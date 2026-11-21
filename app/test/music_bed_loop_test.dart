// The music bed has to loop without a hole in it.
//
// Two kinds of bed live in kMusicBeds now. The Sanctuary theme is a real
// four-minute MP3 and the challenge bed is still a generated WAV loop, so the
// checks below split: anything this repo synthesises gets measured sample by
// sample, and the recording gets the checks you can make without a decoder.
//
// It didn't. Both beds ended with exactly 1.2 seconds of digital silence, so
// every seventeen seconds the music stopped, and a five-year-old heard that
// gap over and over for the length of every session — long enough to notice,
// short enough that nobody looking at the code would think to check a WAV.
//
// The cause was in the generator, and it is a good bug: `build_music` blends
// the tail of the loop into the head so the seam is inaudible, then zeroes the
// tail — and never shortened the buffer. Correct crossfade, right up to the
// point of dropping the frames it had just folded away.
//
// So this reads the shipped audio rather than trusting the tool. A generator
// fix that nobody re-runs leaves the broken file on disk, which is exactly the
// state this repo was in.

import 'dart:io';
import 'dart:typed_data';

import 'package:critmath/data/sfx_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Enough of a WAV reader to answer one question.
class _Wav {
  _Wav({
    required this.channels,
    required this.sampleRate,
    required this.samples,
  });

  final int channels;
  final int sampleRate;

  /// Interleaved 16-bit PCM.
  final Int16List samples;

  int get frames => samples.length ~/ channels;
  double get seconds => frames / sampleRate;

  /// Loudest sample in the file, as an absolute value.
  int get peak {
    var p = 0;
    for (final s in samples) {
      final a = s.abs();
      if (a > p) p = a;
    }
    return p;
  }

  /// Amplitude of frame [i], across channels.
  int frameAmp(int i) {
    var a = 0;
    for (var c = 0; c < channels; c++) {
      final v = samples[i * channels + c].abs();
      if (v > a) a = v;
    }
    return a;
  }

  static _Wav read(File file) {
    final bytes = file.readAsBytesSync();
    final data = ByteData.sublistView(bytes);
    var channels = 1;
    var sampleRate = 22050;
    var bits = 16;

    // Walk the RIFF chunks rather than assuming a 44-byte header: encoders
    // insert LIST/fact chunks and a fixed offset would silently read metadata
    // as audio.
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = data.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (id == 'fmt ') {
        channels = data.getUint16(body + 2, Endian.little);
        sampleRate = data.getUint32(body + 4, Endian.little);
        bits = data.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        if (bits != 16) {
          throw StateError('${file.path} is $bits-bit; expected 16');
        }
        final end = (body + size).clamp(0, bytes.length);
        return _Wav(
          channels: channels,
          sampleRate: sampleRate,
          samples: Int16List.sublistView(
            Uint8List.sublistView(bytes, body, end),
          ),
        );
      }
      // Chunks are word-aligned.
      offset = body + size + (size.isOdd ? 1 : 0);
    }
    throw StateError('no data chunk in ${file.path}');
  }
}

void main() {
  final beds = kMusicBeds.values.toSet();
  final wavBeds = beds.where((a) => a.endsWith('.wav'));
  final mp3Beds = beds.where((a) => a.endsWith('.mp3'));

  test('every bed named in the catalog is actually on disk', () {
    expect(beds, isNotEmpty);
    for (final asset in beds) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('the Sanctuary and the challenge mode are different pieces', () {
    // The two names for the Sanctuary bed resolve to one file on purpose —
    // that is what keeps a lesson asking for the picnic bed from restarting
    // the music mid-visit. The challenge bed must NOT collapse into it, or
    // opting into a challenge stops sounding like anything.
    expect(kMusicBeds['sanctuary-low'], kMusicBeds['sanctuary-picnic']);
    expect(
      kMusicBeds['sanctuary-challenge-rising-energy'],
      isNot(kMusicBeds['sanctuary-low']),
    );
  });

  for (final asset in mp3Beds) {
    test('$asset carries no tag payload', () {
      // A 366 KB ID3v2 block of cover art was riding along on the delivered
      // file. Nothing decodes it and every byte ships to the iPad, so the
      // first MPEG frame has to start at byte zero.
      final bytes = File(asset).openSync().readSync(4);
      expect(
        String.fromCharCodes(bytes.sublist(0, 3)),
        isNot('ID3'),
        reason: '$asset still has an ID3v2 tag on the front — strip it',
      );
      expect(bytes[0], 0xFF, reason: 'no MPEG frame sync at the start');
      expect(bytes[1] & 0xE0, 0xE0, reason: 'no MPEG frame sync at the start');
    });

    test('$asset is long enough that the seam is rare', () {
      // MP3 has no gapless metadata here, so looping costs a few tens of
      // milliseconds of decoder padding. That is fine for a four-minute piece
      // most sessions never reach the end of, and would not be fine for a
      // twenty-second loop — which is the swap this guards against.
      final seconds = File(asset).lengthSync() * 8 / 320000;
      expect(
        seconds,
        greaterThan(120),
        reason:
            '$asset is only ${seconds.toStringAsFixed(0)}s at 320 kbps. A '
            'short MP3 bed needs the gapless treatment the WAVs get; render '
            'it as a WAV loop instead.',
      );
    });
  }

  for (final asset in wavBeds) {
    test('$asset loops without a gap', () {
      final wav = _Wav.read(File(asset));
      final quiet = wav.peak * 0.01;

      var trailing = 0;
      while (trailing < wav.frames &&
          wav.frameAmp(wav.frames - 1 - trailing) < quiet) {
        trailing++;
      }
      final trailingSeconds = trailing / wav.sampleRate;

      expect(
        trailingSeconds,
        lessThan(0.05),
        reason:
            'the bed ends in ${trailingSeconds.toStringAsFixed(3)}s of '
            'silence, which is a hole in the music every '
            '${wav.seconds.toStringAsFixed(1)}s. Re-run '
            'tools/audio/generate_placeholder_sfx.py — fold_tail_into_head '
            'must drop the frames it folds, not just zero them.',
      );
    });

    test('$asset does not click at the seam', () {
      // The tail is folded into the head, so the last frame and the first
      // should be at a similar level. A big step between them is an audible
      // tick once a loop — quieter than a gap and just as wrong.
      final wav = _Wav.read(File(asset));
      final step = (wav.frameAmp(0) - wav.frameAmp(wav.frames - 1)).abs();
      expect(
        step / wav.peak,
        lessThan(0.25),
        reason: 'a $step jump against a peak of ${wav.peak} at the loop point',
      );
    });
  }
}
