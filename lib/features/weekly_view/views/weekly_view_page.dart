import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:ruby/core/theme/ruby_theme.dart';
import 'package:ruby/core/utils/date_formatter.dart';
import 'package:ruby/core/models/task_filter.dart';
import 'package:ruby/features/weekly_view/widgets/unified_chat_view.dart';
import 'package:ruby/presentation/widgets/chat_input.dart';
import 'package:ruby/presentation/widgets/filter_bottom_sheet.dart';
import 'package:ruby/features/weekly_view/widgets/slideable_task_input.dart';
import 'package:ruby/presentation/screens/task_detail_screen.dart';
import 'package:ruby/core/models/task.dart';
import 'package:ruby/features/settings/controllers/settings_controller.dart';
import 'package:ruby/features/weekly_view/widgets/weekly_view_modals.dart';
import 'package:ruby/features/weekly_view/widgets/weekly_view_logic_mixin.dart';
import 'package:ruby/features/search/views/search_screen.dart';
import 'package:ruby/core/services/auth_service.dart';
import 'package:ruby/core/utils/ruby_snackbars.dart';
import 'package:ruby/presentation/screens/auth/login_screen.dart';

class WeeklyViewPage extends StatefulWidget {
  final SettingsController? settingsController;

  const WeeklyViewPage({super.key, this.settingsController});

  @override
  State<WeeklyViewPage> createState() => _WeeklyViewPageState();
}

class _WeeklyViewPageState extends State<WeeklyViewPage>
    with TickerProviderStateMixin, WeeklyViewLogicMixin<WeeklyViewPage> {
  TaskFilter _currentFilter = const TaskFilter();
  @override
  void initState() {
    super.initState();

    // Initialize weekly view
    weeklyViewController.initialize(this);

    // Set up listeners
    _setupListeners();

    // Initialize and load data (from Mixin)
    initializeData();
  }

  void _setupListeners() {
    weeklyViewController.addListener(() {
      if (mounted) setState(() {});
    });

    taskController.addListener(() {
      if (mounted) setState(() {});
    });

    migrationController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    weeklyViewController.dispose();
    taskController.dispose();
    migrationController.dispose();
    for (var controller in dayScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // UI action handlers that use Modals helper

  void _handleShowTaskDetail(Task task) {
    // Use the task's actual creation date, not the current date
    final taskDateKey = DateFormatter.getDateKey(task.createdAt);

    WeeklyViewModals.showTaskDetailModal(
      context,
      task: task,
      currentDateKey: taskDateKey,
      taskController: taskController,
      onLoadHistory: loadChatHistoryForDay,
    );
  }

  void _handleShowPrioritySelector(Task task) {
    // Use the task's actual creation date, not the current date
    final taskDateKey = DateFormatter.getDateKey(task.createdAt);

    WeeklyViewModals.showPrioritySelector(
      context,
      task: task,
      currentDateKey: taskDateKey,
      taskController: taskController,
      onLoadHistory: loadChatHistoryForDay,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settingsController != null) {
      return AnimatedBuilder(
        animation: widget.settingsController!,
        builder: (context, child) => _buildScaffold(context),
      );
    }
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = RubyTheme.pureWhite;

    if (widget.settingsController?.wallpaperType == 'color') {
      backgroundColor = widget.settingsController!.backgroundColor;
    } else if (isDarkMode) {
      backgroundColor = RubyTheme.darkBackground;
    }

    final isLightBackground =
        !isDarkMode && backgroundColor.computeLuminance() > 0.5;
    final statusBarStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLightBackground
          ? Brightness.dark
          : Brightness.light,
      statusBarBrightness: isLightBackground
          ? Brightness.light
          : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle,
      child: Stack(
        children: [
          // 1. Fixed Background Layer (Ignores Keyboard)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: backgroundColor),
              child: Stack(
                children: [
                  // Dark Mode Default Background (Only if user hasn't customized)
                  if (isDarkMode &&
                      widget.settingsController?.wallpaperType == 'image' &&
                      widget.settingsController?.wallpaperPath ==
                          'assets/pattern.jpg')
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.2, // Default opacity for dark mode bg
                        child: Image.asset(
                          'assets/darkmode bg.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  // User Selected Wallpaper (Image)
                  else if (widget.settingsController?.wallpaperType ==
                          'image' &&
                      widget.settingsController?.wallpaperPath != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: widget.settingsController!.isAssetWallpaper
                            ? 0.2
                            : widget.settingsController!.wallpaperOpacity,
                        child: widget.settingsController!.isAssetWallpaper
                            ? Image.asset(
                                widget.settingsController!.wallpaperPath!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(widget.settingsController!.wallpaperPath!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Resizable Content Layer (Adjusts to Keyboard)
          Scaffold(
            resizeToAvoidBottomInset:
                true, // Native resize enables KB avoidance
            backgroundColor: Colors.transparent, // Let background show through
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    children: [
                      Expanded(child: _buildUnifiedChatView()),
                      if (widget.settingsController != null)
                        SlideableTaskInput(
                          dayOfWeek: 'النهاردة',
                          onTaskAdded: addTaskToCurrentDay,
                          onTaskRestored: (taskId, dateKey) =>
                              restoreTask(taskId),
                          onVoiceTaskAdded: addVoiceTaskToCurrentDay,
                          settingsController: widget.settingsController!,
                          onSearchTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchScreen(
                                  taskController: taskController,
                                ),
                              ),
                            );
                          },
                          onSyncTap: () async {
                            if (!AuthService.instance.isAuthenticated) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(
                                    settingsController:
                                        widget.settingsController,
                                  ),
                                ),
                              );
                            } else {
                              await taskController.loadTasks();
                              if (context.mounted) {
                                RubySnackBar.showSuccess(
                                  context,
                                  "تاسكاتك اتحدثت بنجاح! 🚀",
                                );
                              }
                            }
                          },
                          onFilterTap: () => _showFilterBottomSheet(),
                          currentFilter: _currentFilter,
                        )
                      else
                        ChatInput(
                          dayOfWeek: 'النهاردة',
                          onTaskAdded: addTaskToCurrentDay,
                          onTaskRestored: (taskId, dateKey) =>
                              restoreTask(taskId),
                          onVoiceTaskAdded: addVoiceTaskToCurrentDay,
                          hasActiveFilters: _currentFilter.hasActiveFilters,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedChatView() {
    final List<Task> allTasks = [];
    taskController.tasks.forEach((dateKey, tasks) {
      allTasks.addAll(tasks.where((task) => !task.isDeleted));
    });

    // Apply filters
    final filteredTasks = _applyFilters(allTasks);

    return UnifiedChatView(
      tasks: filteredTasks,
      onTaskTap: (task, dateKey) => _showTaskDetailScreen(task, dateKey),
      hasActiveFilters: _currentFilter.hasActiveFilters,
      onResetFilters: () {
        setState(() {
          _currentFilter = _currentFilter.reset();
        });
      },
    );
  }

  void _showTaskDetailScreen(Task task, String dateKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task,
          taskController: taskController,
          dateKey: dateKey,
          onTaskUpdated: () {
            setState(() {
              loadChatHistoryForDay(dateKey);
            });
          },
        ),
      ),
    );
  }

  void _showFilterBottomSheet() async {
    final newFilter = await showFilterBottomSheet(
      context: context,
      currentFilter: _currentFilter,
    );

    if (newFilter != null && newFilter != _currentFilter) {
      setState(() {
        _currentFilter = newFilter;
      });
    }
  }

  List<Task> _applyFilters(List<Task> tasks) {
    return tasks.where((task) {
      // Apply completion filter
      if (!_matchesCompletionFilter(task)) {
        return false;
      }

      // Apply priority filter
      if (!_matchesPriorityFilter(task)) {
        return false;
      }

      // Apply date filter
      if (!_matchesDateFilter(task)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _matchesCompletionFilter(Task task) {
    switch (_currentFilter.completionFilter) {
      case TaskCompletionFilter.all:
        return true;
      case TaskCompletionFilter.completed:
        return task.isCompleted;
      case TaskCompletionFilter.uncompleted:
        return !task.isCompleted;
    }
  }

  bool _matchesPriorityFilter(Task task) {
    if (_currentFilter.priorityFilter == null) {
      return true;
    }

    switch (_currentFilter.priorityFilter!) {
      case TaskPriorityFilter.important:
        return task.priority == TaskPriority.important;
      case TaskPriorityFilter.normal:
        return task.priority == TaskPriority.normal;
    }
  }

  bool _matchesDateFilter(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(
      task.createdAt.year,
      task.createdAt.month,
      task.createdAt.day,
    );

    switch (_currentFilter.dateFilter) {
      case TaskDateFilter.all:
        return true;
      case TaskDateFilter.today:
        return taskDate == today;
      case TaskDateFilter.thisWeek:
        // Check if task is in current week (Saturday to Friday)
        final currentWeekDates = weeklyViewController.currentWeekDates;
        return currentWeekDates.any((date) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          return dateOnly == taskDate;
        });
      case TaskDateFilter.past:
        return taskDate.isBefore(today);
    }
  }
}
