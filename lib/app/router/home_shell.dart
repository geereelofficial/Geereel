import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Bottom navigation shell for the three persistent tabs (Feed, Chat,
/// Profile). "Upload" sits visually between Chat and Profile but isn't a
/// stateful branch — tapping it pushes /upload as a one-off screen instead
/// of switching tabs, matching TikTok's center "+" button.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  static const _branchForVisualIndex = {0: 0, 1: 1, 3: 2};
  static const _visualIndexForBranch = {0: 0, 1: 1, 2: 3};

  void _onTap(BuildContext context, int visualIndex) {
    if (visualIndex == 2) {
      context.push('/upload');
      return;
    }
    final branchIndex = _branchForVisualIndex[visualIndex]!;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentVisualIndex = _visualIndexForBranch[navigationShell.currentIndex] ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentVisualIndex,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Inbox'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, color: AppColors.primary, size: 32),
            label: 'Post',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
