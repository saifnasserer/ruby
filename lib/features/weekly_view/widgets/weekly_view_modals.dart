import 'package:flutter/material.dart';
import '../../../../core/models/task.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../task_management/widgets/task_options_modal.dart';
import '../../task_management/widgets/task_detail_modal.dart';
import '../../task_management/widgets/move_task_modal.dart';
import '../controllers/weekly_view_controller.dart';
import '../../task_management/controllers/task_controller.dart';

class WeeklyViewModals {
  static void showTaskOptions(
    BuildContext context, {
    required String taskId,
    required Task task,
    required VoidCallback onDelete,
    required Function(Task) onEdit,
    required Function(Task) onChangePriority,
    required Function(Task) onMove,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskOptionsModal(
        onDelete: onDelete,
        onEdit: () => onEdit(task),
        onChangePriority: () => onChangePriority(task),
        onManageCategory: () => onEdit(task),
        onMove: () => onMove(task),
      ),
    );
  }

  static void showTaskDetailModal(
    BuildContext context, {
    required Task task,
    required String currentDateKey,
    required TaskController taskController,
    required Function(String) onLoadHistory,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TaskDetailModal(
          task: task,
          onTextChanged: (newText) {
            taskController.editTask(currentDateKey, task.id, newText);
            onLoadHistory(currentDateKey);
          },
          onPriorityChanged: (priority) {
            taskController.updateTaskPriority(
              currentDateKey,
              task.id,
              priority,
            );
            onLoadHistory(currentDateKey);
          },
          onCategoryChanged: (category) {
            taskController.updateTaskCategory(
              currentDateKey,
              task.id,
              category,
            );
            onLoadHistory(currentDateKey);
          },
          onTagsChanged: (tags) {
            taskController.updateTaskTags(currentDateKey, task.id, tags);
          },
          onDeadlineChanged: (deadline) {
            taskController.updateTaskDeadline(
              currentDateKey,
              task.id,
              deadline,
            );
            onLoadHistory(currentDateKey);
          },
        ),
      ),
    );
  }

  static void showPrioritySelector(
    BuildContext context, {
    required Task task,
    required String currentDateKey,
    required TaskController taskController,
    required Function(String) onLoadHistory,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغيير الأولوية', style: RubyTheme.heading2(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskPriority.values.map((priority) {
            return ListTile(
              title: Text(priority.displayName),
              leading: Radio<TaskPriority>(
                value: priority,
                groupValue: task.priority,
                onChanged: (value) {
                  if (value != null) {
                    taskController.updateTaskPriority(
                      currentDateKey,
                      task.id,
                      value,
                    );
                    onLoadHistory(currentDateKey);
                    Navigator.pop(context);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static void showMoveTaskModal(
    BuildContext context, {
    required Task task,
    required String currentDateKey,
    required WeeklyViewController weeklyViewController,
    required TaskController taskController,
    required Function(String) onLoadHistory,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MoveTaskModal(
        weekDates: weeklyViewController.currentWeekDates,
        currentDateKey: currentDateKey,
        getDateKey: weeklyViewController.getDateKey,
        getDateDisplayText: weeklyViewController.getDateDisplayText,
        onDateSelected: (newDateKey) {
          taskController.moveTask(currentDateKey, newDateKey, task.id);
          onLoadHistory(currentDateKey);
          onLoadHistory(newDateKey);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم نقل التاسك بنجاح',
                style: RubyTheme.bodyMedium(
                  context,
                ).copyWith(color: RubyTheme.pureWhite),
              ),
              backgroundColor: RubyTheme.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  RubyTheme.radiusMedium(context),
                ),
              ),
              margin: EdgeInsets.all(RubyTheme.spacingM(context)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  static void showRestoreDialog(
    BuildContext context, {
    required ChatMessage message,
    required Function(ChatMessage) onRestore,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('استعادة التاسك', style: RubyTheme.heading2(context)),
        content: Text(
          'هل تريد استعادة التاسك "${message.taskText}"؟',
          style: RubyTheme.bodyLarge(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: RubyTheme.bodyMedium(
                context,
              ).copyWith(color: RubyTheme.mediumGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRestore(message);
            },
            child: Text(
              'استعادة',
              style: RubyTheme.bodyMedium(
                context,
              ).copyWith(color: RubyTheme.emerald, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
