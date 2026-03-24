enum TaskCompletionFilter {
  all,
  completed,
  uncompleted;

  String get displayName {
    switch (this) {
      case TaskCompletionFilter.all:
        return 'الكل';
      case TaskCompletionFilter.completed:
        return 'المكتملة';
      case TaskCompletionFilter.uncompleted:
        return 'غير المكتملة';
    }
  }
}

enum TaskPriorityFilter {
  important,
  normal;

  String get displayName {
    switch (this) {
      case TaskPriorityFilter.important:
        return 'مهم';
      case TaskPriorityFilter.normal:
        return 'عادي';
    }
  }
}

enum TaskDateFilter {
  all,
  today,
  thisWeek,
  past;

  String get displayName {
    switch (this) {
      case TaskDateFilter.all:
        return 'كل الأوقات';
      case TaskDateFilter.today:
        return 'النهاردة';
      case TaskDateFilter.thisWeek:
        return 'هذا الأسبوع';
      case TaskDateFilter.past:
        return 'السابقة';
    }
  }
}

class TaskFilter {
  final TaskCompletionFilter completionFilter;
  final TaskPriorityFilter? priorityFilter;
  final TaskDateFilter dateFilter;
  final String? selectedTag;

  const TaskFilter({
    this.completionFilter = TaskCompletionFilter.all,
    this.priorityFilter,
    this.dateFilter = TaskDateFilter.all,
    this.selectedTag,
  });

  /// Check if any filters are active (not default)
  bool get hasActiveFilters {
    return completionFilter != TaskCompletionFilter.all ||
        priorityFilter != null ||
        dateFilter != TaskDateFilter.all ||
        selectedTag != null;
  }

  /// Create a copy with updated values
  TaskFilter copyWith({
    TaskCompletionFilter? completionFilter,
    TaskPriorityFilter? priorityFilter,
    bool clearPriorityFilter = false,
    TaskDateFilter? dateFilter,
    String? selectedTag,
    bool clearSelectedTag = false,
  }) {
    return TaskFilter(
      completionFilter: completionFilter ?? this.completionFilter,
      priorityFilter: clearPriorityFilter
          ? null
          : (priorityFilter ?? this.priorityFilter),
      dateFilter: dateFilter ?? this.dateFilter,
      selectedTag: clearSelectedTag
          ? null
          : (selectedTag ?? this.selectedTag),
    );
  }

  /// Reset all filters to default
  TaskFilter reset() {
    return const TaskFilter();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskFilter &&
        other.completionFilter == completionFilter &&
        other.priorityFilter == priorityFilter &&
        other.dateFilter == dateFilter &&
        other.selectedTag == selectedTag;
  }

  @override
  int get hashCode {
    return Object.hash(completionFilter, priorityFilter, dateFilter, selectedTag);
  }
}
