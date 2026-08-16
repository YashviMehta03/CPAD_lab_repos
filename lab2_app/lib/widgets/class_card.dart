import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/class_entry.dart';

class ClassCard extends StatelessWidget {
  final ClassEntry entry;

  const ClassCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Time column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.startTime,
                style: AppTheme.subheadingStyle.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 15,
                ),
              ),
              Text(
                entry.endTime,
                style: AppTheme.captionStyle,
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spacingM),
          // Vertical divider
          Container(
            width: 2,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          // Subject & info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subject, style: AppTheme.subheadingStyle),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 13, color: AppTheme.subtleText),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        entry.professor,
                        style: AppTheme.captionStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Room badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              entry.room,
              style: AppTheme.captionStyle.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
