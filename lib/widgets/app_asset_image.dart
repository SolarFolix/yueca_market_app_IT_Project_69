import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Drop-in replacement for Image.asset that never crashes the app while
/// you're still adding files to assets/images. Once the named file exists,
/// it renders automatically — no code changes needed.
class AppAssetImage extends StatelessWidget {
  final String assetPath; // e.g. 'assets/images/market_banner.jpg'
  final BoxFit fit;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;

  const AppAssetImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.primaryLight.withOpacity(0.18),
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: AppColors.primaryDark.withOpacity(0.5), size: 28),
      ),
    );
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
