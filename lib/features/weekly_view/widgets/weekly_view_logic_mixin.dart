import 'package:flutter/material.dart';
import 'package:ruby/core/models/chat_message.dart';
import 'package:ruby/core/models/task.dart';
import 'package:ruby/core/theme/ruby_theme.dart';
import 'package:ruby/features/task_management/controllers/task_controller.dart';
import 'package:ruby/features/task_migration/controllers/migration_controller.dart';
import 'package:ruby/features/weekly_view/controllers/weekly_view_controller.dart';
import 'package:ruby/core/services/chat_history_service.dart';

mixin WeeklyViewLogicMixin<T extends StatefulWidget> on State<T> {
  final WeeklyViewController weeklyViewController = WeeklyViewController();
  final TaskController taskController = TaskController();
  final MigrationController migrationController = MigrationController();

  final Map<String, List<ChatMessage>> chatHistory = {};
  final Map<String, ScrollController> dayScrollControllers = {};

  Future<void> initializeData() async {
    final dateKeys = weeklyViewController.currentWeekDates
        .map((date) => weeklyViewController.getDateKey(date))
        .toList();
    taskController.initializeTasksForDates(dateKeys);

    for (final dateKey in dateKeys) {
      chatHistory[dateKey] = [];
      dayScrollControllers[dateKey] = ScrollController();
    }

    await taskController.loadTasks();

    // Generate chat history for existing tasks
    await migrationController.generateHistoryForExistingTasks(
      taskController.tasks,
    );

    await loadAllChatHistory();

    await migrationController.migrateIncompleteTasksFromPreviousWeek(
      taskController.tasks,
      weeklyViewController.currentWeekDates,
    );
  }

  Future<void> loadChatHistoryForDay(String dateKey) async {
    final history = await ChatHistoryService.getChatHistoryForDay(dateKey);
    if (mounted) {
      setState(() {
        chatHistory[dateKey] = history.reversed.toList();
      });
    }
  }

  Future<void> loadAllChatHistory() async {
    for (final date in weeklyViewController.currentWeekDates) {
      final dateKey = weeklyViewController.getDateKey(date);
      await loadChatHistoryForDay(dateKey);
    }
  }

  void addTaskToCurrentDay(String taskText, List<String> tags, {String? selectedTag}) {
    final currentDateKey = weeklyViewController.getCurrentDateKey();
    // Merge provided tags with selected filter tag
    final allTags = <String>{...tags};
    if (selectedTag != null) allTags.add(selectedTag);
    
    taskController.addTask(currentDateKey, taskText, tags: allTags.toList());
    loadChatHistoryForDay(currentDateKey);
  }

  void addTaskToDay(String dateKey, String taskText, {String? selectedTag}) {
    // Always add to the specific day requested.
    // This ensures historical data is preserved as intended by the user.
    taskController.addTask(dateKey, taskText, tags: selectedTag != null ? [selectedTag] : null);
    loadChatHistoryForDay(dateKey);
  }

  void toggleTaskCompletion(String taskId) {
    String? taskDateKey;
    for (var entry in taskController.tasks.entries) {
      if (entry.value.any((t) => t.id == taskId)) {
        taskDateKey = entry.key;
        break;
      }
    }

    if (taskDateKey != null) {
      taskController.toggleTaskCompletion(taskDateKey, taskId);
      loadChatHistoryForDay(taskDateKey);
    }
  }

  void deleteTask(String taskId) {
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

  void restoreTask(String taskId) {
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

  void addVoiceTaskToCurrentDay(
    String audioPath,
    List<double>? waveformData,
    List<String> tags, [
    String? selectedTag,
  ]) {
    if (audioPath.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = weeklyViewController.getDateKey(today);

    // Merge provided tags with selected filter tag
    final allTags = <String>{...tags};
    if (selectedTag != null) allTags.add(selectedTag);

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'تسجيل صوتي',
      createdAt: DateTime.now(),
      dayOfWeek: dateKey,
      audioPath: audioPath,
      waveformData: waveformData,
      tags: allTags.toList(),
    );

    taskController.addTaskObject(dateKey, task);
    loadChatHistoryForDay(dateKey);
  }

  void restoreTaskFromHistory(ChatMessage message) {
    if (message.taskId != null && message.metadata?['dayKey'] != null) {
      final dayKey = message.metadata!['dayKey'] as String;
      taskController.restoreTask(dayKey, message.taskId!);
      loadChatHistoryForDay(dayKey);
    }
  }

  int getUnfinishedTasksInPastDaysCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int count = 0;

    for (DateTime date in weeklyViewController.currentWeekDates) {
      if (date.isAfter(today) || weeklyViewController.isToday(date)) {
        continue;
      }

      final dateKey = weeklyViewController.getDateKey(date);
      final dayTasks = taskController.getVisibleTasksForDate(dateKey);
      count += dayTasks.where((task) => !task.isCompleted).length;
    }

    return count;
  }

  Future<void> migrateUnfinishedTasksToToday() async {
    await migrationController.migrateUnfinishedTasksToToday(
      taskController.tasks,
      weeklyViewController.currentWeekDates,
    );

    if (mounted) {
      final unfinishedCount = taskController.getUnfinishedTasksCount(
        weeklyViewController.getCurrentDateKey(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم نقل $unfinishedCount مهمة غير مكتملة إلى النهاردة',
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
        ),
      );
    }
  }
}
