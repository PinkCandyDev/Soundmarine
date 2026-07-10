import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';



class TrackListSkeleton extends StatelessWidget {
  const TrackListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _ShimmerRow(),
          );
        },
        childCount: 8,
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    // premium dark palette (Spotify-ish)
    final baseColor = const Color(0xFF1A1A1A);
    final highlightColor = const Color(0xFF2A2A2A);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // cover
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(width: 12),

          // text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          
          Icon(
            Icons.favorite,
            color: Colors.white,
            size: 22,
          ),

          const SizedBox(width: 10),

          Icon(
            Icons.more_horiz,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }
}