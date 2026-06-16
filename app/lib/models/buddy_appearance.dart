// BuddyAppearance — the kid's saved Buddy configuration. A small bag of
// catalog ids; the BuddyWidget resolves them to sprite paths at render
// time so swapping one PNG behind a catalog id propagates everywhere
// the Buddy shows up without any extra wiring.

import '../data/buddy_parts_catalog.dart';

class BuddyAppearance {
  const BuddyAppearance({
    required this.bodyId,
    required this.eyesId,
    required this.mouthId,
    required this.armsId,
    required this.legsId,
    this.hatId,
  });

  /// Default Buddy a fresh save starts with. Picked so the first thing a
  /// kid sees in the Hub already feels like a finished character even
  /// before they tap the character creator. No hat by default — the
  /// kid opts into hats explicitly.
  factory BuddyAppearance.defaults() => const BuddyAppearance(
        bodyId: kBuddyDefaultBodyId,
        eyesId: kBuddyDefaultEyesId,
        mouthId: kBuddyDefaultMouthId,
        armsId: kBuddyDefaultArmsId,
        legsId: kBuddyDefaultLegsId,
      );

  factory BuddyAppearance.fromJson(Map<String, dynamic> json) {
    return BuddyAppearance(
      bodyId: json['bodyId'] as String? ?? kBuddyDefaultBodyId,
      eyesId: json['eyesId'] as String? ?? kBuddyDefaultEyesId,
      mouthId: json['mouthId'] as String? ?? kBuddyDefaultMouthId,
      armsId: json['armsId'] as String? ?? kBuddyDefaultArmsId,
      legsId: json['legsId'] as String? ?? kBuddyDefaultLegsId,
      hatId: json['hatId'] as String?,
    );
  }

  final String bodyId;
  final String eyesId;
  final String mouthId;
  final String armsId;
  final String legsId;

  /// Optional accessory. Null = no hat is rendered. Cleared by passing
  /// `clearHat: true` to `copyWith`.
  final String? hatId;

  BuddyAppearance copyWith({
    String? bodyId,
    String? eyesId,
    String? mouthId,
    String? armsId,
    String? legsId,
    String? hatId,
    bool clearHat = false,
  }) {
    return BuddyAppearance(
      bodyId: bodyId ?? this.bodyId,
      eyesId: eyesId ?? this.eyesId,
      mouthId: mouthId ?? this.mouthId,
      armsId: armsId ?? this.armsId,
      legsId: legsId ?? this.legsId,
      hatId: clearHat ? null : (hatId ?? this.hatId),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bodyId': bodyId,
        'eyesId': eyesId,
        'mouthId': mouthId,
        'armsId': armsId,
        'legsId': legsId,
        if (hatId != null) 'hatId': hatId,
      };
}
