import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Event Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header with Stack for category badge
            Stack(
              children: [
                // Background gradient header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  margin: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _categoryColor,
                        _categoryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: _categoryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusL),
                        ),
                        child: Icon(
                          event.icon,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        event.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      // Date, time, location in Rows
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            event.date,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          const Icon(Icons.access_time_outlined,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            event.time,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category badge overlay — Stack Positioned
                Positioned(
                  top: AppTheme.spacingM + AppTheme.spacingM,
                  right: AppTheme.spacingM + AppTheme.spacingM,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // About section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: AppTheme.headingStyle),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Text(
                      event.description,
                      style: AppTheme.bodyStyle.copyWith(height: 1.6),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _categoryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingM),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusL),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.how_to_reg_rounded),
                      label: const Text(
                        'Register for Event',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Registration will be available soon!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
