import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';

/// Shown briefly while the initial auth state resolves, before the router
/// redirects to /feed or /login.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Geereel', style: AppTextStyles.heading1.copyWith(color: AppColors.primary)),
            const SizedBox(height: 24),
            const LoadingIndicator(),
          ],
        ),
      ),
    );
  }
}
