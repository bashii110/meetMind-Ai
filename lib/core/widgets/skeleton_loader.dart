import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/spacing.dart';

/// DESIGN.md 4: "Skeleton loaders for lists." `shimmer` has been a
/// pubspec dependency since the original scaffold (see its own comment
/// there) but was never actually wired up — every list screen used a
/// bare `CircularProgressIndicator` instead. This is the first real
/// usage, applied to the screens DESIGN.md calls out by name.
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: child,
    );
  }
}

/// A skeleton standing in for a single list-item card (the meeting-card /
/// task-card shape) — three lines of decreasing width inside a
/// card-shaped block. `shimmer` masks a solid color, so the inner blocks
/// are plain white regardless of theme — the shimmer gradient is what
/// actually reads as color.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 88});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _Bar(width: double.infinity, height: 14),
          _Bar(width: 160, height: 12),
          _Bar(width: 100, height: 12),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(width: width, height: height, color: Colors.white);
}

/// A vertical list of [SkeletonCard]s, for a list screen's loading state.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.builder(
        padding: const EdgeInsets.all(Spacing.lg),
        itemCount: count,
        itemBuilder: (context, index) => const SkeletonCard(),
      ),
    );
  }
}
