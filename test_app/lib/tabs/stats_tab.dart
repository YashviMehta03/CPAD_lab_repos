import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class StatsTab extends StatelessWidget {
  final String groupId;

  const StatsTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final breakdown = expenseProvider.getCategoryBreakdown(groupId);
    final expenses = expenseProvider.getGroupExpenses(groupId);
    final timelineData = expenses.reversed.toList(); // chronological

    if (expenses.isEmpty) {
      return const Center(
        child: Text('No expenses to analyze.', style: TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spend by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          if (breakdown.isNotEmpty) _buildPieChart(breakdown),
          const SizedBox(height: 40),
          const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _buildTimeline(timelineData, context),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> breakdown) {
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.warning,
      AppTheme.negative,
      AppTheme.positive,
    ];
    int colorIndex = 0;
    
    final sections = breakdown.entries.map((e) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: e.value,
        title: '${e.key}\n₹${e.value.toStringAsFixed(0)}',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildTimeline(List expenses, BuildContext context) {
    return Column(
      children: expenses.map((expense) {
        final isSettlement = expense.isSettlement;
        final icon = isSettlement ? Icons.handshake : Icons.receipt_long;
        final color = isSettlement ? AppTheme.positive : Theme.of(context).colorScheme.primary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    width: 2,
                    height: 30, // Connects to next item loosely
                    color: Theme.of(context).dividerColor,
                  )
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(expense.date),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSettlement ? AppTheme.positive : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
