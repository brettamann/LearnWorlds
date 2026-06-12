// SubModePickerSheet — modal bottom sheet shown when the kid taps a
// Sanctuary node that has more than one available sub-mode to play. Each
// option renders as a square card with the sub-mode's symbol sprite, a
// short label, and a hint chip ("New!" for the next un-completed
// sub-mode, "Replay" for previously-completed ones).
//
// Designed for K-level UX — big tap targets, no text-only options, no
// numeric ordering. The kid picks by what the icons *look like*.

import 'package:flutter/material.dart';

import '../../data/sub_mode_picker_data.dart';
import '../../models/activity.dart';

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
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'What do you want to play?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activityDisplayName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final e in entries)
                    _OptionCard(
                      activityId: activityId,
                      entry: e,
                      onTap: () =>
                          Navigator.of(sheetCtx).pop(e.subMode.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.activityId,
    required this.entry,
    required this.onTap,
  });

  final String activityId;
  final SubModePickerEntry entry;
  final VoidCallback onTap;

  static const double _cardWidth = 160;
  static const double _spriteSize = 96;

  @override
  Widget build(BuildContext context) {
    final option = pickerOptionFor(
      activityId: activityId,
      subModeId: entry.subMode.id,
    );
    final label = option?.label ?? entry.subMode.id;
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
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
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
                      : Image.asset(option.symbolAsset, fit: BoxFit.contain),
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
    );
  }
}
