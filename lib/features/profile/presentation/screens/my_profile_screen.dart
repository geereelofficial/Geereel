import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'profile_screen.dart';

/// Resolves the signed-in user's uid and delegates to [ProfileScreen],
/// so the bottom-nav "Profile" tab doesn't need the uid in its route path.
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value;
    if (uid == null) return const SizedBox.shrink();
    return ProfileScreen(uid: uid);
  }
}
