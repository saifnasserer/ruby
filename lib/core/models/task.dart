class Task {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final String dayOfWeek;
  final bool isMigrated;

  Task({
    required this.id,
    required this.text,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    required this.dayOfWeek,
    this.isMigrated = false,
  });

  Task copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
    String? dayOfWeek,
    bool? isMigrated,
  }) {
    return Task(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isMigrated: isMigrated ?? this.isMigrated,
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
    );
  }
}
