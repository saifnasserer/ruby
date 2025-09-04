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

  // Current week's dates (starts from Sunday)
  List<DateTime> _currentWeekDates = [];

  // Arabic weekdays
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

  // Initialize current week dates (Sunday to Saturday)
  void _initializeCurrentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the Sunday of current week
    final sunday = today.subtract(Duration(days: today.weekday % 7));

    // Generate all 7 days of the week
    _currentWeekDates = List.generate(
      7,
      (index) => sunday.add(Duration(days: index)),
    );

    print('Current week dates: $_currentWeekDates');
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

  // Task migration feature - migrate incomplete tasks from past dates to today
  void _migrateIncompleteTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _getDateKey(today);

    print('Migration: Today is $todayKey');

    // Get all stored date keys that are before today
    final List<String> pastDateKeys = [];
    for (String dateKey in _tasks.keys) {
      try {
        final parts = dateKey.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        if (date.isBefore(today)) {
          pastDateKeys.add(dateKey);
        }
      } catch (e) {
        print('Migration: Invalid date key format: $dateKey');
      }
    }

    print('Migration: Past dates to check: $pastDateKeys');

    // Check each past date for incomplete tasks
    for (String dateKey in pastDateKeys) {
      final dayTasks = _tasks[dateKey] ?? [];
      print('Migration: Checking $dateKey with ${dayTasks.length} tasks');

      // Find incomplete tasks
      final incompleteTasks = dayTasks
          .where((task) => !task.isCompleted)
          .toList();

      if (incompleteTasks.isNotEmpty) {
        print(
          'Migration: Found ${incompleteTasks.length} incomplete tasks in $dateKey',
        );

        // Ensure today's list exists
        _tasks[todayKey] = _tasks[todayKey] ?? [];

        // Add incomplete tasks to today with updated day and migration flag
        for (final task in incompleteTasks) {
          final migratedTask = task.copyWith(
            dayOfWeek: todayKey,
            isMigrated: true,
          );
          _tasks[todayKey]!.add(migratedTask);
        }

        // Remove incomplete tasks from original date
        _tasks[dateKey]!.removeWhere((task) => !task.isCompleted);
        print(
          'Migration: Moved ${incompleteTasks.length} tasks from $dateKey to $todayKey',
        );
      }
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
    );
  }
}
