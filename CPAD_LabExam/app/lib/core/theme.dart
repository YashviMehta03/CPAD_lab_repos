import 'package:flutter/material.dart';

class AppColors {
  static const brand = Color(0xFF3949AB);
  static const student = Color(0xFF3949AB);
  static const professor = Color(0xFF00796B);
  static const admin = Color(0xFF6D4C41);
}

Color roleColor(String role) => switch (role) {
      'professor' => AppColors.professor,
      'admin' => AppColors.admin,
      _ => AppColors.student,
    };

ThemeData buildTheme(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFF6F7FB) : scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: brightness == Brightness.light ? const Color(0xFFF6F7FB) : scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: const ChipThemeData(side: BorderSide.none),
  );
}

/// Professor availability states.
class StatusStyle {
  const StatusStyle(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

const statusStyles = {
  'in_cabin': StatusStyle('In cabin', Color(0xFF2E7D32), Icons.meeting_room_outlined),
  'in_class': StatusStyle('In class', Color(0xFF1565C0), Icons.co_present_outlined),
  'busy': StatusStyle('Busy', Color(0xFFEF6C00), Icons.do_not_disturb_on_outlined),
  'away': StatusStyle('Away', Color(0xFF757575), Icons.directions_walk),
  'out_of_college': StatusStyle('Out of college', Color(0xFF455A64), Icons.home_outlined),
  'on_leave': StatusStyle('On leave', Color(0xFFC62828), Icons.event_busy_outlined),
};

const ticketStatusStyles = {
  'open': StatusStyle('Open', Color(0xFF1565C0), Icons.radio_button_unchecked),
  'in_progress': StatusStyle('In progress', Color(0xFFEF6C00), Icons.timelapse),
  'resolved': StatusStyle('Resolved', Color(0xFF2E7D32), Icons.check_circle_outline),
  'rejected': StatusStyle('Rejected', Color(0xFF757575), Icons.block),
};

const meetingStatusStyles = {
  'pending': StatusStyle('Pending', Color(0xFF1565C0), Icons.hourglass_empty),
  'accepted': StatusStyle('Accepted', Color(0xFF2E7D32), Icons.check_circle_outline),
  'rejected': StatusStyle('Rejected', Color(0xFFC62828), Icons.cancel_outlined),
  'suggested': StatusStyle('New time suggested', Color(0xFFEF6C00), Icons.schedule),
  'cancelled': StatusStyle('Cancelled', Color(0xFF757575), Icons.block),
};
