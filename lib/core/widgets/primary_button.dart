import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Primary call-to-action button with a built-in loading state, used by
/// auth forms, the upload screen's "Post" action, and profile editing.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textPrimary),
              )
            : Text(label),
      ),
    );
  }
}
