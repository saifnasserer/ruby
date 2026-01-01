class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String content;
  final DateTime timestamp;
  final String? taskId;
  final String? taskText;
  final String? fromDay;
  final String? toDay;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.taskId,
    this.taskText,
    this.fromDay,
    this.toDay,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    ChatMessageType? type,
    String? content,
    DateTime? timestamp,
    String? taskId,
    String? taskText,
    String? fromDay,
    String? toDay,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      taskId: taskId ?? this.taskId,
      taskText: taskText ?? this.taskText,
      fromDay: fromDay ?? this.fromDay,
      toDay: toDay ?? this.toDay,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'taskId': taskId,
      'taskText': taskText,
      'fromDay': fromDay,
      'toDay': toDay,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatMessageType.taskCreated,
      ),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      taskId: json['taskId'],
      taskText: json['taskText'],
      fromDay: json['fromDay'],
      toDay: json['toDay'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

enum ChatMessageType {
  taskCreated,
  taskCompleted,
  taskUncompleted,
  taskDeleted,
  taskMigrated,
  daySummary,
  weekSummary,
  taskRestored,
  taskEdited,
  taskPriorityChanged,
  taskCategoryChanged,
  taskMoved,
}

extension ChatMessageTypeExtension on ChatMessageType {
  String get displayName {
    switch (this) {
      case ChatMessageType.taskCreated:
        return 'تم إنشاء التاسك';
      case ChatMessageType.taskCompleted:
        return 'تم إكمال التاسك';
      case ChatMessageType.taskUncompleted:
        return 'تم إلغاء إكمال التاسك';
      case ChatMessageType.taskDeleted:
        return 'تم حذف التاسك';
      case ChatMessageType.taskMigrated:
        return 'تم نقل التاسك';
      case ChatMessageType.daySummary:
        return 'ملخص اليوم';
      case ChatMessageType.weekSummary:
        return 'ملخص الأسبوع';
      case ChatMessageType.taskRestored:
        return 'تم استعادة التاسك';
      case ChatMessageType.taskEdited:
        return 'تم تعديل التاسك';
      case ChatMessageType.taskPriorityChanged:
        return 'تم تغيير الأولوية';
      case ChatMessageType.taskCategoryChanged:
        return 'تم تغيير الفئة';
      case ChatMessageType.taskMoved:
        return 'تم نقل التاسك';
    }
  }

  String get icon {
    switch (this) {
      case ChatMessageType.taskCreated:
        return '➕';
      case ChatMessageType.taskCompleted:
        return '✅';
      case ChatMessageType.taskUncompleted:
        return '↩️';
      case ChatMessageType.taskDeleted:
        return '🗑️';
      case ChatMessageType.taskMigrated:
        return '➡️';
      case ChatMessageType.daySummary:
        return '📊';
      case ChatMessageType.weekSummary:
        return '📈';
      case ChatMessageType.taskRestored:
        return '🔄';
      case ChatMessageType.taskEdited:
        return '✏️';
      case ChatMessageType.taskPriorityChanged:
        return '⭐';
      case ChatMessageType.taskCategoryChanged:
        return '🏷️';
      case ChatMessageType.taskMoved:
        return '📅';
    }
  }
}
