import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/feed_providers.dart';

/// TikTok-style overlay above the feed: "Following" / "For You" tabs
/// centered, with a search icon pinned to the right.
class FeedTopBar extends ConsumerWidget {
  const FeedTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedFeedTabProvider);

    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TabLabel(
                label: 'Following',
                isSelected: selected == FeedTab.following,
                onTap: () => ref.read(selectedFeedTabProvider.notifier).select(FeedTab.following),
              ),
              const SizedBox(width: 28),
              _TabLabel(
                label: 'For You',
                isSelected: selected == FeedTab.forYou,
                onTap: () => ref.read(selectedFeedTabProvider.notifier).select(FeedTab.forYou),
              ),
            ],
          ),
          Positioned(
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 34),
              onPressed: () => context.push('/search'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabLabel({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 3,
            width: 26,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
