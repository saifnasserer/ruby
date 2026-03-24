import 'package:flutter/material.dart';
import 'package:ruby/core/models/task.dart';
import 'package:ruby/core/services/storage_service.dart';
import 'package:ruby/core/services/chat_history_service.dart';
import 'package:ruby/core/services/sound_service.dart';
import 'package:ruby/core/services/sync_service.dart';

class TaskController extends ChangeNotifier {
  Map<String, List<Task>> _tasks = {};
  List<String> _availableTags = [];

  Map<String, List<Task>> get tasks => _tasks;
  List<String> get availableTags => _availableTags;

  // Map to store draft subtask text for each task: {taskId: draftText}
  final Map<String, String> _subtaskDrafts = {};

  /// Save a draft subtask for a specific task
  void setSubtaskDraft(String taskId, String draft) {
    if (draft.trim().isEmpty) {
      _subtaskDrafts.remove(taskId);
    } else {
      _subtaskDrafts[taskId] = draft;
    }
  }

  /// Get the saved draft subtask for a specific task
  String getSubtaskDraft(String taskId) {
    return _subtaskDrafts[taskId] ?? '';
  }

  /// Add a new task
  void addTask(String dateKey, String taskText, {List<String>? tags}) {
    final now = DateTime.now();
    final task = Task(
      id: now.millisecondsSinceEpoch.toString(),
      text: taskText,
      createdAt: now,
      updatedAt: now,
      dayOfWeek: dateKey,
      tags: tags ?? [],
    );

    _tasks[dateKey] = _tasks[dateKey] ?? [];
    _tasks[dateKey]!.add(task);

    ChatHistoryService.addMessage(
      ChatHistoryService.createTaskCreatedMessage(
        taskId: task.id,
        taskText: taskText,
        dayKey: dateKey,
      ),
    );

    _saveTasks();
    notifyListeners();
    SyncService.instance.createTask(task);
  }

  /// Add a full task object
  void addTaskObject(String dateKey, Task task) {
    final updatedTask = task.updatedAt == null
        ? task.copyWith(updatedAt: DateTime.now())
        : task;
    _tasks[dateKey] = _tasks[dateKey] ?? [];
    _tasks[dateKey]!.add(updatedTask);

    ChatHistoryService.addMessage(
      ChatHistoryService.createTaskCreatedMessage(
        taskId: task.id,
        taskText: task.text,
        dayKey: dateKey,
        metadata: task.audioPath != null ? {'audioPath': task.audioPath} : null,
      ),
    );

    _saveTasks();
    notifyListeners();
    SyncService.instance.createTask(updatedTask);
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
          updatedAt: DateTime.now(),
          completedAt: !task.isCompleted
              ? DateTime.now()
              : const NullableValue(null),
        );

        if (!wasCompleted) {
          SoundService.instance.playTaskCompletionSound();
          ChatHistoryService.addMessage(
            ChatHistoryService.createTaskCompletedMessage(
              taskId: taskId,
              taskText: task.text,
              dayKey: dateKey,
            ),
          );
        } else {
          ChatHistoryService.addMessage(
            ChatHistoryService.createTaskUncompletedMessage(
              taskId: taskId,
              taskText: task.text,
              dayKey: dateKey,
            ),
          );
        }

        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(dayTasks[taskIndex]);
      }
    }
  }

  /// Delete a task (mark as deleted)
  void deleteTask(String dateKey, String taskId) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];

        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskDeletedMessage(
            taskId: taskId,
            taskText: task.text,
            dayKey: dateKey,
          ),
        );

        dayTasks[taskIndex] = task.copyWith(
          isDeleted: true,
          deletedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(dayTasks[taskIndex]);
      }
    }
  }

  /// Restore a deleted task
  void restoreTask(String dateKey, String taskId) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];
        final restoredTask = task.copyWith(
          isDeleted: false,
          deletedAt: const NullableValue(null),
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = restoredTask;

        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskRestoredMessage(
            taskId: taskId,
            taskText: task.text,
            dayKey: dateKey,
          ),
        );

        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(restoredTask);
      }
    }
  }

  /// Load tasks from storage
  Future<void> loadTasks() async {
    final savedTasks = await StorageService.loadTasks();
    _tasks = savedTasks;
    
    // Load available tags
    _availableTags = await StorageService.loadAvailableTags();
    
    _movePinnedTasksToToday();
    notifyListeners();

    // Background Sync
    SyncService.instance.sync().then((_) {
      StorageService.loadTasks().then((newTasks) {
        _tasks = newTasks;
        notifyListeners();
      });
      // Also sync tags if needed later
    });
  }

  /// Save tasks to storage
  Future<void> _saveTasks() async {
    await StorageService.saveTasks(_tasks);
  }

  /// Get tasks for a specific date
  List<Task> getTasksForDate(String dateKey) {
    return _tasks[dateKey] ?? [];
  }

  /// Get a specific task
  Task? getTask(String dateKey, String taskId) {
    return _tasks[dateKey]?.cast<Task?>().firstWhere(
      (task) => task?.id == taskId,
      orElse: () => null,
    );
  }

  /// Get visible tasks for a specific date (excluding deleted)
  List<Task> getVisibleTasksForDate(String dateKey) {
    return (_tasks[dateKey] ?? []).where((task) => !task.isDeleted).toList();
  }

  /// Get visible tasks for a specific date INCLUDING tasks with deadlines
  List<Task> getVisibleTasksWithDeadlines(String dateKey) {
    final regularTasks = getVisibleTasksForDate(dateKey);
    final dateParts = dateKey.split('-');
    if (dateParts.length != 3) return regularTasks;

    final currentDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    final deadlineTasks = <Task>[];
    _tasks.forEach((taskDateKey, tasks) {
      for (final task in tasks) {
        if (task.isDeleted || task.deadlineDate == null) continue;
        final taskCreationDate = DateTime(
          task.createdAt.year,
          task.createdAt.month,
          task.createdAt.day,
        );
        final deadlineDate = DateTime(
          task.deadlineDate!.year,
          task.deadlineDate!.month,
          task.deadlineDate!.day,
        );

        if (currentDate.isAfter(
              taskCreationDate.subtract(const Duration(days: 1)),
            ) &&
            currentDate.isBefore(deadlineDate.add(const Duration(days: 1))) &&
            taskDateKey != dateKey) {
          deadlineTasks.add(task);
        }
      }
    });

    return [...regularTasks, ...deadlineTasks];
  }

  /// Get days remaining until deadline for a task on a specific date
  int getDaysToDeadline(Task task, String dateKey) {
    if (task.deadlineDate == null) return 0;
    final dateParts = dateKey.split('-');
    if (dateParts.length != 3) return 0;

    final currentDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    final deadlineDate = DateTime(
      task.deadlineDate!.year,
      task.deadlineDate!.month,
      task.deadlineDate!.day,
    );
    return deadlineDate.difference(currentDate).inDays;
  }

  int getUnfinishedTasksCount(String dateKey) {
    final dayTasks = _tasks[dateKey] ?? [];
    return dayTasks
        .where((task) => !task.isCompleted && !task.isDeleted)
        .length;
  }

  int getCompletedTasksCount(String dateKey) {
    final dayTasks = _tasks[dateKey] ?? [];
    return dayTasks.where((task) => task.isCompleted && !task.isDeleted).length;
  }

  int getTotalTasksCount(String dateKey) {
    final dayTasks = _tasks[dateKey] ?? [];
    return dayTasks.where((task) => !task.isDeleted).length;
  }

  bool hasTasksForDate(String dateKey) {
    return getVisibleTasksForDate(dateKey).isNotEmpty;
  }

  void initializeTasksForDates(List<String> dateKeys) {
    for (String dateKey in dateKeys) {
      _tasks[dateKey] = _tasks[dateKey] ?? [];
    }
    notifyListeners();
  }

  void updateTasks(Map<String, List<Task>> newTasks) {
    _tasks = newTasks;
    _saveTasks();
    notifyListeners();
  }

  void clearTasks() {
    _tasks = {};
    _subtaskDrafts.clear();
    notifyListeners();
  }

  void editTask(String dateKey, String taskId, String newText) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];
        final oldText = task.text;
        final updatedTask = task.copyWith(
          text: newText,
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = updatedTask;

        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskEditedMessage(
            taskId: taskId,
            oldText: oldText,
            newText: newText,
            dayKey: dateKey,
          ),
        );
        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

  void updateTaskText(String dateKey, String taskId, String newText) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final updatedTask = dayTasks[taskIndex].copyWith(
          text: newText,
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = updatedTask;
        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

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
        final updatedTask = task.copyWith(
          priority: priority,
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = updatedTask;

        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskPriorityChangedMessage(
            taskId: taskId,
            taskText: task.text,
            priority: priority,
            dayKey: dateKey,
          ),
        );
        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

  void toggleTaskPin(String dateKey, String taskId) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final updatedTask = dayTasks[taskIndex].copyWith(
          isPinned: !dayTasks[taskIndex].isPinned,
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = updatedTask;
        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

  void updateTaskSubtasks(
    String dateKey,
    String taskId,
    List<Subtask> subtasks,
  ) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final updatedTask = dayTasks[taskIndex].copyWith(
          subtasks: subtasks,
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = updatedTask;
        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

  void updateTaskCategory(String dateKey, String taskId, String? category) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];
        final updatedTask = task.copyWith(
          category: category,
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = updatedTask;

        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskCategoryChangedMessage(
            taskId: taskId,
            taskText: task.text,
            category: category,
            dayKey: dateKey,
          ),
        );
        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

  void updateTaskTags(String dateKey, String taskId, List<String> tags) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = dayTasks[taskIndex];
        final updatedTask = task.copyWith(
          tags: tags,
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = updatedTask;
        
        // Update available tags if new tags were added
        bool tagsAdded = false;
        for (final tag in tags) {
          if (!_availableTags.contains(tag)) {
            _availableTags.add(tag);
            tagsAdded = true;
          }
        }
        
        if (tagsAdded) {
          StorageService.saveAvailableTags(_availableTags);
        }

        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

  void addGlobalTag(String tag) {
    if (!_availableTags.contains(tag)) {
      _availableTags.add(tag);
      StorageService.saveAvailableTags(_availableTags);
      notifyListeners();
    }
  }

  void removeGlobalTag(String tag) {
    if (_availableTags.contains(tag)) {
      _availableTags.remove(tag);
      StorageService.saveAvailableTags(_availableTags);
      notifyListeners();
    }
  }

  void renameGlobalTag(String oldTag, String newTag) {
    if (_availableTags.contains(oldTag)) {
      final index = _availableTags.indexOf(oldTag);
      _availableTags[index] = newTag;
      
      // Update tags in all tasks
      _tasks.forEach((dateKey, tasks) {
        for (int i = 0; i < tasks.length; i++) {
          if (tasks[i].tags.contains(oldTag)) {
            final newTags = tasks[i].tags.map((t) => t == oldTag ? newTag : t).toList();
            tasks[i] = tasks[i].copyWith(
              tags: newTags,
              updatedAt: DateTime.now(),
            );
            SyncService.instance.updateTask(tasks[i]);
          }
        }
      });
      
      StorageService.saveAvailableTags(_availableTags);
      _saveTasks();
      notifyListeners();
    }
  }

  void updateTaskDeadline(String dateKey, String taskId, DateTime? deadline) {
    final dayTasks = _tasks[dateKey];
    if (dayTasks != null) {
      final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final updatedTask = dayTasks[taskIndex].copyWith(
          deadlineDate: deadline ?? const NullableValue(null),
          updatedAt: DateTime.now(),
        );
        dayTasks[taskIndex] = updatedTask;
        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

  void moveTask(String fromDateKey, String toDateKey, String taskId) {
    final fromDayTasks = _tasks[fromDateKey];
    if (fromDayTasks != null) {
      final taskIndex = fromDayTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = fromDayTasks[taskIndex];
        fromDayTasks.removeAt(taskIndex);

        final dateParts = toDateKey.split('-');
        DateTime newCreatedAt = task.createdAt;

        if (dateParts.length == 3) {
          try {
            final hour = task.isPinned ? 0 : task.createdAt.hour;
            final minute = task.isPinned ? 1 : task.createdAt.minute;
            final second = task.isPinned ? 0 : task.createdAt.second;

            newCreatedAt = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              hour,
              minute,
              second,
            );
          } catch (_) {}
        }

        _tasks[toDateKey] = _tasks[toDateKey] ?? [];
        final updatedTask = task.copyWith(
          dayOfWeek: toDateKey,
          createdAt: newCreatedAt,
          updatedAt: DateTime.now(),
        );
        _tasks[toDateKey]!.add(updatedTask);

        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskMovedMessage(
            taskId: taskId,
            taskText: task.text,
            fromDayKey: fromDateKey,
            toDayKey: toDateKey,
          ),
        );
        _saveTasks();
        notifyListeners();
        SyncService.instance.updateTask(updatedTask);
      }
    }
  }

  void _movePinnedTasksToToday() {
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final tasksToMove = <Map<String, dynamic>>[];

    _tasks.forEach((dateKey, tasks) {
      if (dateKey == todayKey) return;
      for (final task in tasks) {
        if (task.isPinned && !task.isDeleted && !task.isCompleted) {
          tasksToMove.add({'fromKey': dateKey, 'taskId': task.id});
        }
      }
    });

    for (final moveInfo in tasksToMove) {
      moveTask(moveInfo['fromKey'], todayKey, moveInfo['taskId']);
    }
    if (tasksToMove.isNotEmpty) _saveTasks();
  }
}
