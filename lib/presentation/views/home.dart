import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/theme/ruby_theme.dart';
import '../../core/services/storage_service.dart';
import '../widgets/task_bubble.dart';
import '../widgets/chat_input.dart';

class Todo extends StatefulWidget {
  const Todo({super.key});

  @override
  State<Todo> createState() => _TodoState();
}

class _TodoState extends State<Todo> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _tabScrollController;
  int _selectedIndex = 0;
  Map<String, List<Task>> _tasks = {};

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
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
      // Auto-scroll to keep selected tab in view
      _scrollToSelectedTab(_tabController.index);
    });

    // Initialize current week dates
    _initializeCurrentWeek();

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
    }
  }

  // Get date key for storage (format: "2025-01-30")
  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Get display text for a date (e.g., "السبت 30/2")
  String _getDateDisplayText(DateTime date) {
    final dayName = _weekDays[date.weekday % 7];
    return "$dayName ${date.day}/${date.month}";
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
      _tabController.animateTo(todayIndex);
      _selectedIndex = todayIndex;

      // Scroll to today's tab after a short delay to ensure it's rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTodayTab(todayIndex);
      });
    }
  }

  void _scrollToTodayTab(int todayIndex) {
    _scrollToSelectedTab(todayIndex);
  }

  void _scrollToSelectedTab(int selectedIndex) {
    if (_tabScrollController.hasClients) {
      // Calculate the position to center the selected tab
      final double tabWidth = 120.0; // Approximate tab width
      final double screenWidth = MediaQuery.of(context).size.width;
      final double targetPosition =
          (selectedIndex * tabWidth) - (screenWidth / 2) + (tabWidth / 2);

      _tabScrollController.animateTo(
        targetPosition.clamp(
          0.0,
          _tabScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
          dayTasks[taskIndex] = task.copyWith(
            isCompleted: !task.isCompleted,
            completedAt: !task.isCompleted ? DateTime.now() : null,
          );
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
        dayTasks.removeWhere((task) => task.id == taskId);
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

    // Migrate incomplete tasks after loading
    _migrateIncompleteTasks();
  }

  Future<void> _saveTasks() async {
    print('Saving tasks: $_tasks');
    await StorageService.saveTasks(_tasks);
    print('Tasks saved successfully');
  }

  // Task migration feature - migrate all incomplete tasks to new Saturday (only on Friday)
  void _migrateIncompleteTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _getDateKey(today);

    print('Migration: Today is $todayKey (${today.toString()})');
    print('Migration: Today is weekday ${today.weekday} (0=Monday, 6=Sunday)');

    // Only migrate on Friday (weekday 5 in Dart, but we need to check if it's Friday in our Saturday-Friday week)
    // In our Saturday-Friday week: Saturday=0, Sunday=1, Monday=2, Tuesday=3, Wednesday=4, Thursday=5, Friday=6
    final isFriday = today.weekday == 5; // Friday in Dart's weekday system

    if (!isFriday) {
      print('Migration: Not Friday, skipping migration');
      return;
    }

    print('Migration: It\'s Friday! Starting weekly migration...');

    // Calculate next Saturday (start of next week)
    final nextSaturday = today.add(
      Duration(days: 1),
    ); // Friday + 1 day = Saturday
    final nextSaturdayKey = _getDateKey(nextSaturday);

    print(
      'Migration: Next Saturday is $nextSaturdayKey (${nextSaturday.toString()})',
    );

    // Get all incomplete tasks from the entire current week
    final List<Task> allIncompleteTasks = [];

    for (DateTime weekDate in _currentWeekDates) {
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

      // Ensure next Saturday's list exists
      _tasks[nextSaturdayKey] = _tasks[nextSaturdayKey] ?? [];

      // Add all incomplete tasks to next Saturday with migration flag
      for (final task in allIncompleteTasks) {
        final migratedTask = task.copyWith(
          dayOfWeek: nextSaturdayKey,
          isMigrated: true,
        );
        _tasks[nextSaturdayKey]!.add(migratedTask);
      }

      // Remove all incomplete tasks from current week
      for (DateTime weekDate in _currentWeekDates) {
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
        'Migration: Moved ${allIncompleteTasks.length} tasks to next Saturday ($nextSaturdayKey)',
      );
    } else {
      print('Migration: No incomplete tasks found in current week');
    }

    // Save the migrated tasks
    _saveTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollController.dispose();
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
                      final displayText = _getDateDisplayText(date);
                      return GestureDetector(
                        onTap: () {
                          _tabController.animateTo(index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isToday)
                                Container(
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
                                  ),
                                ),
                              Text(
                                displayText,
                                style: RubyTheme.bodyLarge(context).copyWith(
                                  color: isSelected
                                      ? RubyTheme.pureWhite
                                      : RubyTheme.charcoal,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Chat-style Task List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(_currentWeekDates.length, (index) {
                    final date = _currentWeekDates[index];
                    final dateKey = _getDateKey(date);
                    final dayTasks = _tasks[dateKey] ?? [];
                    final isToday = _isTodayIndex(index);
                    final displayText = _getDateDisplayText(date);

                    return Column(
                      children: [
                        // Task list
                        Expanded(
                          child: dayTasks.isEmpty
                              ? // Empty state
                                Container(
                                  padding: EdgeInsets.all(
                                    RubyTheme.spacingXXL(context),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          displayText,
                                          style: RubyTheme.heading2(
                                            context,
                                          ).copyWith(color: RubyTheme.charcoal),
                                        ),
                                        SizedBox(
                                          height: RubyTheme.spacingS(context),
                                        ),
                                        Text(
                                          'مفيش تاسكات النهارده',
                                          style: RubyTheme.bodyLarge(context)
                                              .copyWith(
                                                color: RubyTheme.mediumGray,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.only(
                                    top: RubyTheme.spacingM(context),
                                    bottom: RubyTheme.spacingS(context),
                                  ),
                                  itemCount: dayTasks.length,
                                  itemBuilder: (context, taskIndex) {
                                    final task = dayTasks[taskIndex];
                                    return TaskBubble(
                                      task: task,
                                      isToday: isToday,
                                      onTap: () => _toggleTaskCompletion(
                                        dateKey,
                                        task.id,
                                      ),
                                      onLongPress: () =>
                                          _showTaskOptions(dateKey, task.id),
                                    );
                                  },
                                ),
                        ),

                        // Chat input
                        ChatInput(
                          dayOfWeek: displayText,
                          onTaskAdded: _addTaskToCurrentDay,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
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
                  'خيارات المهمة',
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
                  'حذف المهمة',
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
