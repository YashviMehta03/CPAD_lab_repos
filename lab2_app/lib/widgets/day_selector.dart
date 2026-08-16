import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DaySelector extends StatelessWidget {
  final List<String> days;
  final String selectedDay;
  final ValueChanged<String> onDaySelected;

  const DaySelector({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          final isSelected = day == selectedDay;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingS),
            child: GestureDetector(
              onTap: () => onDaySelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor,
                  ),
                  boxShadow: isSelected ? AppTheme.cardShadow : null,
                ),
                child: Text(
                  day,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.subtleText,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
