import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/models/task.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/chat_history_service.dart';

class MigrationController extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// Generate chat history for existing tasks
  Future<void> generateHistoryForExistingTasks(
    Map<String, List<Task>> tasks,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ChatHistoryService.generateHistoryForExistingTasks(tasks);
    } catch (e) {
      print('Error generating history for existing tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Migrate incomplete tasks from previous week to current Saturday
  Future<void> migrateIncompleteTasksFromPreviousWeek(
    Map<String, List<Task>> tasks,
    List<DateTime> currentWeekDates,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if migration has already been done for this week
      final lastMigration = await StorageService.getLastMigrationWeekAsync();
      final currentWeekKey = _getWeekKey(today);

      if (lastMigration == currentWeekKey) {
        print(
          'Migration: Already migrated for this week ($currentWeekKey), skipping',
        );
        return;
      }

      // Only migrate on Saturday (weekday 6 in Dart) or when app opens and it's a new week
      final isSaturday =
          today.weekday == 6; // Saturday in Dart's weekday system
      final isNewWeek = lastMigration != currentWeekKey;

      if (!isSaturday && !isNewWeek) {
        print('Migration: Not Saturday and not a new week, skipping migration');
        return;
      }

      // Get current Saturday (first day of the week)
      final currentSaturday = currentWeekDates.first;
      final currentSaturdayKey = _getDateKey(currentSaturday);

      // Get previous week dates
      final previousWeekDates = _getPreviousWeekDates(today);

      // Collect all incomplete tasks from previous week
      final List<Task> allIncompleteTasks = [];
      for (DateTime weekDate in previousWeekDates) {
        final dateKey = _getDateKey(weekDate);
        final dayTasks = tasks[dateKey] ?? [];

        final incompleteTasks = dayTasks
            .where((task) => !task.isCompleted && !task.isDeleted)
            .toList();
        allIncompleteTasks.addAll(incompleteTasks);

        print(
          'Migration: Found ${incompleteTasks.length} incomplete tasks in $dateKey',
        );
      }

      if (allIncompleteTasks.isNotEmpty) {
        // Move all incomplete tasks to current Saturday
        for (final task in allIncompleteTasks) {
          final migratedTask = task.copyWith(
            dayOfWeek: currentSaturdayKey,
            isMigrated: true,
            originalDayOfWeek: task.dayOfWeek,
          );

          // Add to current Saturday
          tasks[currentSaturdayKey] = tasks[currentSaturdayKey] ?? [];
          tasks[currentSaturdayKey]!.add(migratedTask);

          // Add chat message for task migration
          ChatHistoryService.addMessage(
            ChatHistoryService.createTaskMigratedMessage(
              taskId: task.id,
              taskText: task.text,
              fromDay: task.dayOfWeek,
              toDay: currentSaturdayKey,
            ),
          );
        }

        // Remove all incomplete tasks from previous week
        for (DateTime weekDate in previousWeekDates) {
          final dateKey = _getDateKey(weekDate);
          if (tasks[dateKey] != null) {
            final beforeCount = tasks[dateKey]!.length;
            tasks[dateKey]!.removeWhere((task) => !task.isCompleted);
            final afterCount = tasks[dateKey]!.length;
            print(
              'Migration: Removed ${beforeCount - afterCount} incomplete tasks from $dateKey',
            );
          }
        }

        print(
          'Migration: Moved ${allIncompleteTasks.length} tasks to current Saturday ($currentSaturdayKey)',
        );
      } else {
        print('Migration: No incomplete tasks found in previous week');
      }

      // Mark this week as migrated
      await StorageService.setLastMigrationWeek(currentWeekKey);

      // Save the migrated tasks
      await StorageService.saveTasks(tasks);

      // Add weekly summary message
      if (allIncompleteTasks.isNotEmpty) {
        final totalTasks = allIncompleteTasks.length;
        final migratedTasks = allIncompleteTasks.length;
        ChatHistoryService.addMessage(
          ChatHistoryService.createWeekSummaryMessage(
            completedTasks: 0, // We don't track completed tasks in migration
            totalTasks: totalTasks,
            migratedTasks: migratedTasks,
          ),
        );
      }
    } catch (e) {
      print('Error during migration: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Migrate unfinished tasks to today
  Future<void> migrateUnfinishedTasksToToday(
    Map<String, List<Task>> tasks,
    List<DateTime> currentWeekDates,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey = _getDateKey(today);

      // Find today's index in current week dates
      final todayIndex = currentWeekDates.indexWhere(
        (date) => _getDateKey(date) == todayKey,
      );
      if (todayIndex == -1) {
        print('Migration: Today not found in current week dates');
        return;
      }

      // Get unfinished tasks from past days (excluding today)
      final List<Task> unfinishedTasks = [];
      for (int i = 0; i < todayIndex; i++) {
        final date = currentWeekDates[i];
        final dateKey = _getDateKey(date);
        final dayTasks = tasks[dateKey] ?? [];

        final dayUnfinishedTasks = dayTasks
            .where((task) => !task.isCompleted && !task.isDeleted)
            .toList();
        unfinishedTasks.addAll(dayUnfinishedTasks);
      }

      if (unfinishedTasks.isNotEmpty) {
        // Move unfinished tasks to today
        for (final task in unfinishedTasks) {
          final migratedTask = task.copyWith(
            dayOfWeek: todayKey,
            isMigrated: true,
            originalDayOfWeek: task.dayOfWeek,
          );

          // Add to today
          tasks[todayKey] = tasks[todayKey] ?? [];
          tasks[todayKey]!.add(migratedTask);

          // Remove from original day
          final originalDateKey = task.dayOfWeek;
          if (tasks[originalDateKey] != null) {
            tasks[originalDateKey]!.removeWhere((t) => t.id == task.id);
          }

          // Add chat message for task migration
          ChatHistoryService.addMessage(
            ChatHistoryService.createTaskMigratedMessage(
              taskId: task.id,
              taskText: task.text,
              fromDay: task.dayOfWeek,
              toDay: todayKey,
            ),
          );
        }

        // Save the migrated tasks
        await StorageService.saveTasks(tasks);

        print(
          'Migration: Moved ${unfinishedTasks.length} unfinished tasks to today ($todayKey)',
        );
      }
    } catch (e) {
      print('Error during migration to today: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekKey(DateTime date) {
    // Calculate week number (Saturday-based week)
    final year = date.year;
    final jan1 = DateTime(year, 1, 1);
    final daysSinceJan1 = date.difference(jan1).inDays;
    final weekNumber = ((daysSinceJan1 + jan1.weekday) / 7).ceil();
    return "$year-W${weekNumber.toString().padLeft(2, '0')}";
  }

  List<DateTime> _getPreviousWeekDates(DateTime currentDate) {
    // Find the Saturday of current week
    final daysToSaturday = (currentDate.weekday + 1) % 7;
    final currentSaturday = currentDate.subtract(
      Duration(days: daysToSaturday),
    );

    // Calculate previous Saturday (7 days before current Saturday)
    final previousSaturday = currentSaturday.subtract(Duration(days: 7));

    // Generate all 7 days of the previous week (Saturday to Friday)
    return List.generate(
      7,
      (index) => previousSaturday.add(Duration(days: index)),
    );
  }
}
