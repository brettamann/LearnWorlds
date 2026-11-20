// RoundBackButton - the white circular back arrow over a full-bleed scene.

import 'package:flutter/material.dart';

class RoundBackButton extends StatelessWidget {
  const RoundBackButton({
    super.key,
    required this.onPressed,
    this.semanticLabel = 'Back to the Sanctuary',
  });

  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.white.withValues(alpha: 0.88),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_back,
            size: 28,
            color: Colors.black87,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
