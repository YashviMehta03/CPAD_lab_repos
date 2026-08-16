import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/class_card.dart';
import '../widgets/day_selector.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const List<String> _days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    // Default to current weekday, falling back to MON on weekends
    final weekday = DateTime.now().weekday; // 1=Mon … 5=Fri, 6=Sat, 7=Sun
    _selectedDay = weekday <= 5 ? _days[weekday - 1] : 'MON';
  }

  @override
  Widget build(BuildContext context) {
    final classes = MockData.getClassesForDay(_selectedDay);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Timetable'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined,
                    color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'LY Computer Engineering',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${classes.length} ${classes.length == 1 ? 'class' : 'classes'}',
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Day selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: DaySelector(
              days: _days,
              selectedDay: _selectedDay,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Class list
          Expanded(
            child: classes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.free_breakfast_outlined,
                            size: 48,
                            color: AppTheme.subtleText.withValues(alpha: 0.5)),
                        const SizedBox(height: AppTheme.spacingM),
                        Text('No classes on $_selectedDay',
                            style: AppTheme.subheadingStyle
                                .copyWith(color: AppTheme.subtleText)),
                        const SizedBox(height: 4),
                        Text('Enjoy the free day!',
                            style: AppTheme.captionStyle),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM),
                    itemCount: classes.length,
                    itemBuilder: (_, i) => ClassCard(entry: classes[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
