import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/professor.dart';

class ProfessorCard extends StatelessWidget {
  final Professor professor;
  final VoidCallback onTap;

  const ProfessorCard({
    super.key,
    required this.professor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            // Name and info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(professor.name, style: AppTheme.subheadingStyle),
                  const SizedBox(height: 2),
                  Text(professor.department, style: AppTheme.captionStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Text(
                          professor.mainSubject,
                          style: AppTheme.captionStyle.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.subtleText,
            ),
          ],
        ),
      ),
    );
  }
}
