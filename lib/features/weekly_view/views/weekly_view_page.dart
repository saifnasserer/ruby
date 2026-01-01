import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../responsive.dart';
import '../../task_management/controllers/task_controller.dart';

import '../../task_migration/widgets/migration_button.dart';
import '../../task_migration/controllers/migration_controller.dart';
import '../../task_management/widgets/task_list_view.dart';
import '../../task_management/widgets/task_options_modal.dart';
import '../../task_management/widgets/task_detail_modal.dart';
import '../../task_management/widgets/move_task_modal.dart';
import '../../../presentation/widgets/chat_input.dart';
import '../../../presentation/widgets/chat_message_bubble.dart';
import '../../../presentation/widgets/task_bubble.dart';
import '../../../presentation/screens/task_detail_screen.dart';
import '../../../../core/services/chat_history_service.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/models/task.dart';
import '../../../../core/services/test_data_service.dart';
import '../controllers/weekly_view_controller.dart';

class WeeklyViewPage extends StatefulWidget {
  const WeeklyViewPage({super.key});

  @override
  State<WeeklyViewPage> createState() => _WeeklyViewPageState();
}

class _WeeklyViewPageState extends State<WeeklyViewPage>
    with TickerProviderStateMixin {
  late WeeklyViewController _weeklyViewController;
  late TaskController _taskController;
  late MigrationController _migrationController;

  // History view state
  final Map<String, List<ChatMessage>> _chatHistory = {};
  final Map<String, ScrollController> _dayScrollControllers = {};

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _weeklyViewController = WeeklyViewController();
    _taskController = TaskController();
    _migrationController = MigrationController();

    // Initialize weekly view
    _weeklyViewController.initialize(this);

    // Set up listeners
    _setupListeners();

    // Initialize and load data
    _initializeData();
  }

  void _setupListeners() {
    _weeklyViewController.addListener(() {
      setState(() {});
    });

    _taskController.addListener(() {
      setState(() {});
    });

    _migrationController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    // Initialize tasks for each day
    final dateKeys = _weeklyViewController.currentWeekDates
        .map((date) => _weeklyViewController.getDateKey(date))
        .toList();
    _taskController.initializeTasksForDates(dateKeys);

    // Initialize chat history and scroll controllers for each day
    for (final dateKey in dateKeys) {
      _chatHistory[dateKey] = [];
      _dayScrollControllers[dateKey] = ScrollController();
    }

    // Load saved tasks
    await _taskController.loadTasks();

    // TESTING: Load mock data if no tasks exist
    // Set this to false after testing
    const bool loadTestData = false; // DISABLED - loading from storage
    if (loadTestData && _taskController.tasks.isEmpty) {
      final mockTasks = TestDataService.generateMockTasks();
      _taskController.updateTasks(mockTasks);
      print('Loaded test data with ${mockTasks.length} days of tasks');
    }

    // TESTING: Add old tasks for date grouping test
    // COMMENT THIS OUT AFTER TESTING
    const bool loadOldTasks = false; // DISABLED - loading from storage
    if (loadOldTasks) {
      _addOldTasksForTesting();
    }

    // Generate chat history for existing tasks
    await _migrationController.generateHistoryForExistingTasks(
      _taskController.tasks,
    );

    // Load chat history for all days
    await _loadAllChatHistory();

    // Migrate incomplete tasks after loading
    await _migrationController.migrateIncompleteTasksFromPreviousWeek(
      _taskController.tasks,
      _weeklyViewController.currentWeekDates,
    );
  }

  // TESTING: Add old tasks with different creation dates
  // COMMENT THIS OUT AFTER TESTING
  void _addOldTasksForTesting() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _weeklyViewController.getDateKey(today);

    // Get or create today's task list
    final todayTasks = _taskController.tasks[todayKey] ?? [];

    // Add task from 3 days ago
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    todayTasks.add(
      Task(
        id: 'old_task_1',
        text: 'مهمة قديمة من 3 أيام - تحديث التطبيق',
        createdAt: threeDaysAgo.add(const Duration(hours: 10)),
        dayOfWeek: todayKey,
        priority: TaskPriority.normal,
        category: 'عمل',
        tags: ['قديم', 'تحديث'],
        isCompleted: true,
        completedAt: threeDaysAgo.add(const Duration(hours: 15)),
      ),
    );

    // Add task from yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    todayTasks.add(
      Task(
        id: 'old_task_2',
        text: 'مهمة من الأمس - مراجعة الكود',
        createdAt: yesterday.add(const Duration(hours: 14)),
        dayOfWeek: todayKey,
        priority: TaskPriority.important,
        category: 'عمل',
        tags: ['مراجعة'],
        isCompleted: false,
      ),
    );

    // Add task from 1 week ago
    final oneWeekAgo = today.subtract(const Duration(days: 7));
    todayTasks.add(
      Task(
        id: 'old_task_3',
        text: 'مهمة من أسبوع - اجتماع العميل',
        createdAt: oneWeekAgo.add(const Duration(hours: 11)),
        dayOfWeek: todayKey,
        priority: TaskPriority.important,
        category: 'عمل',
        tags: ['اجتماع', 'عميل'],
        isCompleted: true,
        completedAt: oneWeekAgo.add(const Duration(hours: 12)),
      ),
    );

    // Add task from today morning
    todayTasks.add(
      Task(
        id: 'old_task_4',
        text: 'مهمة اليوم الصباح - قراءة الإيميلات',
        createdAt: today.add(const Duration(hours: 8)),
        dayOfWeek: todayKey,
        priority: TaskPriority.normal,
        category: 'شخصي',
        tags: ['يومي'],
        isCompleted: true,
        completedAt: today.add(const Duration(hours: 9)),
      ),
    );

    // Add task from today afternoon
    todayTasks.add(
      Task(
        id: 'old_task_5',
        text: 'مهمة اليوم الظهر - كتابة التقرير',
        createdAt: today.add(const Duration(hours: 13)),
        dayOfWeek: todayKey,
        priority: TaskPriority.normal,
        category: 'عمل',
        tags: ['تقرير'],
        isCompleted: false,
      ),
    );

    // Add task from 2 days ago
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    todayTasks.add(
      Task(
        id: 'old_task_6',
        text: 'مهمة من يومين - تصميم الواجهة',
        createdAt: twoDaysAgo.add(const Duration(hours: 16)),
        dayOfWeek: todayKey,
        priority: TaskPriority.normal,
        category: 'تطوير',
        tags: ['تصميم', 'UI'],
        isCompleted: false,
      ),
    );

    // Update the task controller with the modified list
    _taskController.tasks[todayKey] = todayTasks;

    // Trigger UI update
    setState(() {});

    print('Added ${todayTasks.length} old tasks for date grouping test');
  }

  // Load chat history for a specific day
  Future<void> _loadChatHistoryForDay(String dateKey) async {
    final history = await ChatHistoryService.getChatHistoryForDay(dateKey);
    setState(() {
      _chatHistory[dateKey] = history.reversed
          .toList(); // Reverse to show oldest first (chat style)
    });
  }

  // Load chat history for all days
  Future<void> _loadAllChatHistory() async {
    for (final date in _weeklyViewController.currentWeekDates) {
      final dateKey = _weeklyViewController.getDateKey(date);
      await _loadChatHistoryForDay(dateKey);
    }
  }

  void _addTaskToCurrentDay(String taskText) {
    final currentDateKey = _weeklyViewController.getCurrentDateKey();
    _taskController.addTask(currentDateKey, taskText);

    // Reload chat history to show the new task immediately
    _loadChatHistoryForDay(currentDateKey);
  }

  // Add task to a specific day (schedules to next occurrence if day is in the past)
  void _addTaskToDay(String dateKey, String taskText) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Parse the dateKey to check if it's in the past
    final dateParts = dateKey.split('-');
    final targetDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    // If the target day is in the past, schedule for next occurrence
    if (targetDate.isBefore(today)) {
      // Calculate next occurrence of this weekday
      final targetWeekday = targetDate.weekday;
      final daysUntilNext = (targetWeekday - today.weekday + 7) % 7;
      final nextOccurrence = daysUntilNext == 0
          ? today.add(
              const Duration(days: 7),
            ) // If it's today's weekday, schedule for next week
          : today.add(Duration(days: daysUntilNext));

      final nextDateKey = _weeklyViewController.getDateKey(nextOccurrence);
      _taskController.addTask(nextDateKey, taskText);

      // Reload chat history for the scheduled date
      _loadChatHistoryForDay(nextDateKey);

      // Show a message to user about the scheduled date
      if (mounted) {
        final arabicWeekdays = [
          'الإثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة',
          'السبت',
          'الأحد',
        ];
        final dayName = arabicWeekdays[targetWeekday % 7];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم جدولة التاسك ل$dayName ${nextOccurrence.day}/${nextOccurrence.month}',
              style: RubyTheme.bodyMedium(
                context,
              ).copyWith(color: RubyTheme.pureWhite),
            ),
            backgroundColor: RubyTheme.sapphire,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
            ),
            margin: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Day is today or in the future, add normally
      _taskController.addTask(dateKey, taskText);

      // Reload chat history for the current date
      _loadChatHistoryForDay(dateKey);
    }
  }

  void _toggleTaskCompletion(String taskId) {
    // Find the task in any day (since we have unified view)
    String? taskDateKey;
    Task? foundTask;

    for (var entry in _taskController.tasks.entries) {
      final task = entry.value.firstWhere(
        (t) => t.id == taskId,
        orElse: () =>
            Task(id: '', text: '', createdAt: DateTime.now(), dayOfWeek: ''),
      );

      if (task.id.isNotEmpty) {
        taskDateKey = entry.key;
        foundTask = task;
        break;
      }
    }

    if (taskDateKey != null && foundTask != null) {
      _taskController.toggleTaskCompletion(taskDateKey, taskId);
      _loadChatHistoryForDay(taskDateKey);
    }
  }

  void _deleteTask(String taskId) {
    // Find the task in any day
    String? taskDateKey;

    for (var entry in _taskController.tasks.entries) {
      if (entry.value.any((t) => t.id == taskId)) {
        taskDateKey = entry.key;
        break;
      }
    }

    if (taskDateKey != null) {
      _taskController.deleteTask(taskDateKey, taskId);
      _loadChatHistoryForDay(taskDateKey);
    }
  }

  void _restoreTask(String taskId) {
    // Find the task in any day
    String? taskDateKey;

    for (var entry in _taskController.tasks.entries) {
      if (entry.value.any((t) => t.id == taskId)) {
        taskDateKey = entry.key;
        break;
      }
    }

    if (taskDateKey != null) {
      _taskController.restoreTask(taskDateKey, taskId);
      _loadChatHistoryForDay(taskDateKey);
    }
  }

  void _showTaskOptions(String taskId) {
    // Find the task in any day
    Task? task;

    for (var entry in _taskController.tasks.entries) {
      final foundTask = entry.value.firstWhere(
        (t) => t.id == taskId,
        orElse: () =>
            Task(id: '', text: '', createdAt: DateTime.now(), dayOfWeek: ''),
      );

      if (foundTask.id.isNotEmpty) {
        task = foundTask;
        break;
      }
    }

    if (task == null || task.id.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskOptionsModal(
        onDelete: () => _deleteTask(taskId),
        onEdit: () => _showTaskDetailModal(task!),
        onChangePriority: () => _showPrioritySelector(task!),
        onManageCategory: () => _showTaskDetailModal(task!),
        onMove: () => _showMoveTaskModal(task!),
      ),
    );
  }

  void _showTaskDetailModal(Task task) {
    final currentDateKey = _weeklyViewController.getCurrentDateKey();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TaskDetailModal(
          task: task,
          onTextChanged: (newText) {
            _taskController.editTask(currentDateKey, task.id, newText);
            _loadChatHistoryForDay(currentDateKey);
          },
          onPriorityChanged: (priority) {
            _taskController.updateTaskPriority(
              currentDateKey,
              task.id,
              priority,
            );
            _loadChatHistoryForDay(currentDateKey);
          },
          onCategoryChanged: (category) {
            _taskController.updateTaskCategory(
              currentDateKey,
              task.id,
              category,
            );
            _loadChatHistoryForDay(currentDateKey);
          },
          onTagsChanged: (tags) {
            _taskController.updateTaskTags(currentDateKey, task.id, tags);
          },
          onDeadlineChanged: (deadline) {
            _taskController.updateTaskDeadline(
              currentDateKey,
              task.id,
              deadline,
            );
            _loadChatHistoryForDay(currentDateKey);
          },
        ),
      ),
    );
  }

  void _showPrioritySelector(Task task) {
    final currentDateKey = _weeklyViewController.getCurrentDateKey();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغيير الأولوية', style: RubyTheme.heading2(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskPriority.values.map((priority) {
            return ListTile(
              title: Text(priority.displayName),
              leading: Radio<TaskPriority>(
                value: priority,
                groupValue: task.priority,
                onChanged: (value) {
                  if (value != null) {
                    _taskController.updateTaskPriority(
                      currentDateKey,
                      task.id,
                      value,
                    );
                    _loadChatHistoryForDay(currentDateKey);
                    Navigator.pop(context);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMoveTaskModal(Task task) {
    final currentDateKey = _weeklyViewController.getCurrentDateKey();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MoveTaskModal(
        weekDates: _weeklyViewController.currentWeekDates,
        currentDateKey: currentDateKey,
        getDateKey: _weeklyViewController.getDateKey,
        getDateDisplayText: _weeklyViewController.getDateDisplayText,
        onDateSelected: (newDateKey) {
          _taskController.moveTask(currentDateKey, newDateKey, task.id);
          _loadChatHistoryForDay(currentDateKey);
          _loadChatHistoryForDay(newDateKey);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم نقل التاسك بنجاح',
                style: RubyTheme.bodyMedium(
                  context,
                ).copyWith(color: RubyTheme.pureWhite),
              ),
              backgroundColor: RubyTheme.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  RubyTheme.radiusMedium(context),
                ),
              ),
              margin: EdgeInsets.all(RubyTheme.spacingM(context)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  /// Check if there are unfinished tasks in past days of current week
  bool _hasUnfinishedTasksInPastDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (DateTime date in _weeklyViewController.currentWeekDates) {
      // Skip today and future days
      if (date.isAfter(today) ||
          _weeklyViewController.isTodayIndex(
            _weeklyViewController.currentWeekDates.indexOf(date),
          )) {
        continue;
      }

      final dateKey = _weeklyViewController.getDateKey(date);
      final dayTasks = _taskController.getVisibleTasksForDate(dateKey);

      // Check if there are any unfinished tasks
      final hasUnfinishedTasks = dayTasks.any((task) => !task.isCompleted);
      if (hasUnfinishedTasks) {
        return true;
      }
    }

    return false;
  }

  /// Get count of unfinished tasks in past days
  int _getUnfinishedTasksInPastDaysCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int count = 0;

    for (DateTime date in _weeklyViewController.currentWeekDates) {
      // Skip today and future days
      if (date.isAfter(today) ||
          _weeklyViewController.isTodayIndex(
            _weeklyViewController.currentWeekDates.indexOf(date),
          )) {
        continue;
      }

      final dateKey = _weeklyViewController.getDateKey(date);
      final dayTasks = _taskController.getVisibleTasksForDate(dateKey);

      // Count unfinished tasks
      count += dayTasks.where((task) => !task.isCompleted).length;
    }

    return count;
  }

  Future<void> _migrateUnfinishedTasksToToday() async {
    await _migrationController.migrateUnfinishedTasksToToday(
      _taskController.tasks,
      _weeklyViewController.currentWeekDates,
    );

    // Show success message
    if (mounted) {
      final unfinishedCount = _taskController.getUnfinishedTasksCount(
        _weeklyViewController.getCurrentDateKey(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم نقل $unfinishedCount مهمة غير مكتملة إلى اليوم',
            style: RubyTheme.bodyMedium(
              context,
            ).copyWith(color: RubyTheme.pureWhite),
          ),
          backgroundColor: RubyTheme.emerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              RubyTheme.radiusMedium(context),
            ),
          ),
          margin: EdgeInsets.all(RubyTheme.spacingM(context)),
        ),
      );
    }
  }

  // Build chat history view (WhatsApp-style with date grouping)
  Widget _buildChatHistoryView(
    String dateKey,
    List<dynamic> dayTasks,
    String displayText,
    bool isToday,
  ) {
    final history = _chatHistory[dateKey] ?? [];
    final activeTasks = dayTasks.where((task) => !task.isDeleted).toList();

    // If no history and no active tasks, show empty state
    if (history.isEmpty && activeTasks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.xlarge)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: Responsive.text(context, size: TextSize.heading) * 3,
                color: RubyTheme.mediumGray.withOpacity(0.3),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'مفيش تاسكات لليوم ده',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w500,
                  color: RubyTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Combine all items (history messages + active tasks) and group by date
    final List<dynamic> allItems = [...history, ...activeTasks];

    // Group items by their creation date
    final Map<String, List<dynamic>> groupedByDate = {};
    for (var item in allItems) {
      DateTime itemDate;
      if (item is ChatMessage) {
        itemDate = item.timestamp;
      } else if (item is Task) {
        itemDate = item.createdAt;
      } else {
        continue;
      }

      final itemDateKey = _getDateKey(itemDate);
      groupedByDate.putIfAbsent(itemDateKey, () => []);
      groupedByDate[itemDateKey]!.add(item);
    }

    // Sort date keys in chronological order (oldest first for reverse display)
    // This way when reversed in the list, newest appears at top
    final sortedDateKeys = groupedByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b)); // Ascending order (oldest to newest)

    // Get scroll controller for this day
    final scrollController =
        _dayScrollControllers[dateKey] ?? ScrollController();

    return ListView.builder(
      controller: scrollController,
      reverse: true, // Reverse the list so newest is at top
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
        bottom: Responsive.space(context, size: Space.small),
      ),
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupDateKey = sortedDateKeys[groupIndex];
        final groupItems = groupedByDate[groupDateKey]!;

        // Sort items within the group by timestamp
        groupItems.sort((a, b) {
          DateTime aTime;
          DateTime bTime;

          if (a is ChatMessage) {
            aTime = a.timestamp;
          } else if (a is Task) {
            aTime = a.createdAt;
          } else {
            aTime = DateTime.now();
          }

          if (b is ChatMessage) {
            bTime = b.timestamp;
          } else if (b is Task) {
            bTime = b.createdAt;
          } else {
            bTime = DateTime.now();
          }

          return aTime.compareTo(bTime);
        });

        return Column(
          children: [
            // Date separator (WhatsApp-style)
            _buildDateSeparator(groupDateKey),

            // Items for this date
            ...groupItems.map((item) {
              if (item is ChatMessage) {
                return ChatMessageBubble(
                  message: item,
                  showTimestamp: true,
                  onLongPress: () {
                    if (item.type == ChatMessageType.taskDeleted) {
                      _showRestoreDialog(item);
                    }
                  },
                );
              } else if (item is Task) {
                return TaskBubble(
                  task: item,
                  isToday: isToday,
                  onTap: () => _toggleTaskCompletion(item.id),
                  onLongPress: () => _showTaskOptions(item.id),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }

  // Build WhatsApp-style date separator
  Widget _buildDateSeparator(String dateKey) {
    final date = DateTime.parse(dateKey);
    final dateLabel = _getRelativeDateLabel(date);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.medium),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.medium),
            vertical: Responsive.space(context, size: Space.small),
          ),
          decoration: BoxDecoration(
            color: RubyTheme.mediumGray.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            border: Border.all(
              color: RubyTheme.mediumGray.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.w600,
              color: RubyTheme.mediumGray,
            ),
          ),
        ),
      ),
    );
  }

  // Get relative date label (Today, Yesterday, or formatted date)
  String _getRelativeDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'اليوم';
    } else if (dateOnly == yesterday) {
      return 'أمس';
    } else {
      // Format as "Day DD Month"
      final weekDays = [
        'الأحد',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];

      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];

      final dayName = weekDays[date.weekday % 7];
      final monthName = months[date.month - 1];

      return '$dayName ${date.day} $monthName';
    }
  }

  // Helper to get date key from DateTime
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if a day has ended (not today and has tasks)
  bool _isDayEnded(String dayKey, bool isToday) {
    if (isToday) return false;

    final dayTasks = _taskController.getVisibleTasksForDate(dayKey);
    return dayTasks.isNotEmpty;
  }

  /// Build the day view based on whether it's today or not
  Widget _buildDayView(
    int index,
    String dateKey,
    List<dynamic> dayTasks,
    bool isToday,
    String displayText,
  ) {
    final isDayEnded = _isDayEnded(dateKey, isToday);

    if (isToday) {
      return _buildTodayView(index, dateKey, dayTasks, displayText);
    } else {
      return _buildHistoryView(
        index,
        dateKey,
        dayTasks,
        isToday,
        displayText,
        isDayEnded,
      );
    }
  }

  /// Build today's view with task list and chat input
  Widget _buildTodayView(
    int index,
    String dateKey,
    List<dynamic> dayTasks,
    String displayText,
  ) {
    return Column(
      key: ValueKey('today_$index'),
      children: [
        // Migration button (only show on today if there are unfinished tasks in past days)
        if (_hasUnfinishedTasksInPastDays())
          MigrationButton(
            onTap: _migrateUnfinishedTasksToToday,
            unfinishedTasksCount: _getUnfinishedTasksInPastDaysCount(),
          ),

        // Task list
        TaskListView(
          tasks: dayTasks.cast(),
          isToday: true,
          displayText: displayText,
          onTaskTap: _toggleTaskCompletion,
          onTaskLongPress: _showTaskOptions,
        ),

        // Chat input
        ChatInput(
          dayOfWeek: displayText,
          onTaskAdded: _addTaskToCurrentDay,
          onTaskRestored: (taskId, dateKey) => _restoreTask(taskId),
        ),
      ],
    );
  }

  /// Build history view for non-today days
  Widget _buildHistoryView(
    int index,
    String dateKey,
    List<dynamic> dayTasks,
    bool isToday,
    String displayText,
    bool isDayEnded,
  ) {
    return Column(
      key: ValueKey('history_$index'),
      children: [
        // Small date label for past days
        Container(
          margin: EdgeInsets.only(
            top: Responsive.space(context, size: Space.medium),
            bottom: Responsive.space(context, size: Space.small),
          ),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, size: Space.medium),
                vertical: Responsive.space(context, size: Space.small),
              ),
              decoration: BoxDecoration(
                color: RubyTheme.mediumGray.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(
                  color: RubyTheme.mediumGray.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  fontWeight: FontWeight.w600,
                  color: RubyTheme.mediumGray,
                ),
              ),
            ),
          ),
        ),

        // Chat History + Active Tasks
        Expanded(
          child: _buildChatHistoryView(dateKey, dayTasks, displayText, isToday),
        ),

        // Chat input (available on all days - redirects to today if past day)
        ChatInput(
          dayOfWeek: displayText,
          onTaskAdded: (taskText) => _addTaskToDay(dateKey, taskText),
          onTaskRestored: (taskId, restoredDateKey) => _restoreTask(taskId),
        ),
      ],
    );
  }

  /// Show restore dialog
  void _showRestoreDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('استعادة التاسك', style: RubyTheme.heading2(context)),
        content: Text(
          'هل تريد استعادة التاسك "${message.taskText}"؟',
          style: RubyTheme.bodyLarge(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: RubyTheme.bodyMedium(
                context,
              ).copyWith(color: RubyTheme.mediumGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restoreTaskFromHistory(message);
            },
            child: Text(
              'استعادة',
              style: RubyTheme.bodyMedium(
                context,
              ).copyWith(color: RubyTheme.emerald, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Restore task from history
  void _restoreTaskFromHistory(ChatMessage message) {
    if (message.taskId != null && message.metadata?['dayKey'] != null) {
      final dayKey = message.metadata!['dayKey'] as String;
      _taskController.restoreTask(dayKey, message.taskId!);

      // Reload history to show the restoration message
      _loadChatHistoryForDay(dayKey);
    }
  }

  @override
  void dispose() {
    _weeklyViewController.dispose();
    _taskController.dispose();
    _migrationController.dispose();
    for (var controller in _dayScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RubyTheme.softGray,
      // appBar: AppBar(
      //   backgroundColor: RubyTheme.pureWhite,
      //   elevation: 0,
      //   title: Directionality(
      //     textDirection: TextDirection.rtl,
      //     child: Row(
      //       children: [
      //         Container(
      //           padding: EdgeInsets.all(
      //             Responsive.space(context, size: Space.small),
      //           ),
      //           decoration: BoxDecoration(
      //             gradient: RubyTheme.rubyGradient,
      //             borderRadius: BorderRadius.circular(
      //               Responsive.space(context, size: Space.small),
      //             ),
      //           ),
      //           child: Icon(
      //             Icons.task_alt_rounded,
      //             color: RubyTheme.pureWhite,
      //             size: Responsive.text(context, size: TextSize.medium),
      //           ),
      //         ),
      //         SizedBox(width: Responsive.space(context, size: Space.medium)),
      //         Text('المهام', style: RubyTheme.heading2(context)),
      //       ],
      //     ),
      //   ),
      //   bottom: PreferredSize(
      //     preferredSize: const Size.fromHeight(1),
      //     child: Container(
      //       height: 1,
      //       decoration: BoxDecoration(
      //         gradient: LinearGradient(
      //           colors: [
      //             RubyTheme.rubyRed.withOpacity(0.1),
      //             RubyTheme.emerald.withOpacity(0.1),
      //             RubyTheme.sapphire.withOpacity(0.1),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Unified Chat View (all tasks from all days)
              Expanded(child: _buildUnifiedChatView()),

              // Chat Input
              ChatInput(
                dayOfWeek: 'اليوم',
                onTaskAdded: _addTaskToCurrentDay,
                onTaskRestored: (taskId, dateKey) => _restoreTask(taskId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build unified chat view showing all tasks from all days
  Widget _buildUnifiedChatView() {
    // Collect all tasks from all days
    final List<Task> allTasks = [];

    // Get all tasks (no chat messages)
    _taskController.tasks.forEach((dateKey, tasks) {
      allTasks.addAll(tasks.where((task) => !task.isDeleted));
    });

    // If no tasks, show empty state
    if (allTasks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.xlarge)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: Responsive.text(context, size: TextSize.heading) * 3,
                color: RubyTheme.mediumGray.withOpacity(0.3),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'ابدأ بإضافة مهمتك الأولى',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w500,
                  color: RubyTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group tasks by their creation date
    final Map<String, List<Task>> groupedByDate = {};
    for (var task in allTasks) {
      final itemDateKey = _getDateKey(task.createdAt);
      groupedByDate.putIfAbsent(itemDateKey, () => []);
      groupedByDate[itemDateKey]!.add(task);
    }

    // Sort date keys in descending order (newest to oldest)
    // With reverse: false, newest (today) appears at bottom
    // User swipes UP to see older days
    final sortedDateKeys = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order (newest first)

    return ListView.builder(
      reverse: true, // Normal order - today at bottom, swipe up for older
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
        bottom: Responsive.space(context, size: Space.small),
      ),
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupDateKey = sortedDateKeys[groupIndex];
        final groupTasks = groupedByDate[groupDateKey]!;

        // Sort tasks within the group by creation time
        groupTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final groupDate = DateTime.parse(groupDateKey);
        final isToday =
            DateTime(groupDate.year, groupDate.month, groupDate.day) == today;

        return Column(
          children: [
            // Date separator (WhatsApp-style)
            _buildDateSeparator(groupDateKey),

            // Tasks for this date
            ...groupTasks.map((task) {
              return TaskBubble(
                task: task,
                isToday: isToday,
                onTap: () => _showTaskDetailScreen(task, groupDateKey),
                onLongPress: () => _showTaskOptions(task.id),
              );
            }),
          ],
        );
      },
    );
  }

  void _showTaskDetailScreen(Task task, String dateKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task,
          taskController: _taskController,
          dateKey: dateKey,
          onTaskUpdated: () {
            setState(() {
              _loadChatHistoryForDay(dateKey);
            });
          },
        ),
      ),
    );
  }
}
