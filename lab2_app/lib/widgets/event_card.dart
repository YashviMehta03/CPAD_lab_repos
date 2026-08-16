import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  Color get _categoryColor {
    switch (event.category) {
      case 'Tech':
        return const Color(0xFF3F51B5);
      case 'Cultural':
        return const Color(0xFFE91E63);
      case 'Hackathon':
        return const Color(0xFF009688);
      case 'Placement':
        return const Color(0xFFFF9800);
      case 'Academic':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: AppTheme.cardShadow,
        ),
        // Stack: card content with category badge overlay
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Icon(
                      event.icon,
                      color: _categoryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  // Event info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Leave room for category badge
                        const SizedBox(height: 2),
                        Text(event.name, style: AppTheme.subheadingStyle),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 13, color: AppTheme.subtleText),
                            const SizedBox(width: 4),
                            Text(event.date, style: AppTheme.captionStyle),
                            const SizedBox(width: AppTheme.spacingM),
                            Icon(Icons.access_time_outlined,
                                size: 13, color: AppTheme.subtleText),
                            const SizedBox(width: 4),
                            Text(event.time, style: AppTheme.captionStyle),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: AppTheme.subtleText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: AppTheme.captionStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: AppTheme.captionStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Category badge — Stack overlay in top-right corner
            Positioned(
              top: AppTheme.spacingM,
              right: AppTheme.spacingM,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
