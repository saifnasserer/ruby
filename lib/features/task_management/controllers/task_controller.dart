import 'package:flutter/material.dart';
import '../../../../core/models/task.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/chat_history_service.dart';
import '../../../../core/services/sound_service.dart';

class TaskController extends ChangeNotifier {
  Map<String, List<Task>> _tasks = {};

  Map<String, List<Task>> get tasks => _tasks;

  /// Add a new task
  void addTask(String dateKey, String taskText) {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: taskText,
      createdAt: DateTime.now(),
      dayOfWeek: dateKey,
    );

    _tasks[dateKey] = _tasks[dateKey] ?? [];
    _tasks[dateKey]!.add(task);

    // Add chat message for task creation
    ChatHistoryService.addMessage(
      ChatHistoryService.createTaskCreatedMessage(
        taskId: task.id,
        taskText: taskText,
        dayKey: dateKey,
      ),
    );

    // Save tasks after adding
    _saveTasks();
    notifyListeners();
  }

  /// Add a full task object
  void addTaskObject(String dateKey, Task task) {
    _tasks[dateKey] = _tasks[dateKey] ?? [];
    _tasks[dateKey]!.add(task);

    // Add chat message for task creation
    ChatHistoryService.addMessage(
      ChatHistoryService.createTaskCreatedMessage(
        taskId: task.id,
        taskText: task.text,
        dayKey: dateKey,
        metadata: task.audioPath != null ? {'audioPath': task.audioPath} : null,
      ),
    );

    // Save tasks after adding
    _saveTasks();
    notifyListeners();
  }

  /// Toggle task completion
  void toggleTaskCompletion(String dateKey, String taskId) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];
        final wasCompleted = task.isCompleted;

        dayTasks[taskIndex] = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );

        // Add chat message for task completion/uncompletion
        if (!wasCompleted) {
          // Task was completed - play completion sound
          SoundService.instance.playTaskCompletionSound();

          ChatHistoryService.addMessage(
            ChatHistoryService.createTaskCompletedMessage(
              taskId: taskId,
              taskText: task.text,
              dayKey: dateKey,
            ),
          );
        } else {
          // Task was uncompleted
          ChatHistoryService.addMessage(
            ChatHistoryService.createTaskUncompletedMessage(
              taskId: taskId,
              taskText: task.text,
              dayKey: dateKey,
            ),
          );
        }
      }
    }

    // Save tasks after toggling
    _saveTasks();
    notifyListeners();
  }

  /// Delete a task (mark as deleted)
  void deleteTask(String dateKey, String taskId) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];

        // Add chat message for task deletion before removing
        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskDeletedMessage(
            taskId: taskId,
            taskText: task.text,
            dayKey: dateKey,
          ),
        );

        // Mark task as deleted instead of removing completely
        dayTasks[taskIndex] = task.copyWith(
          isDeleted: true,
          deletedAt: DateTime.now(),
        );
      }
    }

    // Save tasks after deleting
    _saveTasks();
    notifyListeners();
  }

  /// Restore a deleted task
  void restoreTask(String dateKey, String taskId) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];
        dayTasks[taskIndex] = task.copyWith(isDeleted: false, deletedAt: null);

        // Add chat message for task restoration
        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskRestoredMessage(
            taskId: taskId,
            taskText: task.text,
            dayKey: dateKey,
          ),
        );
      }
    }

    // Save tasks after restoring
    _saveTasks();
    notifyListeners();
  }

  /// Load tasks from storage
  Future<void> loadTasks() async {
    final savedTasks = await StorageService.loadTasks();
    _tasks = savedTasks;
    notifyListeners();
  }

  /// Save tasks to storage
  Future<void> _saveTasks() async {
    await StorageService.saveTasks(_tasks);
  }

  /// Get tasks for a specific date
  List<Task> getTasksForDate(String dateKey) {
    return _tasks[dateKey] ?? [];
  }

  /// Get visible tasks for a specific date (excluding deleted)
  List<Task> getVisibleTasksForDate(String dateKey) {
    return (_tasks[dateKey] ?? []).where((task) => !task.isDeleted).toList();
  }

  /// Get unfinished tasks count for a specific date
  int getUnfinishedTasksCount(String dateKey) {
    final dayTasks = _tasks[dateKey] ?? [];
    return dayTasks
        .where((task) => !task.isCompleted && !task.isDeleted)
        .length;
  }

  /// Get completed tasks count for a specific date
  int getCompletedTasksCount(String dateKey) {
    final dayTasks = _tasks[dateKey] ?? [];
    return dayTasks.where((task) => task.isCompleted && !task.isDeleted).length;
  }

  /// Get total tasks count for a specific date
  int getTotalTasksCount(String dateKey) {
    final dayTasks = _tasks[dateKey] ?? [];
    return dayTasks.where((task) => !task.isDeleted).length;
  }

  /// Check if there are any tasks for a specific date
  bool hasTasksForDate(String dateKey) {
    return getVisibleTasksForDate(dateKey).isNotEmpty;
  }

  /// Initialize tasks for a list of date keys
  void initializeTasksForDates(List<String> dateKeys) {
    for (String dateKey in dateKeys) {
      _tasks[dateKey] = _tasks[dateKey] ?? [];
    }
    notifyListeners();
  }

  /// Update tasks map (for migration purposes)
  void updateTasks(Map<String, List<Task>> newTasks) {
    _tasks = newTasks;
    _saveTasks();
    notifyListeners();
  }

  /// Edit task text
  void editTask(String dateKey, String taskId, String newText) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];
        final oldText = task.text;

        dayTasks[taskIndex] = task.copyWith(
          text: newText,
          updatedAt: DateTime.now(),
        );

        // Add chat message for task edit
        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskEditedMessage(
            taskId: taskId,
            oldText: oldText,
            newText: newText,
            dayKey: dateKey,
          ),
        );
      }
    }

    _saveTasks();
    notifyListeners();
  }

  /// Update task priority
  void updateTaskPriority(
    String dateKey,
    String taskId,
    TaskPriority priority,
  ) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];

        dayTasks[taskIndex] = task.copyWith(
          priority: priority,
          updatedAt: DateTime.now(),
        );

        // Add chat message for priority change
        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskPriorityChangedMessage(
            taskId: taskId,
            taskText: task.text,
            priority: priority,
            dayKey: dateKey,
          ),
        );
      }
    }

    _saveTasks();
    notifyListeners();
  }

  /// Update task subtasks
  void updateTaskSubtasks(
    String dateKey,
    String taskId,
    List<Subtask> subtasks,
  ) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        dayTasks[taskIndex] = dayTasks[taskIndex].copyWith(
          subtasks: subtasks,
          updatedAt: DateTime.now(),
        );

        _saveTasks();
        notifyListeners();
      }
    }
  }

  /// Update task category
  void updateTaskCategory(String dateKey, String taskId, String? category) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];

        dayTasks[taskIndex] = task.copyWith(
          category: category,
          updatedAt: DateTime.now(),
        );

        // Add chat message for category change
        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskCategoryChangedMessage(
            taskId: taskId,
            taskText: task.text,
            category: category,
            dayKey: dateKey,
          ),
        );
      }
    }

    _saveTasks();
    notifyListeners();
  }

  /// Update task tags
  void updateTaskTags(String dateKey, String taskId, List<String> tags) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];

        dayTasks[taskIndex] = task.copyWith(
          tags: tags,
          updatedAt: DateTime.now(),
        );
      }
    }

    _saveTasks();
    notifyListeners();
  }

  /// Update task deadline
  void updateTaskDeadline(String dateKey, String taskId, DateTime? deadline) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];

        dayTasks[taskIndex] = task.copyWith(
          deadlineDate: deadline,
          updatedAt: DateTime.now(),
        );
      }
    }

    _saveTasks();
    notifyListeners();
  }

  /// Move task to another day
  void moveTask(String fromDateKey, String toDateKey, String taskId) {
    final fromDayTasks = _tasks[fromDateKey];
    if (fromDayTasks != null) {
      final taskIndex = fromDayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = fromDayTasks[taskIndex];

        // Remove from original day
        fromDayTasks.removeAt(taskIndex);

        // Add to new day with updated dayOfWeek
        _tasks[toDateKey] = _tasks[toDateKey] ?? [];
        _tasks[toDateKey]!.add(
          task.copyWith(dayOfWeek: toDateKey, updatedAt: DateTime.now()),
        );

        // Add chat message for task move
        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskMovedMessage(
            taskId: taskId,
            taskText: task.text,
            fromDayKey: fromDateKey,
            toDayKey: toDateKey,
          ),
        );
      }
    }

    _saveTasks();
    notifyListeners();
  }
}
