import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isComingSoon;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Main card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: isComingSoon
                  ? AppTheme.surfaceColor
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(
                color: isComingSoon
                    ? AppTheme.dividerColor
                    : AppTheme.dividerColor,
              ),
              boxShadow: isComingSoon ? null : AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isComingSoon
                        ? AppTheme.primaryColor.withValues(alpha: 0.05)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    icon,
                    color: isComingSoon
                        ? AppTheme.subtleText
                        : AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  title,
                  style: AppTheme.subheadingStyle.copyWith(
                    fontSize: 14,
                    color: isComingSoon
                        ? AppTheme.subtleText
                        : AppTheme.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.captionStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Coming Soon badge — Stack overlay
          if (isComingSoon)
            Positioned(
              top: AppTheme.spacingS,
              right: AppTheme.spacingS,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    color: AppTheme.subtleText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
