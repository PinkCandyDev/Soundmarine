import 'package:flutter/material.dart';

/// A row with Play, Shuffle pill buttons and a trailing "more" icon.
class ActionButtonsRow extends StatelessWidget {
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final VoidCallback? onMore;

  const ActionButtonsRow({
    super.key,
    this.onPlay,
    this.onShuffle,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _PillButton(
            label: 'Play',
            backgroundColor: Colors.blue,
            onTap: onPlay,
          ),
          const SizedBox(width: 16),
          _PillButton(
            label: 'Shuffle',
            backgroundColor: Colors.grey[800]!,
            onTap: onShuffle,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.grey[500]),
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
