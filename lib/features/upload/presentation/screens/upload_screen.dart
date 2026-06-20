import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../providers/upload_providers.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedFile;
  MediaType? _selectedMediaType;
  VideoPlayerController? _previewController;

  @override
  void dispose() {
    _captionController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 3));
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
    _captionController.clear();
    setState(() {
      _selectedFile = null;
      _selectedMediaType = null;
    });
  }

  Future<void> _post() async {
    final file = _selectedFile;
    final mediaType = _selectedMediaType;
    if (file == null || mediaType == null) return;

    final success = await ref.read(uploadControllerProvider.notifier).postMedia(
      mediaFile: file,
      mediaType: mediaType,
      caption: _captionController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      _reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posted!'), backgroundColor: AppColors.success),
      );
    } else {
      final error = ref.read(uploadControllerProvider).error;
      final message = error is Failure ? error.message : 'Upload failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        leading: _selectedFile == null
            ? null
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
            const Icon(Icons.video_call, color: AppColors.primary, size: 64),
            const SizedBox(height: 24),
            const Text('Share a video or photo', style: AppTextStyles.heading3),
            const SizedBox(height: 32),
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
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final uploadState = ref.watch(uploadControllerProvider);
    final progress = ref.watch(uploadProgressProvider);
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
            TextField(
              controller: _captionController,
              maxLines: 3,
              maxLength: AppConstants.maxCaptionLength,
              decoration: const InputDecoration(hintText: 'Write a caption...'),
            ),
            const SizedBox(height: 12),
            if (isUploading) ...[
              LinearProgressIndicator(value: progress, color: AppColors.primary),
              const SizedBox(height: 12),
            ],
            PrimaryButton(label: 'Post', onPressed: _post, isLoading: isUploading),
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
