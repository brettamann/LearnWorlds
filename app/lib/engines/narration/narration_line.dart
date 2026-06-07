// NarrationLine — a single caption that the player is currently showing.
// During the TTS deferral (specs/shared/text-and-tts-deferral.md) this is the
// only narration surface. Post-deferral, the same value object also drives
// pre-rendered audio + (optional) system-TTS dispatch.

class NarrationLine {
  const NarrationLine({
    required this.text,
    this.cueId,
    this.speaker = 'narrator',
  });

  /// Visible caption text.
  final String text;

  /// Stable id for analytics + future pre-rendered audio lookup.
  /// Null lines are runtime-composed and won't have one.
  final String? cueId;

  /// Who's speaking. 'narrator' for the regional narrator, 'buddy' for the
  /// kid's Buddy. Determines visual treatment in the caption layer.
  final String speaker;
}
