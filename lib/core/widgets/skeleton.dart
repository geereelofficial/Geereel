import 'package:flutter/material.dart';

/// Pulsing grey box — the building block for all skeleton layouts.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _opacity.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for a full-screen video feed item.
class FeedItemSkeleton extends StatelessWidget {
  const FeedItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF1A1A1A)),
        Positioned(
          left: 16,
          right: 88,
          bottom: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(width: 120, height: 14),
              const SizedBox(height: 10),
              SkeletonBox(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              SkeletonBox(width: 180, height: 12),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(width: 40, height: 40, borderRadius: 20),
              const SizedBox(height: 20),
              SkeletonBox(width: 32, height: 32, borderRadius: 16),
              const SizedBox(height: 4),
              SkeletonBox(width: 24, height: 10),
              const SizedBox(height: 20),
              SkeletonBox(width: 32, height: 32, borderRadius: 16),
              const SizedBox(height: 4),
              SkeletonBox(width: 24, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton for a list tile with an avatar, title line, and subtitle line.
/// Used for notifications, chat list, follow list, etc.
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SkeletonBox(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 13),
                const SizedBox(height: 6),
                SkeletonBox(width: double.infinity, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SkeletonBox(width: 48, height: 11),
        ],
      ),
    );
  }
}

/// A scrollable list of [count] [ListTileSkeleton]s.
/// Uses ListView so it never overflows when placed inside an Expanded.
class ListSkeletonLoader extends StatelessWidget {
  final int count;

  const ListSkeletonLoader({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (_, __) => const ListTileSkeleton(),
    );
  }
}
