import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../domain/entities/status_entity.dart';
import '../providers/status_providers.dart';
import '../widgets/status_viewers_sheet.dart';

const _imageDuration = Duration(seconds: 5);

/// Full-screen tap-through status viewer for one author at a time —
/// tapping the right/left half advances/retreats, running out of an
/// author's statuses moves to the next author in the tray (same order the
/// tray displayed them), matching Instagram/WhatsApp/TikTok's status flow.
class StatusViewerScreen extends ConsumerStatefulWidget {
  final String authorId;

  const StatusViewerScreen({super.key, required this.authorId});

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  VideoPlayerController? _videoController;

  late String _authorId;
  int _index = 0;
  String? _startedKey;
  List<StatusEntity> _latestStatuses = const [];

  @override
  void initState() {
    super.initState();
    _authorId = widget.authorId;
    _progress = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _onAdvance(_latestStatuses);
      });
  }

  @override
  void dispose() {
    _progress.dispose();
    _videoController?.dispose();
    ref.read(statusViewControllerProvider.notifier).refreshTray();
    super.dispose();
  }

  void _playCurrent(StatusEntity status) {
    ref.read(statusViewControllerProvider.notifier).markViewed(status.statusId);

    _videoController?.dispose();
    _videoController = null;
    _progress.stop();
    _progress.reset();

    if (status.mediaType == MediaType.video) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(status.mediaUrl));
      _videoController = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        final duration = controller.value.duration;
        _progress.duration = duration > Duration.zero ? duration : _imageDuration;
        controller.play();
        _progress.forward();
        setState(() {});
      });
    } else {
      _progress.duration = _imageDuration;
      _progress.forward();
    }
  }

  void _onAdvance(List<StatusEntity> statuses) {
    if (statuses.isEmpty) return;
    if (_index < statuses.length - 1) {
      setState(() => _index++);
    } else {
      _goToAuthor(offset: 1);
    }
  }

  void _onRetreat(List<StatusEntity> statuses) {
    if (_index > 0) {
      setState(() => _index--);
    } else {
      _goToAuthor(offset: -1);
    }
  }

  void _goToAuthor({required int offset}) {
    final groups = ref.read(statusTrayProvider).value ?? const [];
    final ids = groups.map((g) => g.authorId).toList();
    final current = ids.indexOf(_authorId);
    final next = current == -1 ? -1 : current + offset;

    if (next < 0 || next >= ids.length) {
      if (mounted) context.pop();
      return;
    }

    setState(() {
      _authorId = ids[next];
      _index = 0;
      _startedKey = null;
    });
  }

  void _togglePause(bool pause) {
    if (pause) {
      _progress.stop();
      _videoController?.pause();
    } else {
      _progress.forward();
      _videoController?.play();
    }
  }

  Future<void> _delete(String statusId) async {
    final result = await ref.read(statusViewControllerProvider.notifier).deleteStatus(statusId);
    if (result case Ok() when mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).value;
    final statusesAsync = ref.watch(userStatusesProvider(_authorId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: statusesAsync.when(
        data: (statuses) {
          _latestStatuses = statuses;

          if (statuses.isEmpty) {
            return _ClosablePlaceholder(
              message: 'No active status.',
              onClose: () => context.pop(),
            );
          }

          final index = _index.clamp(0, statuses.length - 1);
          final status = statuses[index];
          final key = status.statusId;

          if (_startedKey != key) {
            _startedKey = key;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _playCurrent(status);
            });
          }

          final isMine = myUid != null && status.authorId == myUid;

          return Stack(
            fit: StackFit.expand,
            children: [
              _buildMedia(status),
              GestureDetector(
                onTapUp: (details) {
                  final width = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < width / 2) {
                    _onRetreat(statuses);
                  } else {
                    _onAdvance(statuses);
                  }
                },
                onLongPressStart: (_) => _togglePause(true),
                onLongPressEnd: (_) => _togglePause(false),
                onVerticalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) > 200) context.pop();
                },
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      _ProgressBars(count: statuses.length, index: index, controller: _progress),
                      const SizedBox(height: 10),
                      _Header(
                        status: status,
                        isMine: isMine,
                        onClose: () => context.pop(),
                        onDelete: () => _delete(status.statusId),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMine)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _ViewersButton(status: status),
                ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => _ClosablePlaceholder(
          message: 'Could not load this status.\n$error',
          onClose: () => context.pop(),
          onRetry: () => ref.invalidate(userStatusesProvider(_authorId)),
        ),
      ),
    );
  }

  Widget _buildMedia(StatusEntity status) {
    if (status.mediaType == MediaType.image) {
      return Image.network(status.mediaUrl, fit: BoxFit.cover);
    }
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  final int count;
  final int index;
  final AnimationController controller;

  const _ProgressBars({required this.count, required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: i < index
                  ? const _Bar(value: 1)
                  : i > index
                  ? const _Bar(value: 0)
                  : AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) => _Bar(value: controller.value),
                    ),
            ),
          ),
        );
      }),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;

  const _Bar({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: Stack(
        children: [
          const ColoredBox(color: Colors.white24),
          FractionallySizedBox(widthFactor: value.clamp(0, 1), child: const ColoredBox(color: Colors.white)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final StatusEntity status;
  final bool isMine;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _Header({required this.status, required this.isMine, required this.onClose, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(photoUrl: status.authorPhotoUrl, radius: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('@${status.authorUsername}', style: AppTextStyles.username),
              Text(Formatters.relativeTime(status.createdAt), style: AppTextStyles.caption),
            ],
          ),
        ),
        if (isMine)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: onDelete,
          ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _ViewersButton extends StatelessWidget {
  final StatusEntity status;

  const _ViewersButton({required this.status});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showStatusViewersSheet(context, statusId: status.statusId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '${status.viewsCount} ${status.viewsCount == 1 ? 'view' : 'views'}',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosablePlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  final VoidCallback? onRetry;

  const _ClosablePlaceholder({required this.message, required this.onClose, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClose,
            ),
          ),
        ),
      ],
    );
  }
}
