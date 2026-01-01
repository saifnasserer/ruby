import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/models/chat_message.dart';
import '../../core/theme/ruby_theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/chat_history_service.dart';
import '../../core/services/sound_service.dart';
import '../widgets/task_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message_bubble.dart';

class Todo extends StatefulWidget {
  const Todo({super.key});

  @override
  State<Todo> createState() => _TodoState();
}

class _TodoState extends State<Todo> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _tabScrollController;
  late PageController _pageController;
  int _selectedIndex = 0;
  Map<String, List<Task>> _tasks = {};
  final Map<String, List<ChatMessage>> _chatHistory = {};
  final Map<String, ScrollController> _dayScrollControllers = {};

  // Current week's dates (starts from Saturday)
  List<DateTime> _currentWeekDates = [];

  // Arabic weekdays (Saturday to Friday)
  final List<String> _weekDays = [
    'الأحد', // Sunday
    'الإثنين', // Monday
    'الثلاثاء', // Tuesday
    'الأربعاء', // Wednesday
    'الخميس', // Thursday
    'الجمعة', // Friday
    'السبت', // Saturday
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _weekDays.length, vsync: this);
    _tabScrollController = ScrollController();

    // Initialize current week dates first to get today's index
    _initializeCurrentWeek();

    // Find today's index for PageController initialization
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIndex = _currentWeekDates.indexWhere(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );

    // Initialize PageController with today's page
    _pageController = PageController(
      initialPage: todayIndex >= 0 ? todayIndex : 0,
    );

    _tabController.addListener(() {
      if (_selectedIndex != _tabController.index) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
        // Auto-scroll to keep selected tab in view
        _scrollToSelectedTab(_tabController.index);
      }
    });

    _pageController.addListener(() {
      if (_pageController.page != null) {
        final pageIndex = _pageController.page!.round();
        if (pageIndex != _selectedIndex &&
            pageIndex >= 0 &&
            pageIndex < _weekDays.length) {
          setState(() {
            _selectedIndex = pageIndex;
          });
          // Only update tab controller if it's not already at the correct index
          if (_tabController.index != pageIndex) {
            _tabController.animateTo(pageIndex);
          }
        }
      }
    });

    // Initialize tasks for each day
    _initializeTasks();

    // Load saved tasks
    _loadTasks();

    // Set today's tab as default and scroll to it
    _setTodayTab();
  }

  // Initialize current week dates (Saturday to Friday)
  void _initializeCurrentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the Saturday of current week
    // Saturday is weekday 6, so we need to calculate days back to Saturday
    final daysToSaturday =
        (today.weekday + 1) % 7; // Convert to Saturday-based calculation
    final saturday = today.subtract(Duration(days: daysToSaturday));

    // Generate all 7 days of the week (Saturday to Friday)
    _currentWeekDates = List.generate(
      7,
      (index) => saturday.add(Duration(days: index)),
    );

    print('Current week dates (Saturday to Friday): $_currentWeekDates');
  }

  // Initialize tasks for each day using date keys
  void _initializeTasks() {
    for (DateTime date in _currentWeekDates) {
      final dateKey = _getDateKey(date);
      _tasks[dateKey] = [];
      _chatHistory[dateKey] = [];
      _dayScrollControllers[dateKey] = ScrollController();
    }
  }

  // Get date key for storage (format: "2025-01-30")
  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Get display text for a date (e.g., "السبت 30/2")
  String _getDateDisplayText(DateTime date, bool showDate) {
    final dayName = _weekDays[date.weekday % 7];
    if (showDate) return "$dayName ${date.day}/${date.month}";
    return dayName;
  }

  // Check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _setTodayTab() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find today's index in current week
    final todayIndex = _currentWeekDates.indexWhere(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );

    if (todayIndex != -1) {
      // Set the initial index immediately without animation
      _tabController.index = todayIndex;
      _selectedIndex = todayIndex;

      // Scroll to today's tab after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use a microtask to ensure the scroll happens after the widget is fully built
        Future.microtask(() {
          if (_tabScrollController.hasClients) {
            _scrollToTodayTab(todayIndex);
          }
        });
      });
    }
  }

  void _scrollToTodayTab(int todayIndex) {
    _scrollToSelectedTab(todayIndex);
  }

  void _scrollToSelectedTab(int selectedIndex) {
    if (_tabScrollController.hasClients) {
      // Calculate the position to center the selected tab more accurately
      final double tabWidth =
          140.0; // More accurate tab width including margins
      final double screenWidth = MediaQuery.of(context).size.width;
      final double targetPosition =
          (selectedIndex * tabWidth) - (screenWidth / 2) + (tabWidth / 2);

      _tabScrollController.animateTo(
        targetPosition.clamp(
          0.0,
          _tabScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _addTask(String dateKey, String taskText) {
    setState(() {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: taskText,
        createdAt: DateTime.now(),
        dayOfWeek: dateKey, // Now using date key instead of day name
      );
      _tasks[dateKey] = _tasks[dateKey] ?? [];
      _tasks[dateKey]!.add(task);
    });

    // Add chat message for task creation
    ChatHistoryService.addMessage(
      ChatHistoryService.createTaskCreatedMessage(
        taskId: DateTime.now().millisecondsSinceEpoch.toString(),
        taskText: taskText,
        dayKey: dateKey,
      ),
    ).then((_) => _loadChatHistoryForDay(dateKey));

    // Save tasks after adding
    _saveTasks();
  }

  void _toggleTaskCompletion(String dateKey, String taskId) {
    setState(() {
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
            ).then((_) => _loadChatHistoryForDay(dateKey));
          } else {
            // Task was uncompleted
            ChatHistoryService.addMessage(
              ChatHistoryService.createTaskUncompletedMessage(
                taskId: taskId,
                taskText: task.text,
                dayKey: dateKey,
              ),
            ).then((_) => _loadChatHistoryForDay(dateKey));
          }
        }
      }
    });
    // Save tasks after toggling
    _saveTasks();
  }

  void _deleteTask(String dateKey, String taskId) {
    setState(() {
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
          ).then((_) => _loadChatHistoryForDay(dateKey));

          // Mark task as deleted instead of removing completely
          dayTasks[taskIndex] = task.copyWith(
            isDeleted: true,
            deletedAt: DateTime.now(),
          );
        }
      }
    });
    // Save tasks after deleting
    _saveTasks();
  }

  void _addTaskToCurrentDay(String taskText) {
    final currentDate = _currentWeekDates[_selectedIndex];
    final dateKey = _getDateKey(currentDate);
    _addTask(dateKey, taskText);
  }

  void _restoreTask(String dateKey, String taskId) {
    setState(() {
      final dayTasks = _tasks[dateKey];
      if (dayTasks != null) {
        final taskIndex = dayTasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          final task = dayTasks[taskIndex];
          dayTasks[taskIndex] = task.copyWith(
            isDeleted: false,
            deletedAt: null,
          );

          // Add chat message for task restoration
          ChatHistoryService.addMessage(
            ChatHistoryService.createTaskRestoredMessage(
              taskId: taskId,
              taskText: task.text,
              dayKey: dateKey,
            ),
          ).then((_) => _loadChatHistoryForDay(dateKey));
        }
      }
    });
    // Save tasks after restoring
    _saveTasks();
  }

  bool _isTodayIndex(int index) {
    if (index >= 0 && index < _currentWeekDates.length) {
      return _isToday(_currentWeekDates[index]);
    }
    return false;
  }

  // Storage methods
  Future<void> _loadTasks() async {
    print('Loading tasks...');

    // Check storage info first
    final storageInfo = await StorageService.getStorageInfo();
    print('Storage info: $storageInfo');

    final savedTasks = await StorageService.loadTasks();
    print('Loaded tasks: $savedTasks');

    setState(() {
      _tasks = savedTasks;
      // Ensure all days have empty lists if not present
      for (String day in _weekDays) {
        _tasks[day] = _tasks[day] ?? [];
      }
    });

    // Generate chat history for existing tasks (for app updates)
    await ChatHistoryService.generateHistoryForExistingTasks(_tasks);

    // Load chat history for all days
    await _loadAllChatHistory();

    // Migrate incomplete tasks after loading
    await _migrateIncompleteTasks();
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
    for (DateTime date in _currentWeekDates) {
      final dateKey = _getDateKey(date);
      await _loadChatHistoryForDay(dateKey);
    }
  }

  Future<void> _saveTasks() async {
    print('Saving tasks: $_tasks');
    await StorageService.saveTasks(_tasks);
    print('Tasks saved successfully');
  }

  // Task migration feature - migrate all incomplete tasks from previous week to current Saturday
  Future<void> _migrateIncompleteTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _getDateKey(today);

    print('Migration: Today is $todayKey (${today.toString()})');
    print('Migration: Today is weekday ${today.weekday} (0=Monday, 6=Sunday)');

    // Check if migration has already been done for this week
    final lastMigration = await StorageService.getLastMigrationWeekAsync();
    final currentWeekKey = _getWeekKey(today);

    if (lastMigration == currentWeekKey) {
      print(
        'Migration: Already migrated for this week ($currentWeekKey), skipping',
      );
      return;
    }

    // Only migrate on Saturday (weekday 6 in Dart) or when app opens and it's a new week
    final isSaturday = today.weekday == 6; // Saturday in Dart's weekday system
    final isNewWeek = lastMigration != currentWeekKey;

    if (!isSaturday && !isNewWeek) {
      print('Migration: Not Saturday and not a new week, skipping migration');
      return;
    }

    print('Migration: Starting weekly migration for week $currentWeekKey...');

    // Calculate previous week dates (Saturday to Friday)
    final previousWeekDates = _getPreviousWeekDates(today);
    print('Migration: Previous week dates: $previousWeekDates');

    // Get all incomplete tasks from the previous week
    final List<Task> allIncompleteTasks = [];

    for (DateTime weekDate in previousWeekDates) {
      final dateKey = _getDateKey(weekDate);
      final dayTasks = _tasks[dateKey] ?? [];

      final incompleteTasks = dayTasks
          .where((task) => !task.isCompleted)
          .toList();
      allIncompleteTasks.addAll(incompleteTasks);

      print(
        'Migration: Found ${incompleteTasks.length} incomplete tasks in $dateKey',
      );
    }

    if (allIncompleteTasks.isNotEmpty) {
      print(
        'Migration: Total incomplete tasks to migrate: ${allIncompleteTasks.length}',
      );

      // Get current Saturday (start of current week)
      final currentSaturday = _currentWeekDates.first;
      final currentSaturdayKey = _getDateKey(currentSaturday);

      // Ensure current Saturday's list exists
      _tasks[currentSaturdayKey] = _tasks[currentSaturdayKey] ?? [];

      // Add all incomplete tasks to current Saturday with migration flag
      for (final task in allIncompleteTasks) {
        final migratedTask = task.copyWith(
          dayOfWeek: currentSaturdayKey,
          isMigrated: true,
          originalDayOfWeek: task.dayOfWeek,
        );
        _tasks[currentSaturdayKey]!.add(migratedTask);

        // Add chat message for task migration
        ChatHistoryService.addMessage(
          ChatHistoryService.createTaskMigratedMessage(
            taskId: task.id,
            taskText: task.text,
            fromDay: task.dayOfWeek,
            toDay: currentSaturdayKey,
          ),
        ).then((_) => _loadChatHistoryForDay(currentSaturdayKey));
      }

      // Remove all incomplete tasks from previous week
      for (DateTime weekDate in previousWeekDates) {
        final dateKey = _getDateKey(weekDate);
        if (_tasks[dateKey] != null) {
          final beforeCount = _tasks[dateKey]!.length;
          _tasks[dateKey]!.removeWhere((task) => !task.isCompleted);
          final afterCount = _tasks[dateKey]!.length;
          print(
            'Migration: Removed ${beforeCount - afterCount} incomplete tasks from $dateKey',
          );
        }
      }

      print(
        'Migration: Moved ${allIncompleteTasks.length} tasks to current Saturday ($currentSaturdayKey)',
      );
    } else {
      print('Migration: No incomplete tasks found in previous week');
    }

    // Mark this week as migrated
    await StorageService.setLastMigrationWeek(currentWeekKey);

    // Save the migrated tasks
    await _saveTasks();

    // Add weekly summary message
    if (allIncompleteTasks.isNotEmpty) {
      final totalTasks = allIncompleteTasks.length;
      final migratedTasks = allIncompleteTasks.length;
      ChatHistoryService.addMessage(
        ChatHistoryService.createWeekSummaryMessage(
          completedTasks: 0, // We don't track completed tasks in migration
          totalTasks: totalTasks,
          migratedTasks: migratedTasks,
        ),
      );
    }
  }

  // Get week key for tracking migrations (format: "2025-W05")
  String _getWeekKey(DateTime date) {
    // Calculate week number (Saturday-based week)
    final year = date.year;
    final jan1 = DateTime(year, 1, 1);
    final daysSinceJan1 = date.difference(jan1).inDays;
    final weekNumber = ((daysSinceJan1 + jan1.weekday) / 7).ceil();
    return "$year-W${weekNumber.toString().padLeft(2, '0')}";
  }

  // Get previous week dates (Saturday to Friday)
  List<DateTime> _getPreviousWeekDates(DateTime currentDate) {
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

  // Check if there are unfinished tasks in past days of current week
  bool _hasUnfinishedTasksInPastDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (DateTime date in _currentWeekDates) {
      // Skip today and future days
      if (date.isAfter(today) || _isToday(date)) {
        continue;
      }

      final dateKey = _getDateKey(date);
      final dayTasks = _tasks[dateKey] ?? [];

      // Check if there are any unfinished tasks
      final hasUnfinishedTasks = dayTasks.any((task) => !task.isCompleted);
      if (hasUnfinishedTasks) {
        return true;
      }
    }

    return false;
  }

  // Get count of unfinished tasks in past days
  int _getUnfinishedTasksCountInPastDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int count = 0;

    for (DateTime date in _currentWeekDates) {
      // Skip today and future days
      if (date.isAfter(today) || _isToday(date)) {
        continue;
      }

      final dateKey = _getDateKey(date);
      final dayTasks = _tasks[dateKey] ?? [];

      // Count unfinished tasks (excluding deleted tasks)
      count += dayTasks
          .where((task) => !task.isCompleted && !task.isDeleted)
          .length;
    }

    return count;
  }

  // Migrate unfinished tasks from past days to current day
  Future<void> _migrateUnfinishedTasksToToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _getDateKey(today);

    // Ensure today's task list exists
    _tasks[todayKey] = _tasks[todayKey] ?? [];

    int migratedCount = 0;

    for (DateTime date in _currentWeekDates) {
      // Skip today and future days
      if (date.isAfter(today) || _isToday(date)) {
        continue;
      }

      final dateKey = _getDateKey(date);
      final dayTasks = _tasks[dateKey] ?? [];

      // Get unfinished tasks (excluding deleted tasks)
      final unfinishedTasks = dayTasks
          .where((task) => !task.isCompleted && !task.isDeleted)
          .toList();

      if (unfinishedTasks.isNotEmpty) {
        // Move unfinished tasks to today
        for (final task in unfinishedTasks) {
          final migratedTask = task.copyWith(
            dayOfWeek: todayKey,
            isMigrated: true,
            originalDayOfWeek: task.dayOfWeek,
          );
          _tasks[todayKey]!.add(migratedTask);
          migratedCount++;

          // Add chat message for task migration
          ChatHistoryService.addMessage(
            ChatHistoryService.createTaskMigratedMessage(
              taskId: task.id,
              taskText: task.text,
              fromDay: task.dayOfWeek,
              toDay: todayKey,
            ),
          ).then((_) => _loadChatHistoryForDay(todayKey));
        }

        // Remove unfinished tasks from the past day (excluding deleted tasks)
        _tasks[dateKey]!.removeWhere(
          (task) => !task.isCompleted && !task.isDeleted,
        );
      }
    }

    if (migratedCount > 0) {
      // Save the migrated tasks
      await _saveTasks();

      // Add daily summary message for migration
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey = _getDateKey(today);
      final todayTasks = _tasks[todayKey] ?? [];
      final completedTasks = todayTasks
          .where((task) => task.isCompleted && !task.isDeleted)
          .length;
      final totalTasks = todayTasks.where((task) => !task.isDeleted).length;

      ChatHistoryService.addMessage(
        ChatHistoryService.createDaySummaryMessage(
          dayKey: todayKey,
          completedTasks: completedTasks,
          totalTasks: totalTasks,
          migratedTasks: migratedCount,
        ),
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم نقل $migratedCount مهمة غير مكتملة إلى اليوم',
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollController.dispose();
    _pageController.dispose();
    for (var controller in _dayScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RubyTheme.softGray,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Custom Tab Bar with Today Indicator
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: RubyTheme.spacingM(context),
                  vertical: RubyTheme.spacingS(context),
                ),
                child: SingleChildScrollView(
                  controller: _tabScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_currentWeekDates.length, (index) {
                      final isSelected = _selectedIndex == index;
                      final isToday = _isTodayIndex(index);
                      final date = _currentWeekDates[index];
                      final displayText = _getDateDisplayText(date, false);
                      return GestureDetector(
                        onTap: () {
                          // Update selected index immediately
                          setState(() {
                            _selectedIndex = index;
                          });

                          // Animate page controller first
                          if (_pageController.hasClients) {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                            );
                          }

                          // Animate tab controller
                          _tabController.animateTo(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                          );

                          // Scroll to selected tab
                          _scrollToSelectedTab(index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          margin: EdgeInsets.symmetric(
                            horizontal: RubyTheme.spacingXS(context),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: RubyTheme.spacingL(context),
                            vertical: RubyTheme.spacingM(context) / 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? RubyTheme.rubyGradient
                                : null,
                            color: isSelected ? null : RubyTheme.pureWhite,
                            borderRadius: BorderRadius.circular(
                              RubyTheme.radiusLarge(context),
                            ),
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: RubyTheme.rubyRed.withOpacity(0.5),
                                    width: 2,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? RubyTheme.softShadow
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: AnimatedScale(
                            scale: isSelected ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isToday)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                    width: 8,
                                    height: 8,
                                    margin: EdgeInsets.only(
                                      left: RubyTheme.spacingXS(context),
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? RubyTheme.pureWhite
                                          : RubyTheme.rubyRed,
                                      shape: BoxShape.circle,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: RubyTheme.pureWhite
                                                    .withOpacity(0.5),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOutCubic,
                                  style: RubyTheme.bodyLarge(context).copyWith(
                                    color: isSelected
                                        ? RubyTheme.pureWhite
                                        : RubyTheme.charcoal,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: isSelected
                                        ? RubyTheme.bodyLarge(
                                                context,
                                              ).fontSize! *
                                              1.05
                                        : RubyTheme.bodyLarge(context).fontSize,
                                  ),
                                  child: Text(displayText),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Chat-style Task List
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _currentWeekDates.length,
                  itemBuilder: (context, index) {
                    final date = _currentWeekDates[index];
                    final dateKey = _getDateKey(date);
                    final dayTasks = _tasks[dateKey] ?? [];
                    final isToday = _isTodayIndex(index);
                    final displayText = _getDateDisplayText(date, true);

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.15, 0.0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey(index), // Important for AnimatedSwitcher
                        children: [
                          // Migration button (only show on today if there are unfinished tasks in past days)
                          // if (isToday && _hasUnfinishedTasksInPastDays())
                          //   Container(
                          //     margin: EdgeInsets.symmetric(
                          //       horizontal: RubyTheme.spacingM(context),
                          //       vertical: RubyTheme.spacingS(context),
                          //     ),
                          //     child: GestureDetector(
                          //       onTap: _migrateUnfinishedTasksToToday,
                          //       child: AnimatedContainer(
                          //         duration: const Duration(milliseconds: 400),
                          //         curve: Curves.easeInOutCubic,
                          //         padding: EdgeInsets.symmetric(
                          //           horizontal: RubyTheme.spacingL(context),
                          //           vertical: RubyTheme.spacingM(context),
                          //         ),
                          //         decoration: BoxDecoration(
                          //           gradient: RubyTheme.rubyGradient,
                          //           borderRadius: BorderRadius.circular(
                          //             RubyTheme.radiusLarge(context),
                          //           ),
                          //           boxShadow: RubyTheme.softShadow,
                          //         ),
                          //         child: Row(
                          //           mainAxisAlignment: MainAxisAlignment.center,
                          //           children: [
                          //             Icon(
                          //               Icons.schedule_rounded,
                          //               color: RubyTheme.pureWhite,
                          //               size: 20,
                          //             ),
                          //             SizedBox(
                          //               width: RubyTheme.spacingS(context),
                          //             ),
                          //             Text(
                          //               'نقل المهام غير المكتملة من الأيام الماضية',
                          //               style: RubyTheme.bodyLarge(context)
                          //                   .copyWith(
                          //                     color: RubyTheme.pureWhite,
                          //                     fontWeight: FontWeight.w600,
                          //                   ),
                          //             ),
                          //             SizedBox(
                          //               width: RubyTheme.spacingS(context),
                          //             ),
                          //             Container(
                          //               padding: EdgeInsets.symmetric(
                          //                 horizontal: RubyTheme.spacingS(
                          //                   context,
                          //                 ),
                          //                 vertical: RubyTheme.spacingXS(
                          //                   context,
                          //                 ),
                          //               ),
                          //               decoration: BoxDecoration(
                          //                 color: RubyTheme.pureWhite
                          //                     .withOpacity(0.2),
                          //                 borderRadius: BorderRadius.circular(
                          //                   RubyTheme.radiusMedium(context),
                          //                 ),
                          //               ),
                          //               child: Text(
                          //                 '${_getUnfinishedTasksCountInPastDays()}',
                          //                 style: RubyTheme.bodyMedium(context)
                          //                     .copyWith(
                          //                       color: RubyTheme.pureWhite,
                          //                       fontWeight: FontWeight.w700,
                          //                     ),
                          //               ),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //   ),

                          // Chat History + Active Tasks
                          Expanded(
                            child: _buildChatHistoryView(
                              dateKey,
                              dayTasks,
                              displayText,
                              isToday,
                            ),
                          ),

                          // Chat input
                          ChatInput(
                            dayOfWeek: displayText,
                            onTaskAdded: _addTaskToCurrentDay,
                            onTaskRestored: _restoreTask,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build chat history view (chat-like display)
  Widget _buildChatHistoryView(
    String dateKey,
    List<Task> dayTasks,
    String displayText,
    bool isToday,
  ) {
    final history = _chatHistory[dateKey] ?? [];
    final activeTasks = dayTasks.where((task) => !task.isDeleted).toList();

    // If no history and no active tasks, show empty state
    if (history.isEmpty && activeTasks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(RubyTheme.spacingXXL(context)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayText,
                style: RubyTheme.heading2(
                  context,
                ).copyWith(color: RubyTheme.charcoal),
              ),
              SizedBox(height: RubyTheme.spacingS(context)),
              Text(
                'مفيش تاسكات النهارده',
                style: RubyTheme.bodyLarge(
                  context,
                ).copyWith(color: RubyTheme.mediumGray),
              ),
            ],
          ),
        ),
      );
    }

    // Get scroll controller for this day
    final scrollController =
        _dayScrollControllers[dateKey] ?? ScrollController();

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(
        top: RubyTheme.spacingM(context),
        bottom: RubyTheme.spacingS(context),
      ),
      itemCount: history.length + activeTasks.length,
      itemBuilder: (context, index) {
        // First show all chat history messages
        if (index < history.length) {
          final message = history[index];
          return ChatMessageBubble(
            message: message,
            showTimestamp: true,
            onLongPress: () {
              if (message.type == ChatMessageType.taskDeleted) {
                _showRestoreTaskDialog(dateKey, message);
              }
            },
          );
        }

        // Then show active tasks
        final taskIndex = index - history.length;
        if (taskIndex < activeTasks.length) {
          final task = activeTasks[taskIndex];
          return TaskBubble(
            task: task,
            isToday: isToday,
            onTap: () => _toggleTaskCompletion(dateKey, task.id),
            onLongPress: () => _showTaskOptions(dateKey, task.id),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showRestoreTaskDialog(String dateKey, ChatMessage message) {
    if (message.taskId == null) return;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: RubyTheme.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RubyTheme.radiusLarge(context)),
          ),
          title: Text(
            'استعادة التاسك',
            style: RubyTheme.heading2(
              context,
            ).copyWith(color: RubyTheme.charcoal),
          ),
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
                _restoreTask(dateKey, message.taskId!);
              },
              child: Text(
                'استعادة',
                style: RubyTheme.bodyMedium(context).copyWith(
                  color: RubyTheme.emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskOptions(String dateKey, String taskId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(RubyTheme.spacingM(context)),
        decoration: BoxDecoration(
          color: RubyTheme.pureWhite,
          borderRadius: BorderRadius.circular(RubyTheme.radiusLarge(context)),
          boxShadow: RubyTheme.mediumShadow,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: RubyTheme.spacingM(context)),
                decoration: BoxDecoration(
                  color: RubyTheme.mediumGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: RubyTheme.spacingL(context)),

              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: RubyTheme.spacingL(context),
                ),
                child: Text(
                  'خيارات التاسك',
                  style: RubyTheme.heading2(
                    context,
                  ).copyWith(color: RubyTheme.charcoal),
                ),
              ),
              SizedBox(height: RubyTheme.spacingL(context)),

              // Delete option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      RubyTheme.radiusMedium(context),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  'حذف التاسك',
                  style: RubyTheme.bodyLarge(
                    context,
                  ).copyWith(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteTask(dateKey, taskId);
                },
              ),
              SizedBox(height: RubyTheme.spacingL(context)),
            ],
          ),
        ),
      ),
    );
  }
}
