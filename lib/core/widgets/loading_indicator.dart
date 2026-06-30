import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class LoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;

  const LoadingIndicator({super.key, this.size = 44, this.color = AppColors.primary});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _DotsCirclePainter(
              progress: _controller.value,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _DotsCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  static const int _dotCount = 8;

  const _DotsCirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = size.width / 2 - 5;
    final maxDotRadius = size.width / 9;

    for (int i = 0; i < _dotCount; i++) {
      final angle = (2 * pi * i / _dotCount) - pi / 2;
      final dotCenter = Offset(
        center.dx + orbitRadius * cos(angle),
        center.dy + orbitRadius * sin(angle),
      );
      final distance = ((i / _dotCount) - progress + 1.0) % 1.0;
      final opacity = (1.0 - distance * 1.5).clamp(0.08, 1.0);
      final dotRadius = maxDotRadius * (0.4 + 0.6 * opacity);

      canvas.drawCircle(
        dotCenter,
        dotRadius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsCirclePainter old) => old.progress != progress;
}
