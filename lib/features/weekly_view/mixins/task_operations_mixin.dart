import 'package:flutter/material.dart';
import '../../../core/models/task.dart';
import '../../task_management/controllers/task_controller.dart';
import '../controllers/weekly_view_controller.dart';

/// Mixin for task-related operations (CRUD)
mixin TaskOperationsMixin on State {
  // These will be provided by the main widget
  TaskController get taskController;
  WeeklyViewController get weeklyViewController;

  // Method to reload chat history (to be implemented by main widget)
  void loadChatHistoryForDay(String dateKey);

  /// Toggle task completion status
  void toggleTaskCompletion(String taskId) {
    // Find the task in any day (since we have unified view)
    String? taskDateKey;
    Task? foundTask;

    for (var entry in taskController.tasks.entries) {
      final task = entry.value.firstWhere(
        (t) => t.id == taskId,
        orElse: () =>
            Task(id: '', text: '', createdAt: DateTime.now(), dayOfWeek: ''),
      );

      if (task.id.isNotEmpty) {
        taskDateKey = entry.key;
        foundTask = task;
        break;
      }
    }

    if (taskDateKey != null && foundTask != null) {
      taskController.toggleTaskCompletion(taskDateKey, taskId);
      loadChatHistoryForDay(taskDateKey);
    }
  }

  /// Delete a task
  void deleteTask(String taskId) {
    // Find the task in any day
    String? taskDateKey;

    for (var entry in taskController.tasks.entries) {
      if (entry.value.any((t) => t.id == taskId)) {
        taskDateKey = entry.key;
        break;
      }
    }

    if (taskDateKey != null) {
      taskController.deleteTask(taskDateKey, taskId);
      loadChatHistoryForDay(taskDateKey);
    }
  }

  /// Restore a deleted task
  void restoreTask(String taskId) {
    // Find the task in any day
    String? taskDateKey;

    for (var entry in taskController.tasks.entries) {
      if (entry.value.any((t) => t.id == taskId)) {
        taskDateKey = entry.key;
        break;
      }
    }

    if (taskDateKey != null) {
      taskController.restoreTask(taskDateKey, taskId);
      loadChatHistoryForDay(taskDateKey);
    }
  }

  /// Add task to current day
  void addTaskToCurrentDay(String taskText) {
    final currentDateKey = weeklyViewController.getCurrentDateKey();
    taskController.addTask(currentDateKey, taskText);

    // Reload chat history to show the new task immediately
    loadChatHistoryForDay(currentDateKey);
  }

  /// Add task to a specific day (schedules to next occurrence if day is in the past)
  void addTaskToDay(String dateKey, String taskText, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Parse the dateKey to check if it's in the past
    final dateParts = dateKey.split('-');
    final targetDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    if (targetDate.isBefore(today)) {
      // Calculate next occurrence of this weekday
      final targetWeekday = targetDate.weekday;
      final daysUntilNext = (targetWeekday - today.weekday + 7) % 7;
      final nextOccurrence = daysUntilNext == 0
          ? today.add(const Duration(days: 7))
          : today.add(Duration(days: daysUntilNext));

      final nextDateKey = weeklyViewController.getDateKey(nextOccurrence);
      taskController.addTask(nextDateKey, taskText);

      // Reload chat history for the scheduled date
      loadChatHistoryForDay(nextDateKey);

      // Show a message to user about the scheduled date
      if (context.mounted) {
        final arabicWeekdays = [
          'الإثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة',
          'السبت',
          'الأحد',
        ];
        final dayName = arabicWeekdays[targetWeekday % 7];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم جدولة التاسك ل$dayName ${nextOccurrence.day}/${nextOccurrence.month}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Day is today or in the future, add normally
      taskController.addTask(dateKey, taskText);

      // Reload chat history for the current date
      loadChatHistoryForDay(dateKey);
    }
  }

  /// Find a task by ID across all days
  Task? findTaskById(String taskId) {
    for (var entry in taskController.tasks.entries) {
      final foundTask = entry.value.firstWhere(
        (t) => t.id == taskId,
        orElse: () =>
            Task(id: '', text: '', createdAt: DateTime.now(), dayOfWeek: ''),
      );

      if (foundTask.id.isNotEmpty) {
        return foundTask;
      }
    }
    return null;
  }
}
