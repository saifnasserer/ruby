import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../core/models/task.dart';
import '../../../core/models/chat_message.dart';
import '../../task_management/widgets/task_options_modal.dart';
import '../../task_management/widgets/task_detail_modal.dart';
import '../../task_management/widgets/move_task_modal.dart';
import '../../task_management/controllers/task_controller.dart';
import '../controllers/weekly_view_controller.dart';

/// Mixin for handling modal dialogs
mixin ModalHandlersMixin on State {
  // These will be provided by the main widget
  TaskController get taskController;
  WeeklyViewController get weeklyViewController;

  // Methods to be implemented by main widget
  void deleteTask(String taskId);
  void loadChatHistoryForDay(String dateKey);
  Task? findTaskById(String taskId);

  /// Show task options modal
  void showTaskOptions(String taskId) {
    final task = findTaskById(taskId);

    if (task == null || task.id.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskOptionsModal(
        onDelete: () => deleteTask(taskId),
        onEdit: () => showTaskDetailModal(task),
        onChangePriority: () => showPrioritySelector(task),
      ),
    );
  }

  /// Show task detail modal for editing
  void showTaskDetailModal(Task task) {
    final currentDateKey = weeklyViewController.getCurrentDateKey();

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
            loadChatHistoryForDay(currentDateKey);
          },
          onPriorityChanged: (priority) {
            taskController.updateTaskPriority(
              currentDateKey,
              task.id,
              priority,
            );
            loadChatHistoryForDay(currentDateKey);
          },
          onCategoryChanged: (category) {
            taskController.updateTaskCategory(
              currentDateKey,
              task.id,
              category,
            );
            loadChatHistoryForDay(currentDateKey);
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
            loadChatHistoryForDay(currentDateKey);
          },
        ),
      ),
    );
  }

  /// Show priority selector dialog
  void showPrioritySelector(Task task) {
    final currentDateKey = weeklyViewController.getCurrentDateKey();

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
                    loadChatHistoryForDay(currentDateKey);
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

  /// Show move task modal
  void showMoveTaskModal(Task task) {
    final currentDateKey = weeklyViewController.getCurrentDateKey();

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
          loadChatHistoryForDay(currentDateKey);
          loadChatHistoryForDay(newDateKey);

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

  /// Show restore task dialog
  void showRestoreDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('استعادة التاسك', style: RubyTheme.heading2(context)),
            content: Text(
              'هل تريد استعادة هذه التاسك؟',
              style: RubyTheme.bodyMedium(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: RubyTheme.bodyMedium(
                    context,
                  ).copyWith(color: RubyTheme.mediumGray),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (message.taskId != null) {
                    // Find and restore the task
                    for (var entry in taskController.tasks.entries) {
                      if (entry.value.any((t) => t.id == message.taskId)) {
                        taskController.restoreTask(entry.key, message.taskId!);
                        loadChatHistoryForDay(entry.key);
                        break;
                      }
                    }
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RubyTheme.emerald,
                  foregroundColor: RubyTheme.pureWhite,
                ),
                child: Text(
                  'استعادة',
                  style: RubyTheme.bodyMedium(
                    context,
                  ).copyWith(color: RubyTheme.pureWhite),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
