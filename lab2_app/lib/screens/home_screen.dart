import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/feature_card.dart';
import '../widgets/today_classes_card.dart';
import 'timetable_screen.dart';
import 'professors_screen.dart';
import 'events_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: AppTheme.spacingS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(), style: AppTheme.labelStyle),
                  const SizedBox(height: 4),
                  Text('Campus Companion', style: AppTheme.displayStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppTheme.subtleText),
                      const SizedBox(width: 4),
                      Text(_formattedDate(), style: AppTheme.captionStyle),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayClasses(BuildContext context) {
    return TodayClassesCard(
      classes: MockData.todayClasses,
      onViewTimetable: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimetableScreen()),
        );
      },
    );
  }

  Widget _buildFeaturesHeading() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Features', style: AppTheme.headingStyle),
        Text('LY Computer Engineering', style: AppTheme.captionStyle),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return GridView.count(
          crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTheme.spacingM,
          mainAxisSpacing: AppTheme.spacingM,
          childAspectRatio: 0.85,
          children: [
            FeatureCard(
              icon: Icons.schedule_rounded,
              title: 'Timetable',
              subtitle: 'View your weekly class schedule',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimetableScreen()),
              ),
            ),
            FeatureCard(
              icon: Icons.school_rounded,
              title: 'Professors',
              subtitle: 'Browse professors and their subjects',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessorsScreen()),
              ),
            ),
            FeatureCard(
              icon: Icons.event_rounded,
              title: 'Events',
              subtitle: 'See upcoming campus events',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventsScreen()),
              ),
            ),
            FeatureCard(
              icon: Icons.calendar_month_rounded,
              title: 'Academic Calendar',
              subtitle: 'View holidays and important dates',
              isComingSoon: true,
              onTap: () => _showComingSoon(context, 'Academic Calendar'),
            ),
            FeatureCard(
              icon: Icons.search_rounded,
              title: 'Lost & Found',
              subtitle: 'Find or report lost items',
              isComingSoon: true,
              onTap: () => _showComingSoon(context, 'Lost & Found'),
            ),
            FeatureCard(
              icon: Icons.campaign_rounded,
              title: 'Announcements',
              subtitle: 'View important campus updates',
              isComingSoon: true,
              onTap: () => _showComingSoon(context, 'Announcements'),
            ),
          ],
        );
      },
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppTheme.spacingL),
          _buildTodayClasses(context),
          const SizedBox(height: AppTheme.spacingL),
          _buildFeaturesHeading(),
          const SizedBox(height: AppTheme.spacingM),
          _buildFeaturesGrid(context),
          const SizedBox(height: AppTheme.spacingL),
        ],
      ),
    );
  }

  Widget _tabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppTheme.spacingL),
                _buildTodayClasses(context),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeaturesHeading(),
                const SizedBox(height: AppTheme.spacingM),
                _buildFeaturesGrid(context),
                const SizedBox(height: AppTheme.spacingL),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return _tabletLayout(context);
            } else {
              return _mobileLayout(context);
            }
          },
        ),
      ),
    );
  }
}
