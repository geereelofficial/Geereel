import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../providers/status_providers.dart';

/// Picker + preview for posting a new 24h status. Simpler than the post
/// upload flow (no caption) — once shared, pops back to wherever the
/// status tray's "+" was tapped from.
class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedFile;
  MediaType? _selectedMediaType;
  VideoPlayerController? _previewController;

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 30));
    if (picked == null) return;
    await _setSelectedFile(File(picked.path), MediaType.video);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    await _setSelectedFile(File(picked.path), MediaType.image);
  }

  Future<void> _setSelectedFile(File file, MediaType mediaType) async {
    _previewController?.dispose();
    _previewController = null;

    if (mediaType == MediaType.video) {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(true);
      controller.play();
      _previewController = controller;
    }

    setState(() {
      _selectedFile = file;
      _selectedMediaType = mediaType;
    });
  }

  void _reset() {
    _previewController?.dispose();
    _previewController = null;
    setState(() {
      _selectedFile = null;
      _selectedMediaType = null;
    });
  }

  Future<void> _share() async {
    final file = _selectedFile;
    final mediaType = _selectedMediaType;
    if (file == null || mediaType == null) return;

    final success = await ref.read(statusUploadControllerProvider.notifier).postStatus(
      mediaFile: file,
      mediaType: mediaType,
    );

    if (!mounted) return;
    if (success) {
      context.pop();
    } else {
      final error = ref.read(statusUploadControllerProvider).error;
      final message = error is Failure ? error.message : 'Could not share your status.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Add to status'),
        leading: _selectedFile == null
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop())
            : IconButton(icon: const Icon(Icons.close), onPressed: _reset),
      ),
      body: _selectedFile == null ? _buildPicker() : _buildComposer(),
    );
  }

  Widget _buildPicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 64),
            const SizedBox(height: 24),
            const Text('Share a photo or video', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            const Text(
              'Visible to your followers for 24 hours.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.photo_library,
                    label: 'Photo from gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.camera_alt,
                    label: 'Take photo',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.video_library,
                    label: 'Video from gallery',
                    onTap: () => _pickVideo(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.videocam,
                    label: 'Record video',
                    onTap: () => _pickVideo(ImageSource.camera),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final uploadState = ref.watch(statusUploadControllerProvider);
    final progress = ref.watch(statusUploadProgressProvider);
    final isUploading = uploadState.isLoading;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 16),
            if (isUploading) ...[
              LinearProgressIndicator(value: progress, color: AppColors.primary),
              const SizedBox(height: 12),
            ],
            PrimaryButton(label: 'Share to status', onPressed: _share, isLoading: isUploading),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_selectedMediaType == MediaType.image) {
      return Image.file(_selectedFile!, fit: BoxFit.cover, width: double.infinity);
    }

    final controller = _previewController;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: AppColors.surface);
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

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
