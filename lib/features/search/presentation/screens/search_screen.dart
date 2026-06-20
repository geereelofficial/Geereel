import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/search_providers.dart';

/// Account search: a TikTok-style search field that filters users by
/// username/display name as you type, debounced in [SearchController].
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(userSearchControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: AppTextStyles.body,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Search accounts',
            hintStyle: AppTextStyles.bodySecondary,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() {});
            ref.read(userSearchControllerProvider.notifier).search(value);
          },
        ),
      ),
      body: resultsAsync.when(
        data: (users) {
          if (_controller.text.trim().isEmpty) {
            return const Center(
              child: Text(
                'Search for people by username or name',
                style: AppTextStyles.bodySecondary,
              ),
            );
          }
          if (users.isEmpty) {
            return const Center(
              child: Text('No users found.', style: AppTextStyles.bodySecondary),
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: AppAvatar(photoUrl: user.photoUrl, radius: 22),
                title: Text(user.displayName, style: AppTextStyles.body),
                subtitle: Text('@${user.username}', style: AppTextStyles.caption),
                onTap: () => context.push('/profile/${user.uid}'),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(message: error.toString()),
      ),
    );
  }
}
