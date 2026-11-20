#!/usr/bin/env python3
"""Generate CritMath's placeholder SFX set as 16-bit mono WAV files.

Why this exists
---------------
The game shipped completely silent (no audio asset of any kind existed in the
repo). Sound is the single biggest engagement gap for a pre-reading player, so
we needed clips *now* rather than after an audio-asset commission.

Everything here is synthesized from sine partials and filtered noise using only
the Python standard library, so the whole set is reproducible with:

    python tools/audio/generate_placeholder_sfx.py

These are deliberately *placeholders*: warm and readable, but plain. When real
audio is commissioned, drop the replacements at the same paths and delete this
script's entry from the asset pipeline. The one part worth keeping in spirit is
the counting ladder (see `COUNT_LADDER_HZ`) — those exact pitches are a design
decision, not an arbitrary sound choice.

Format note: WAV, not MP3/M4A. There is no encoder on the dev machine, WAV
decodes everywhere including Flutter web, and these clips are small enough that
compression doesn't matter. specs/shared/asset-paths.md mandates .m4a for
narration; this is an SFX exception and is recorded in that spec's changelog.
"""

from __future__ import annotations

import array
import math
import os
import random
import struct
import wave

SR = 44100
OUT_ROOT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "app",
    "assets",
    "audio",
)

# --- The counting ladder -----------------------------------------------------
# One note per counted object. A C-major scale, NOT chromatic semitones: a
# chromatic run past ~5 notes reads as atonal and anxious to a five-year-old,
# and specs/shared/art-direction.md requires reward signals be "warm, not loud."
# Twelve notes covers counting to 12; runners clamp past the end.
COUNT_LADDER_HZ = [
    523.25,  # C5   1
    587.33,  # D5   2
    659.25,  # E5   3
    698.46,  # F5   4
    783.99,  # G5   5
    880.00,  # A5   6
    987.77,  # B5   7
    1046.50,  # C6   8
    1174.66,  # D6   9
    1318.51,  # E6  10
    1396.91,  # F6  11
    1567.98,  # G6  12
]


# --- Synthesis primitives ----------------------------------------------------


def _env(n: int, i: int, attack: float, decay: float) -> float:
    """Percussive envelope: fast linear attack, exponential decay."""
    a = max(1, int(SR * attack))
    if i < a:
        return i / a
    t = (i - a) / SR
    return math.exp(-t / decay)


def tone(
    freq: float,
    dur: float,
    decay: float = 0.25,
    attack: float = 0.004,
    partials: tuple[tuple[float, float], ...] = ((1.0, 1.0), (2.0, 0.22), (4.0, 0.07)),
    detune: float = 0.0,
) -> array.array:
    """A struck-mallet style note: fundamental plus a couple of quiet partials."""
    n = int(SR * dur)
    buf = array.array("d", [0.0] * n)
    for mult, amp in partials:
        w = 2 * math.pi * freq * mult
        for i in range(n):
            buf[i] += amp * math.sin(w * i / SR)
    if detune:
        w = 2 * math.pi * freq * (1.0 + detune)
        for i in range(n):
            buf[i] += 0.35 * math.sin(w * i / SR)
    for i in range(n):
        buf[i] *= _env(n, i, attack, decay)
    return buf


def sweep(
    f0: float, f1: float, dur: float, decay: float = 0.3, attack: float = 0.01
) -> array.array:
    """Glide from f0 to f1 — used for chirps and blips."""
    n = int(SR * dur)
    buf = array.array("d", [0.0] * n)
    phase = 0.0
    for i in range(n):
        t = i / n
        f = f0 * (f1 / f0) ** t
        phase += 2 * math.pi * f / SR
        buf[i] = math.sin(phase) * _env(n, i, attack, decay)
    return buf


def noise(dur: float, decay: float = 0.15, lowpass: float = 0.25, seed: int = 7):
    """Filtered noise. `lowpass` is a one-pole coefficient (lower = duller)."""
    rng = random.Random(seed)
    n = int(SR * dur)
    buf = array.array("d", [0.0] * n)
    prev = 0.0
    for i in range(n):
        white = rng.uniform(-1.0, 1.0)
        prev += lowpass * (white - prev)
        buf[i] = prev * _env(n, i, 0.001, decay)
    return buf


def mix(*layers: array.array) -> array.array:
    n = max(len(x) for x in layers)
    out = array.array("d", [0.0] * n)
    for layer in layers:
        for i, v in enumerate(layer):
            out[i] += v
    return out


def delay(buf: array.array, seconds: float) -> array.array:
    pad = array.array("d", [0.0] * int(SR * seconds))
    pad.extend(buf)
    return pad


def gain(buf: array.array, g: float) -> array.array:
    return array.array("d", [v * g for v in buf])


def normalize(buf: array.array, peak: float = 0.82) -> array.array:
    hi = max((abs(v) for v in buf), default=0.0)
    if hi < 1e-9:
        return buf
    k = peak / hi
    return array.array("d", [v * k for v in buf])


def fade_tail(buf: array.array, seconds: float = 0.02) -> array.array:
    """Kill the click a hard cut leaves at the end of a clip."""
    n = int(SR * seconds)
    total = len(buf)
    for i in range(min(n, total)):
        buf[total - 1 - i] *= i / n
    return buf


def write(
    path: str,
    buf: array.array,
    sample_rate: int = SR,
    fade: bool = True,
) -> None:
    """Write one clip. Pass fade=False for anything that loops.

    fade_tail exists to kill the click a hard cut leaves at the end of a
    one-shot. On a loop it does the opposite: it ramps the last 20 ms down to
    silence, which lands exactly on the loop point and undoes the crossfade
    build_music just spent 1.2 seconds of audio constructing. The music beds
    used to be written through it and then trimmed back by hand afterwards,
    which meant the shipped file was correct and the tool's own output was not
    -- so the next person to re-run this would quietly ship the click.
    """
    full = os.path.join(OUT_ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    buf = normalize(buf)
    if fade:
        buf = fade_tail(buf)
    frames = bytearray()
    for v in buf:
        s = max(-1.0, min(1.0, v))
        frames.extend(struct.pack("<h", int(s * 32767)))
    with wave.open(full, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        w.writeframes(bytes(frames))
    print(f"  {path:<46} {len(frames) / 1024:7.1f} KB")


# --- The clip set ------------------------------------------------------------


def build_count_ladder() -> None:
    print("counting ladder (C major, one note per counted object)")
    for idx, hz in enumerate(COUNT_LADDER_HZ, start=1):
        # Slightly shorter decay as we climb so the high notes don't smear
        # together when a child taps quickly.
        decay = 0.34 - (idx - 1) * 0.012
        write(f"sfx/counting/count-{idx:02d}.wav", tone(hz, 0.55, decay=decay))


def build_ui() -> None:
    print("ui")
    write("sfx/ui/tap.wav", mix(tone(1180, 0.09, decay=0.03), gain(noise(0.04, 0.02, 0.5), 0.18)))
    write("sfx/ui/whoosh.wav", gain(noise(0.34, decay=0.12, lowpass=0.06, seed=21), 0.9))
    write("sfx/ui/bubble-in.wav", sweep(420, 900, 0.20, decay=0.09))


def build_feedback() -> None:
    print("feedback")
    # Round-pass stinger: a bright major triad, arpeggiated fast.
    write(
        "sfx/feedback/correct-chime.wav",
        mix(
            tone(659.25, 0.75, decay=0.30),
            delay(tone(830.61, 0.70, decay=0.30), 0.075),
            delay(tone(987.77, 0.85, decay=0.38), 0.150),
        ),
    )
    # Wrong: a soft low muted thud. Deliberately NOT a buzzer and NOT dissonant —
    # specs/shared/art-direction.md and playtest-watchlist.md §1 both require a
    # soft "puff", so this reads as "not that one", never as punishment.
    write(
        "sfx/feedback/wrong-soft.wav",
        mix(
            gain(tone(196.00, 0.26, decay=0.075, partials=((1.0, 1.0), (2.0, 0.10))), 0.85),
            gain(noise(0.10, decay=0.035, lowpass=0.045, seed=3), 0.30),
        ),
    )
    write(
        "sfx/feedback/hint.wav",
        mix(tone(880.00, 0.34, decay=0.16), delay(tone(1174.66, 0.40, decay=0.18), 0.11)),
    )


def build_reward() -> None:
    print("reward")
    write(
        "sfx/reward/coin.wav",
        mix(tone(987.77, 0.20, decay=0.07), delay(tone(1318.51, 0.42, decay=0.20), 0.055)),
    )
    # Sub-mode complete. A rising C-major run that lands on the octave.
    fanfare_notes = [523.25, 659.25, 783.99, 1046.50]
    layers = [
        delay(tone(hz, 1.15 - i * 0.12, decay=0.42 - i * 0.03), i * 0.105)
        for i, hz in enumerate(fanfare_notes)
    ]
    layers.append(delay(gain(tone(1567.98, 1.0, decay=0.55), 0.55), 0.42))
    write("sfx/reward/fanfare.wav", mix(*layers))
    write(
        "sfx/reward/egg-crack.wav",
        mix(
            gain(noise(0.20, decay=0.05, lowpass=0.55, seed=11), 0.85),
            gain(tone(140.0, 0.34, decay=0.10, partials=((1.0, 1.0), (1.5, 0.2))), 0.7),
            delay(gain(noise(0.12, decay=0.03, lowpass=0.7, seed=13), 0.5), 0.13),
        ),
    )


def build_buddy() -> None:
    print("buddy")
    # Non-verbal only. specs/shared/k-activity-patterns.md: the Buddy never
    # speaks in scenes, so these are chirps with no vowel character at all.
    write(
        "sfx/buddy/happy.wav",
        mix(sweep(620, 1240, 0.17, decay=0.08), delay(sweep(880, 1560, 0.20, decay=0.10), 0.10)),
    )
    write("sfx/buddy/curious.wav", sweep(430, 640, 0.26, decay=0.14))


def build_sprite() -> None:
    print("sprite")
    write("sfx/sprite/pop.wav", mix(tone(760, 0.13, decay=0.045), gain(noise(0.03, 0.015, 0.6), 0.2)))
    write(
        "sfx/sprite/drop.wav",
        mix(
            gain(tone(240, 0.20, decay=0.055, partials=((1.0, 1.0), (2.0, 0.15))), 0.9),
            gain(noise(0.07, decay=0.025, lowpass=0.3, seed=5), 0.35),
        ),
    )
    shimmer = [
        delay(gain(tone(hz, 0.5, decay=0.16), 0.55), i * 0.035)
        for i, hz in enumerate([1567.98, 2093.00, 1760.00, 2349.32, 1975.53])
    ]
    write("sfx/sprite/sparkle.wav", mix(*shimmer))


def build_silence() -> None:
    print("misc")
    # Used as the autoplay-unlock probe: playing a silent clip inside the first
    # user gesture blesses an HTMLAudioElement without the child hearing a blip.
    write("sfx/silence.wav", array.array("d", [0.0] * int(SR * 0.1)))


def fold_tail_into_head(buf: array.array, xf: int) -> array.array:
    """Make a buffer loop seamlessly, by blending its tail into its head.

    The last xf frames are mixed into the first xf and then DROPPED. That
    truncation is the whole point and it is what the first version of this
    missed: it blended correctly, zeroed the tail, and returned a buffer of the
    original length. The music bed therefore ended in 1.2 seconds of exact
    silence, and every loop had an audible hole in it - which is what a
    five-year-old actually heard, roughly every seventeen seconds, for the
    length of every session.
    """
    total = len(buf)
    if xf <= 0 or xf * 2 >= total:
        return buf
    for i in range(xf):
        k = i / xf
        buf[i] = buf[i] * k + buf[total - xf + i] * (1 - k)
    return buf[: total - xf]


def build_music() -> None:
    """The challenge bed. A brisk pentatonic pad loop that sits under narration.

    There used to be a second, calmer bed here for the Sanctuary itself. It has
    been replaced by a real four-minute recording -- see kSanctuaryMusicBed in
    app/lib/data/sfx_catalog.dart -- so this generator no longer writes
    music/sanctuary-low.wav. Re-adding it would ship 688 KB that nothing loads.
    """
    print("music (22.05 kHz to keep the loop small)")
    sr = 22050
    bars = 8
    beat = 1.05
    total = int(sr * bars * 2 * beat)
    # Cross-fade the tail into the head so the loop point is inaudible.
    xf = int(sr * 1.2)

    # A pentatonic pattern has no semitone clashes, so any two overlapping notes
    # stay consonant however the loop wraps.
    buf2 = array.array("d", [0.0] * total)
    pattern2 = [392.00, 493.88, 587.33, 659.25, 587.33, 493.88, 440.00, 493.88]
    for bar in range(bars):
        for step, hz in enumerate(pattern2):
            start = int((bar * 2 * beat + step * beat / 4) * sr)
            dur = 1.8
            n = int(sr * dur)
            w1 = 2 * math.pi * hz
            for i in range(n):
                if start + i >= total:
                    break
                t = i / sr
                env = math.exp(-t / 0.6) * (1 - math.exp(-t / 0.04))
                buf2[start + i] += 0.45 * env * math.sin(w1 * t)
    buf2 = fold_tail_into_head(buf2, xf)
    write(
        "music/sanctuary-challenge-rising.wav",
        gain(buf2, 0.5),
        sample_rate=sr,
        fade=False,
    )


def main() -> None:
    print(f"Writing to {OUT_ROOT}\n")
    build_count_ladder()
    build_ui()
    build_feedback()
    build_reward()
    build_buddy()
    build_sprite()
    build_silence()
    build_music()
    print("\nDone.")


if __name__ == "__main__":
    main()
