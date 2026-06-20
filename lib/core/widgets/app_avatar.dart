import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Circular user avatar with a placeholder/error fallback icon, used in
/// the feed, profile, and chat screens.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;

  const AppAvatar({super.key, this.photoUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surfaceVariant,
        child: Icon(Icons.person, color: AppColors.textSecondary, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceVariant,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, _) => const SizedBox.shrink(),
          errorWidget: (_, _, _) => Icon(Icons.person, color: AppColors.textSecondary, size: radius),
        ),
      ),
    );
  }
}
