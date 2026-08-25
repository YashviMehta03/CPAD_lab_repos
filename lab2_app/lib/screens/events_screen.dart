import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.onSurfaceColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Event> events = MockData.events;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Upcoming Events'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildCategoryChip('All', true),
                    _buildCategoryChip('Technical', false),
                    _buildCategoryChip('Cultural', false),
                    _buildCategoryChip('Sports', false),
                    _buildCategoryChip('Seminars', false),
                    _buildCategoryChip('Workshops', false),
                    _buildCategoryChip('Hackathons', false),
                    _buildCategoryChip('Guest Lectures', false),
                    _buildCategoryChip('Competitions', false),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  '${events.length} upcoming events',
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return EventCard(
                  event: event,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(event: event),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
