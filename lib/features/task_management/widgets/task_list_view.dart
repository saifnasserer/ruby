import 'package:flutter/material.dart';
import '../../../../core/models/task.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../presentation/widgets/task_bubble.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final bool isToday;
  final String displayText;
  final Function(String) onTaskTap;
  final Function(String) onTaskLongPress;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.isToday,
    required this.displayText,
    required this.onTaskTap,
    required this.onTaskLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: tasks.isEmpty
          ? // Empty state
            Container(
              padding: EdgeInsets.all(RubyTheme.spacingXXL(context)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayText,
                      style: RubyTheme.heading2(
                        context,
                      ).copyWith(color: RubyTheme.charcoal),
                    ),
                    SizedBox(height: RubyTheme.spacingS(context)),
                    Text(
                      'مفيش تاسكات النهارده',
                      style: RubyTheme.bodyLarge(
                        context,
                      ).copyWith(color: RubyTheme.mediumGray),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                top: RubyTheme.spacingM(context),
                bottom: RubyTheme.spacingS(context),
              ),
              itemCount: tasks.length,
              itemBuilder: (context, taskIndex) {
                final task = tasks[taskIndex];
                return TaskBubble(
                  task: task,
                  isToday: isToday,
                  onTap: () => onTaskTap(task.id),
                  onLongPress: () => onTaskLongPress(task.id),
                );
              },
            ),
    );
  }
}







