import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class _UploadScreenState extends ConsumerState<UploadScreen> with WidgetsBindingObserver {
  // Camera
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isVideoMode = true;
  bool _isRecording = false;
  bool _cameraReady = false;
  bool _cameraError = false;

  // Composer
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  MediaType? _selectedMediaType;
  VideoPlayerController? _previewController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captionController.dispose();
    _previewController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_cameraIndex);
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraError = true);
        return;
      }
      await _startCamera(0);
    } catch (_) {
      setState(() => _cameraError = true);
    }
  }

  Future<void> _startCamera(int index) async {
    await _cameraController?.dispose();
    setState(() => _cameraReady = false);

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _cameraController = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameraIndex);
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await controller.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      await _setSelectedFile(File(file.path), MediaType.image);
    } catch (_) {}
  }

  Future<void> _startRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isRecording) return;
    try {
      await controller.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    final controller = _cameraController;
    if (controller == null || !_isRecording) return;
    try {
      final file = await controller.stopVideoRecording();
      setState(() => _isRecording = false);
      await _setSelectedFile(File(file.path), MediaType.video);
    } catch (_) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isVideoMode) {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (picked != null) await _setSelectedFile(File(picked.path), MediaType.video);
    } else {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked != null) await _setSelectedFile(File(picked.path), MediaType.image);
    }
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
      context.go('/feed');
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
    if (_selectedFile != null) return _buildComposer();
    return _buildCameraView();
  }

  // ─────────────────────────── Camera View ───────────────────────────

  Widget _buildCameraView() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live camera preview
          if (_cameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else if (_cameraError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography, color: Colors.white54, size: 56),
                  const SizedBox(height: 16),
                  const Text('Camera not available', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _pickFromGallery(),
                    child: const Text('Pick from gallery', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top bar: close + flash + flip
          Positioned(
            top: statusBarHeight + 4,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _TopButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _TopButton(
                    icon: _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                    onTap: _toggleFlash,
                  ),
                  const SizedBox(width: 8),
                  _TopButton(
                    icon: Icons.flip_camera_ios_outlined,
                    onTap: _flipCamera,
                  ),
                ],
              ),
            ),
          ),

          // Mode toggle (Photo / Video)
          Positioned(
            bottom: bottomInset + 130,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeChip(
                  label: 'VIDEO',
                  active: _isVideoMode,
                  onTap: () => setState(() => _isVideoMode = true),
                ),
                const SizedBox(width: 20),
                _ModeChip(
                  label: 'PHOTO',
                  active: !_isVideoMode,
                  onTap: () => setState(() => _isVideoMode = false),
                ),
              ],
            ),
          ),

          // Bottom bar: gallery | capture | spacer
          Positioned(
            bottom: bottomInset + 32,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gallery picker
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 26),
                    ),
                  ),

                  // Capture / record button
                  _CaptureButton(
                    isVideoMode: _isVideoMode,
                    isRecording: _isRecording,
                    onTap: _isVideoMode
                        ? (_isRecording ? _stopRecording : _startRecording)
                        : _capturePhoto,
                  ),

                  // Placeholder for balance
                  const SizedBox(width: 52),
                ],
              ),
            ),
          ),

          // Recording indicator
          if (_isRecording)
            Positioned(
              top: statusBarHeight + 60,
              left: 0,
              right: 0,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 10),
                    SizedBox(width: 6),
                    Text('REC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── Composer View ───────────────────────────

  Widget _buildComposer() {
    final uploadState = ref.watch(uploadControllerProvider);
    final progress = ref.watch(uploadProgressProvider);
    final isUploading = uploadState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Post'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _reset),
      ),
      body: SafeArea(
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

// ─────────────────────────── Small reusable widgets ───────────────────────────

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool isVideoMode;
  final bool isRecording;
  final VoidCallback onTap;

  const _CaptureButton({
    required this.isVideoMode,
    required this.isRecording,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: isRecording
              ? Colors.red
              : (isVideoMode ? Colors.red.withValues(alpha: 0.85) : Colors.white),
        ),
        child: isRecording
            ? const Icon(Icons.stop_rounded, color: Colors.white, size: 32)
            : Icon(
                isVideoMode ? Icons.videocam_rounded : Icons.camera_alt_rounded,
                color: isVideoMode ? Colors.white : Colors.black,
                size: 32,
              ),
      ),
    );
  }
}
