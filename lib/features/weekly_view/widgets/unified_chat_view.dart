import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../core/models/task.dart';
import '../../../../presentation/widgets/task_bubble.dart';
import '../../../../responsive.dart';
import '../../../../presentation/widgets/date_separator.dart';

class UnifiedChatView extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task, String) onTaskTap;
  final bool hasActiveFilters;
  final VoidCallback? onResetFilters;

  const UnifiedChatView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    this.hasActiveFilters = false,
    this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    // If no tasks, show empty state
    if (tasks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.xlarge)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasActiveFilters
                    ? Icons.filter_alt_off
                    : Icons.task_alt_rounded,
                size: Responsive.text(context, size: TextSize.heading) * 3,
                color: RubyTheme.mediumGray.withOpacity(0.3),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                hasActiveFilters
                    ? 'مفيش تاسكات تطابق الفلاتر'
                    : 'ابدأ بإضافة مهمتك الأولى',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w500,
                  color: RubyTheme.mediumGray,
                ),
              ),
              if (hasActiveFilters && onResetFilters != null) ...[
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                ElevatedButton.icon(
                  onPressed: onResetFilters,
                  icon: Icon(Icons.refresh, size: 20),
                  label: Text('إعادة تعيين الفلاتر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RubyTheme.sapphire,
                    foregroundColor: RubyTheme.pureWhite,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.large),
                      vertical: Responsive.space(context, size: Space.medium),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Group tasks by their storage date (dayOfWeek field)
    final Map<String, List<Task>> groupedByDate = {};
    for (var task in tasks) {
      // Use the task's scheduled dayOfWeek, which is the date key
      final itemDateKey = task.dayOfWeek;
      groupedByDate.putIfAbsent(itemDateKey, () => []);
      groupedByDate[itemDateKey]!.add(task);
    }

    // Sort date keys in descending order (newest to oldest)
    final sortedDateKeys = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      reverse: true, // Normal order - today at bottom, swipe up for older
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
        bottom: Responsive.space(context, size: Space.small),
      ),
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupDateKey = sortedDateKeys[groupIndex];
        final groupTasks = groupedByDate[groupDateKey]!;

        // Sort tasks within the group by creation time (oldest to newest)
        groupTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Safely parse groupDateKey - it might be in Arabic format or invalid
        DateTime groupDate;
        try {
          groupDate = DateTime.parse(groupDateKey);
        } catch (e) {
          // If parsing fails (e.g., Arabic day name like "الجمعة"), use today's date
          groupDate = today;
        }

        final isToday =
            DateTime(groupDate.year, groupDate.month, groupDate.day) == today;

        return Column(
          children: [
            // Date separator (WhatsApp-style)
            DateSeparator(dateKey: groupDateKey),

            // Tasks for this date
            ...groupTasks.map((task) {
              return TaskBubble(
                task: task,
                isToday: isToday,
                onTap: () => onTaskTap(task, groupDateKey),
              );
            }),
          ],
        );
      },
    );
  }
}
