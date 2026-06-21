import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/status_providers.dart';

/// Owner-only "viewed by" list for one status, as a draggable bottom sheet.
void showStatusViewersSheet(BuildContext context, {required String statusId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _StatusViewersSheet(statusId: statusId),
  );
}

class _StatusViewersSheet extends ConsumerWidget {
  final String statusId;

  const _StatusViewersSheet({required this.statusId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewersAsync = ref.watch(statusViewersProvider(statusId));

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const Text('Viewed by', style: AppTextStyles.heading3),
            const Divider(height: 24),
            Expanded(
              child: viewersAsync.when(
                data: (viewers) {
                  if (viewers.isEmpty) {
                    return const Center(
                      child: Text('No views yet.', style: AppTextStyles.bodySecondary),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: viewers.length,
                    itemBuilder: (context, index) {
                      final viewer = viewers[index];
                      return ListTile(
                        leading: AppAvatar(photoUrl: viewer.photoUrl, radius: 20),
                        title: Text('@${viewer.username}', style: AppTextStyles.username),
                        trailing: Text(
                          Formatters.relativeTime(viewer.viewedAt),
                          style: AppTextStyles.caption,
                        ),
                      );
                    },
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (error, _) => ErrorView(message: error.toString()),
              ),
            ),
          ],
        );
      },
    );
  }
}
