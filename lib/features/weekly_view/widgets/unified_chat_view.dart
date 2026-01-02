import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../core/models/task.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../presentation/widgets/task_bubble.dart';
import '../../../../responsive.dart';
import '../../../../presentation/widgets/date_separator.dart';

class UnifiedChatView extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task, String) onTaskTap;
  final Function(String) onTaskLongPress;

  const UnifiedChatView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskLongPress,
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
                Icons.task_alt_rounded,
                size: Responsive.text(context, size: TextSize.heading) * 3,
                color: RubyTheme.mediumGray.withOpacity(0.3),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'ابدأ بإضافة مهمتك الأولى',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w500,
                  color: RubyTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group tasks by their creation date
    final Map<String, List<Task>> groupedByDate = {};
    for (var task in tasks) {
      final itemDateKey = DateFormatter.getDateKey(task.createdAt);
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
        final groupDate = DateTime.parse(groupDateKey);
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
                onLongPress: () => onTaskLongPress(task.id),
              );
            }),
          ],
        );
      },
    );
  }
}
