import '../../../../core/models/task.dart';

class TaskService {
  static final TaskService instance = TaskService._();
  TaskService._();

  /// Get date key for storage (format: "2025-01-30")
  String getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Check if a date is today
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get display text for a date (e.g., "السبت 30/2")
  String getDateDisplayText(DateTime date, bool showDate) {
    final weekDays = [
      'الأحد', // Sunday
      'الإثنين', // Monday
      'الثلاثاء', // Tuesday
      'الأربعاء', // Wednesday
      'الخميس', // Thursday
      'الجمعة', // Friday
      'السبت', // Saturday
    ];

    final dayName = weekDays[date.weekday % 7];
    if (showDate) return "$dayName ${date.day}/${date.month}";
    return dayName;
  }

  /// Get week key for tracking migrations (format: "2025-W05")
  String getWeekKey(DateTime date) {
    // Calculate week number (Saturday-based week)
    final year = date.year;
    final jan1 = DateTime(year, 1, 1);
    final daysSinceJan1 = date.difference(jan1).inDays;
    final weekNumber = ((daysSinceJan1 + jan1.weekday) / 7).ceil();
    return "$year-W${weekNumber.toString().padLeft(2, '0')}";
  }

  /// Get previous week dates (Saturday to Friday)
  List<DateTime> getPreviousWeekDates(DateTime currentDate) {
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

  /// Get current week dates (Saturday to Friday)
  List<DateTime> getCurrentWeekDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the Saturday of current week
    // Saturday is weekday 6, so we need to calculate days back to Saturday
    final daysToSaturday =
        (today.weekday + 1) % 7; // Convert to Saturday-based calculation
    final saturday = today.subtract(Duration(days: daysToSaturday));

    // Generate all 7 days of the week (Saturday to Friday)
    return List.generate(7, (index) => saturday.add(Duration(days: index)));
  }

  /// Get today's date key
  String getTodayDateKey() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getDateKey(today);
  }

  /// Get today's index in current week
  int getTodayIndex(List<DateTime> currentWeekDates) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return currentWeekDates.indexWhere(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );
  }

  /// Check if there are unfinished tasks in past days of current week
  bool hasUnfinishedTasksInPastDays(
    List<DateTime> currentWeekDates,
    Map<String, List<Task>> tasks,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (DateTime date in currentWeekDates) {
      // Skip today and future days
      if (date.isAfter(today) || isToday(date)) {
        continue;
      }

      final dateKey = getDateKey(date);
      final dayTasks = tasks[dateKey] ?? [];

      // Check if there are any unfinished tasks
      final hasUnfinishedTasks = dayTasks.any(
        (task) => !task.isCompleted && !task.isDeleted,
      );
      if (hasUnfinishedTasks) {
        return true;
      }
    }

    return false;
  }

  /// Get count of unfinished tasks in past days
  int getUnfinishedTasksCountInPastDays(
    List<DateTime> currentWeekDates,
    Map<String, List<Task>> tasks,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int count = 0;

    for (DateTime date in currentWeekDates) {
      // Skip today and future days
      if (date.isAfter(today) || isToday(date)) {
        continue;
      }

      final dateKey = getDateKey(date);
      final dayTasks = tasks[dateKey] ?? [];

      // Count unfinished tasks (excluding deleted tasks)
      count += dayTasks
          .where((task) => !task.isCompleted && !task.isDeleted)
          .length;
    }

    return count;
  }
}
