enum TaskPriority {
  normal,
  important;

  String get displayName {
    switch (this) {
      case TaskPriority.normal:
        return 'عادي';
      case TaskPriority.important:
        return 'مهم';
    }
  }

  String toJson() => name;

  static TaskPriority fromJson(String? json) {
    if (json == null) return TaskPriority.normal;
    return TaskPriority.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TaskPriority.normal,
    );
  }
}

// Helper class for explicitly setting nullable values to null in copyWith
class NullableValue<T> {
  final T? value;
  const NullableValue(this.value);
}

class Subtask {
  final String id;
  final String text;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;

  Subtask({
    required this.id,
    required this.text,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
  });

  Subtask copyWith({
    String? id,
    String? text,
    Object?
    description, // Default is null (preserve). Pass NullableValue(null) to clear.
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      text: text ?? this.text,
      description: description == null
          ? this.description
          : (description is NullableValue
                ? description.value as String?
                : description as String?),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      text: json['text'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Task {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final String dayOfWeek;
  final bool isMigrated;
  final String? originalDayOfWeek;
  final bool isDeleted;
  final DateTime? deletedAt;
  final TaskPriority priority;
  final String? category;
  final List<String> tags;
  final DateTime? updatedAt;
  final List<Subtask> subtasks;

  final DateTime? deadlineDate;
  final String? audioPath;

  // Map of date keys to progress notes for deadline tasks
  // e.g., {"2026-01-07": "Made good progress", "2026-01-08": "Almost done"}
  final Map<String, String> dailyProgress;

  Task({
    required this.id,
    required this.text,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    required this.dayOfWeek,
    this.isMigrated = false,
    this.originalDayOfWeek,
    this.isDeleted = false,
    this.deletedAt,
    this.priority = TaskPriority.normal,
    this.category,
    this.tags = const [],
    this.updatedAt,
    this.subtasks = const [],
    this.deadlineDate,
    this.audioPath,
    this.dailyProgress = const {},
  });

  Task copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    bool? isCompleted,
    Object? completedAt,
    String? dayOfWeek,
    bool? isMigrated,
    String? originalDayOfWeek,
    bool? isDeleted,
    Object? deletedAt,
    TaskPriority? priority,
    String? category,
    List<String>? tags,
    Object? updatedAt,
    List<Subtask>? subtasks,
    Object? deadlineDate,
    String? audioPath,
    Map<String, String>? dailyProgress,
  }) {
    return Task(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt == null
          ? this.completedAt
          : (completedAt is NullableValue
                ? completedAt.value as DateTime?
                : completedAt as DateTime?),
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isMigrated: isMigrated ?? this.isMigrated,
      originalDayOfWeek: originalDayOfWeek ?? this.originalDayOfWeek,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt == null
          ? this.deletedAt
          : (deletedAt is NullableValue
                ? deletedAt.value as DateTime?
                : deletedAt as DateTime?),
      priority: priority ?? this.priority,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      updatedAt: updatedAt == null
          ? this.updatedAt
          : (updatedAt is NullableValue
                ? updatedAt.value as DateTime?
                : updatedAt as DateTime?),
      subtasks: subtasks ?? this.subtasks,
      deadlineDate: deadlineDate == null
          ? this.deadlineDate
          : (deadlineDate is NullableValue
                ? deadlineDate.value as DateTime?
                : deadlineDate as DateTime?),
      audioPath: audioPath ?? this.audioPath,
      dailyProgress: dailyProgress ?? this.dailyProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'isMigrated': isMigrated,
      'originalDayOfWeek': originalDayOfWeek,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'priority': priority.toJson(),
      'category': category,
      'tags': tags,
      'updatedAt': updatedAt?.toIso8601String(),

      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'deadlineDate': deadlineDate?.toIso8601String(),
      'audioPath': audioPath,
      'dailyProgress': dailyProgress,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      dayOfWeek: json['dayOfWeek'],
      isMigrated: json['isMigrated'] ?? false,
      originalDayOfWeek: json['originalDayOfWeek'],
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
      priority: TaskPriority.fromJson(json['priority'] as String?),
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      subtasks:
          (json['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      deadlineDate: json['deadlineDate'] != null
          ? DateTime.parse(json['deadlineDate'] as String)
          : null,
      audioPath: json['audioPath'] as String?,
      dailyProgress:
          (json['dailyProgress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
    );
  }
}
