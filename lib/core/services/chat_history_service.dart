import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatHistoryService {
  static const String _chatHistoryKey = 'ruby_chat_history';

  /// Add a new chat message to history
  static Future<void> addMessage(ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJsonString = prefs.getString(_chatHistoryKey);

      List<ChatMessage> messages = [];
      if (historyJsonString != null) {
        final List<dynamic> messagesJson = jsonDecode(historyJsonString);
        messages = messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList();
      }

      // Add new message
      messages.add(message);

      // Sort by timestamp (newest first for chat display)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Save back to storage
      final messagesJson = messages.map((msg) => msg.toJson()).toList();
      final jsonString = jsonEncode(messagesJson);
      await prefs.setString(_chatHistoryKey, jsonString);

      print('ChatHistoryService: Added message - ${message.type.displayName}');
    } catch (e) {
      print('Error adding chat message: $e');
    }
  }

  /// Get chat history for a specific day
  static Future<List<ChatMessage>> getChatHistoryForDay(String dayKey) async {
    try {
      final allMessages = await getAllChatHistory();
      final dayMessages = allMessages.where((msg) {
        // Check if message is for this day or is a summary
        return msg.metadata?['dayKey'] == dayKey ||
            msg.type == ChatMessageType.daySummary ||
            msg.type == ChatMessageType.weekSummary;
      }).toList();

      return dayMessages;
    } catch (e) {
      print('Error getting chat history for day: $e');
      return [];
    }
  }

  /// Get chat history for a specific day with fallback to all messages
  /// This ensures history appears even for existing tasks when app is updated
  static Future<List<ChatMessage>> getChatHistoryForDayWithFallback(
    String dayKey,
  ) async {
    try {
      final dayMessages = await getChatHistoryForDay(dayKey);

      // If no messages found for this day, check if we have any existing tasks
      // and create initial messages for them to show history
      if (dayMessages.isEmpty) {
        // This will be handled by the calling code to create initial messages
        // for existing tasks when the app is first updated with chat history
        return [];
      }

      return dayMessages;
    } catch (e) {
      print('Error getting chat history for day with fallback: $e');
      return [];
    }
  }

  /// Get all chat history
  static Future<List<ChatMessage>> getAllChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJsonString = prefs.getString(_chatHistoryKey);

      if (historyJsonString == null) {
        return [];
      }

      final List<dynamic> messagesJson = jsonDecode(historyJsonString);
      final messages = messagesJson
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      // Sort by timestamp (newest first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return messages;
    } catch (e) {
      print('Error getting all chat history: $e');
      return [];
    }
  }

  /// Clear all chat history
  static Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
      print('ChatHistoryService: Cleared all chat history');
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  /// Get chat history statistics
  static Future<Map<String, dynamic>> getChatHistoryStats() async {
    try {
      final allMessages = await getAllChatHistory();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = today.subtract(Duration(days: today.weekday % 7));

      final todayMessages = allMessages.where((msg) {
        final msgDate = DateTime(
          msg.timestamp.year,
          msg.timestamp.month,
          msg.timestamp.day,
        );
        return msgDate == today;
      }).toList();

      final weekMessages = allMessages.where((msg) {
        final msgDate = DateTime(
          msg.timestamp.year,
          msg.timestamp.month,
          msg.timestamp.day,
        );
        return msgDate.isAfter(thisWeek.subtract(Duration(days: 1)));
      }).toList();

      return {
        'totalMessages': allMessages.length,
        'todayMessages': todayMessages.length,
        'weekMessages': weekMessages.length,
        'taskCreated': allMessages
            .where((m) => m.type == ChatMessageType.taskCreated)
            .length,
        'taskCompleted': allMessages
            .where((m) => m.type == ChatMessageType.taskCompleted)
            .length,
        'taskDeleted': allMessages
            .where((m) => m.type == ChatMessageType.taskDeleted)
            .length,
        'taskMigrated': allMessages
            .where((m) => m.type == ChatMessageType.taskMigrated)
            .length,
      };
    } catch (e) {
      print('Error getting chat history stats: $e');
      return {};
    }
  }

  /// Create a task created message
  static ChatMessage createTaskCreatedMessage({
    required String taskId,
    required String taskText,
    required String dayKey,
  }) {
    return ChatMessage(
      id: 'task_created_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskCreated,
      content: 'تم إنشاء التاسك: $taskText',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      metadata: {'dayKey': dayKey},
    );
  }

  /// Create a task completed message
  static ChatMessage createTaskCompletedMessage({
    required String taskId,
    required String taskText,
    required String dayKey,
  }) {
    return ChatMessage(
      id: 'task_completed_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskCompleted,
      content: 'تم إكمال التاسك: $taskText',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      metadata: {'dayKey': dayKey},
    );
  }

  /// Create a task uncompleted message
  static ChatMessage createTaskUncompletedMessage({
    required String taskId,
    required String taskText,
    required String dayKey,
  }) {
    return ChatMessage(
      id: 'task_uncompleted_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskUncompleted,
      content: 'تم إلغاء إكمال التاسك: $taskText',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      metadata: {'dayKey': dayKey},
    );
  }

  /// Create a task deleted message
  static ChatMessage createTaskDeletedMessage({
    required String taskId,
    required String taskText,
    required String dayKey,
  }) {
    return ChatMessage(
      id: 'task_deleted_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskDeleted,
      content: 'تم حذف التاسك: $taskText',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      metadata: {'dayKey': dayKey},
    );
  }

  /// Create a task migrated message
  static ChatMessage createTaskMigratedMessage({
    required String taskId,
    required String taskText,
    required String fromDay,
    required String toDay,
  }) {
    return ChatMessage(
      id: 'task_migrated_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskMigrated,
      content: 'تم نقل التاسك: $taskText (من $fromDay إلى $toDay)',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      fromDay: fromDay,
      toDay: toDay,
      metadata: {'fromDay': fromDay, 'toDay': toDay},
    );
  }

  /// Create a task restored message
  static ChatMessage createTaskRestoredMessage({
    required String taskId,
    required String taskText,
    required String dayKey,
  }) {
    return ChatMessage(
      id: 'task_restored_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskRestored,
      content: 'تم استعادة التاسك: $taskText',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      metadata: {'dayKey': dayKey},
    );
  }

  /// Create a daily summary message
  static ChatMessage createDaySummaryMessage({
    required String dayKey,
    required int completedTasks,
    required int totalTasks,
    required int migratedTasks,
  }) {
    final completionRate = totalTasks > 0
        ? (completedTasks / totalTasks * 100).round()
        : 0;
    return ChatMessage(
      id: 'day_summary_${dayKey}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.daySummary,
      content:
          'ملخص اليوم: $completedTasks من $totalTasks مهام مكتملة ($completionRate%)${migratedTasks > 0 ? '، $migratedTasks مهام منقولة' : ''}',
      timestamp: DateTime.now(),
      metadata: {
        'dayKey': dayKey,
        'completedTasks': completedTasks,
        'totalTasks': totalTasks,
        'migratedTasks': migratedTasks,
        'completionRate': completionRate,
      },
    );
  }

  /// Create a weekly summary message
  static ChatMessage createWeekSummaryMessage({
    required int completedTasks,
    required int totalTasks,
    required int migratedTasks,
  }) {
    final completionRate = totalTasks > 0
        ? (completedTasks / totalTasks * 100).round()
        : 0;
    return ChatMessage(
      id: 'week_summary_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.weekSummary,
      content:
          'ملخص الأسبوع: $completedTasks من $totalTasks مهام مكتملة ($completionRate%)${migratedTasks > 0 ? '، $migratedTasks مهام منقولة' : ''}',
      timestamp: DateTime.now(),
      metadata: {
        'completedTasks': completedTasks,
        'totalTasks': totalTasks,
        'migratedTasks': migratedTasks,
        'completionRate': completionRate,
      },
    );
  }

  /// Create a task edited message
  static ChatMessage createTaskEditedMessage({
    required String taskId,
    required String oldText,
    required String newText,
    required String dayKey,
  }) {
    return ChatMessage(
      id: 'task_edited_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskEdited,
      content: 'تم تعديل التاسك من "$oldText" إلى "$newText"',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: newText,
      metadata: {'dayKey': dayKey, 'oldText': oldText, 'newText': newText},
    );
  }

  /// Create a task priority changed message
  static ChatMessage createTaskPriorityChangedMessage({
    required String taskId,
    required String taskText,
    required dynamic priority,
    required String dayKey,
  }) {
    return ChatMessage(
      id: 'task_priority_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskPriorityChanged,
      content: 'تم تغيير أولوية التاسك "$taskText" إلى ${priority.displayName}',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      metadata: {'dayKey': dayKey, 'priority': priority.toJson()},
    );
  }

  /// Create a task category changed message
  static ChatMessage createTaskCategoryChangedMessage({
    required String taskId,
    required String taskText,
    required String? category,
    required String dayKey,
  }) {
    return ChatMessage(
      id: 'task_category_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskCategoryChanged,
      content: category != null
          ? 'تم تغيير فئة التاسك "$taskText" إلى "$category"'
          : 'تم إزالة فئة التاسك "$taskText"',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      metadata: {'dayKey': dayKey, 'category': category},
    );
  }

  /// Create a task moved message
  static ChatMessage createTaskMovedMessage({
    required String taskId,
    required String taskText,
    required String fromDayKey,
    required String toDayKey,
  }) {
    return ChatMessage(
      id: 'task_moved_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.taskMoved,
      content: 'تم نقل التاسك "$taskText" من $fromDayKey إلى $toDayKey',
      timestamp: DateTime.now(),
      taskId: taskId,
      taskText: taskText,
      metadata: {'fromDayKey': fromDayKey, 'toDayKey': toDayKey},
    );
  }

  /// Generate chat history for existing tasks (for app updates)
  /// This creates initial messages for tasks that existed before chat history was implemented
  static Future<void> generateHistoryForExistingTasks(
    Map<String, List<dynamic>> tasks,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJsonString = prefs.getString(_chatHistoryKey);

      // Only generate history if no chat history exists yet
      if (historyJsonString != null) {
        print(
          'ChatHistoryService: Chat history already exists, skipping generation',
        );
        return;
      }

      print(
        'ChatHistoryService: Generating chat history for existing tasks...',
      );
      final List<ChatMessage> initialMessages = [];

      tasks.forEach((dayKey, taskList) {
        for (final task in taskList) {
          // Create a task created message for each existing task
          final message = ChatMessage(
            id: 'existing_task_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
            type: ChatMessageType.taskCreated,
            content: 'تم إنشاء التاسك: ${task.text}',
            timestamp: task.createdAt,
            taskId: task.id,
            taskText: task.text,
            metadata: {'dayKey': dayKey, 'isExisting': true},
          );
          initialMessages.add(message);

          // If task is completed, add completion message
          if (task.isCompleted) {
            final completedMessage = ChatMessage(
              id: 'existing_completed_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
              type: ChatMessageType.taskCompleted,
              content: 'تم إكمال التاسك: ${task.text}',
              timestamp: task.completedAt ?? task.createdAt,
              taskId: task.id,
              taskText: task.text,
              metadata: {'dayKey': dayKey, 'isExisting': true},
            );
            initialMessages.add(completedMessage);
          }

          // If task is migrated, add migration message
          if (task.isMigrated) {
            final migratedMessage = ChatMessage(
              id: 'existing_migrated_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
              type: ChatMessageType.taskMigrated,
              content:
                  'تم نقل التاسك: ${task.text} (من ${task.originalDayOfWeek ?? 'يوم سابق'} إلى $dayKey)',
              timestamp: task.createdAt,
              taskId: task.id,
              taskText: task.text,
              fromDay: task.originalDayOfWeek,
              toDay: dayKey,
              metadata: {'dayKey': dayKey, 'isExisting': true},
            );
            initialMessages.add(migratedMessage);
          }
        }
      });

      // Sort messages by timestamp
      initialMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Save initial messages
      final messagesJson = initialMessages.map((msg) => msg.toJson()).toList();
      final jsonString = jsonEncode(messagesJson);
      await prefs.setString(_chatHistoryKey, jsonString);

      print(
        'ChatHistoryService: Generated ${initialMessages.length} initial messages for existing tasks',
      );
    } catch (e) {
      print('Error generating history for existing tasks: $e');
    }
  }
}
