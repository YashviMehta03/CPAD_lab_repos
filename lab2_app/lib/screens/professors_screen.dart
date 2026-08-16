import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/professor.dart';
import '../widgets/professor_card.dart';
import 'professor_detail_screen.dart';

class ProfessorsScreen extends StatelessWidget {
  const ProfessorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Professor> professors = MockData.professors;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Professors'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
            child: Text(
              '${professors.length} faculty members',
              style: AppTheme.captionStyle,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
              itemCount: professors.length,
              itemBuilder: (context, index) {
                final prof = professors[index];
                return ProfessorCard(
                  professor: prof,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfessorDetailScreen(professor: prof),
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
