import '../models/task.dart';
import '../models/chat_message.dart';

class AnalysisMetrics {
  final double completionRate;
  final int totalTasks;
  final int completedTasks;
  final int migratedTasks;
  final double migrationRate;
  final Map<DateTime, int> completionOverTime;
  final Map<DateTime, int> migrationOverTime;
  final List<Task> topMigratedTasks;
  final Map<int, int> hourlyActivity; // 0-23
  final Map<String, int> tasksByCategory;
  final Map<TaskPriority, int> tasksByPriority;
  final int currentStreak;
  final int recordStreak;
  final int todayTotal;
  final int todayCompleted;
  final double todayCompletionRate;

  AnalysisMetrics({
    required this.completionRate,
    required this.totalTasks,
    required this.completedTasks,
    required this.migratedTasks,
    required this.migrationRate,
    required this.completionOverTime,
    required this.migrationOverTime,
    required this.topMigratedTasks,
    required this.hourlyActivity,
    required this.tasksByCategory,
    required this.tasksByPriority,
    required this.currentStreak,
    required this.recordStreak,
    required this.todayTotal,
    required this.todayCompleted,
    required this.todayCompletionRate,
  });
}

class AnalysisService {
  static AnalysisMetrics calculateMetrics(
    List<Task> allTasks,
    List<ChatMessage> allMessages,
  ) {
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // 1. Basic Stats
    final activeTasks = allTasks.where((t) => !t.isDeleted).toList();
    final totalTasks = activeTasks.length;
    final completedTasks = activeTasks.where((t) => t.isCompleted).length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    // Today's Stats
    final todayTasks = activeTasks
        .where((t) => t.dayOfWeek == todayKey)
        .toList();
    final todayTotal = todayTasks.length;
    final todayCompleted = todayTasks.where((t) => t.isCompleted).length;
    final todayCompletionRate = todayTotal > 0
        ? todayCompleted / todayTotal
        : 0.0;

    // 2. Migration Analysis
    final migrationMessages = allMessages
        .where((m) => m.type == ChatMessageType.taskMigrated)
        .toList();
    final migratedTasksCount =
        migrationMessages.length; // Count every migration event
    final migrationRate = totalTasks > 0
        ? migratedTasksCount / totalTasks
        : 0.0;

    // Top Migrated Tasks
    final migrationCounts = <String, int>{};
    for (var msg in migrationMessages) {
      if (msg.taskId != null) {
        migrationCounts[msg.taskId!] = (migrationCounts[msg.taskId!] ?? 0) + 1;
      }
    }

    final sortedTaskIds = migrationCounts.keys.toList()
      ..sort((a, b) => migrationCounts[b]!.compareTo(migrationCounts[a]!));

    final topMigratedTasks = sortedTaskIds
        .take(3)
        .map((id) {
          try {
            return activeTasks.firstWhere((t) => t.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Task>()
        .toList();

    // 3. Time Series Data (Last 7 Days)
    final last7Days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: i));
      return DateTime(date.year, date.month, date.day);
    }).reversed.toList();

    final completionOverTime = <DateTime, int>{};
    final migrationOverTime = <DateTime, int>{};

    for (var date in last7Days) {
      completionOverTime[date] = allMessages.where((m) {
        final mDate = DateTime(
          m.timestamp.year,
          m.timestamp.month,
          m.timestamp.day,
        );
        return mDate == date && m.type == ChatMessageType.taskCompleted;
      }).length;

      migrationOverTime[date] = allMessages.where((m) {
        final mDate = DateTime(
          m.timestamp.year,
          m.timestamp.month,
          m.timestamp.day,
        );
        return mDate == date && m.type == ChatMessageType.taskMigrated;
      }).length;
    }

    // 4. Hourly Activity (Completion Heatmap)
    final hourlyActivity = Map.fromIterables(
      List.generate(24, (i) => i),
      List.generate(24, (i) => 0),
    );

    for (var msg in allMessages) {
      if (msg.type == ChatMessageType.taskCompleted) {
        final hour = msg.timestamp.hour;
        hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
      }
    }

    // 5. Categorical & Priority Breakdown
    final tasksByCategory = <String, int>{};
    final tasksByPriority = {TaskPriority.normal: 0, TaskPriority.important: 0};

    for (var task in activeTasks) {
      if (task.category != null && task.category!.isNotEmpty) {
        tasksByCategory[task.category!] =
            (tasksByCategory[task.category!] ?? 0) + 1;
      }
      tasksByPriority[task.priority] =
          (tasksByPriority[task.priority] ?? 0) + 1;
    }

    // 6. Streaks
    int currentStreak = 0;
    int maxStreak = 0;

    // Get unique dates with at least one completion
    final completionDates =
        allMessages
            .where((m) => m.type == ChatMessageType.taskCompleted)
            .map(
              (m) => DateTime(
                m.timestamp.year,
                m.timestamp.month,
                m.timestamp.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // Newest first

    if (completionDates.isNotEmpty) {
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // Start checking from today or yesterday
      DateTime checkDate = completionDates.first;
      if (checkDate == today || checkDate == yesterday) {
        currentStreak = 1;
        for (int i = 0; i < completionDates.length - 1; i++) {
          if (completionDates[i].difference(completionDates[i + 1]).inDays ==
              1) {
            currentStreak++;
          } else {
            break;
          }
        }
      }

      // Calculate Max Streak
      int tempStreak = 1;
      // Reverse to check from oldest to newest
      final sortedAsc = completionDates.reversed.toList();
      for (int i = 0; i < sortedAsc.length - 1; i++) {
        if (sortedAsc[i + 1].difference(sortedAsc[i]).inDays == 1) {
          tempStreak++;
        } else {
          if (tempStreak > maxStreak) maxStreak = tempStreak;
          tempStreak = 1;
        }
      }
      if (tempStreak > maxStreak) maxStreak = tempStreak;
    }

    return AnalysisMetrics(
      completionRate: completionRate,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      migratedTasks: migratedTasksCount,
      migrationRate: migrationRate,
      completionOverTime: completionOverTime,
      migrationOverTime: migrationOverTime,
      topMigratedTasks: topMigratedTasks,
      hourlyActivity: hourlyActivity,
      tasksByCategory: tasksByCategory,
      tasksByPriority: tasksByPriority,
      currentStreak: currentStreak,
      recordStreak: maxStreak,
      todayTotal: todayTotal,
      todayCompleted: todayCompleted,
      todayCompletionRate: todayCompletionRate,
    );
  }
}
