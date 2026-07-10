import 'package:flutter/material.dart';

/// The top section of album/playlist detail screens:
/// a large cover image followed by title & subtitle text.
class CollectionHeader extends StatelessWidget {
  final Widget cover;
  final String title;
  final String? subtitle;
  final Widget? bottomSection;

  const CollectionHeader({
    super.key,
    required this.cover,
    required this.title,
    this.subtitle,
    this.bottomSection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 75, right: 75, top: 75, bottom: 20),
          child: cover,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ?bottomSection,
        const SizedBox(height: 24),
      ],
    );
  }
}
