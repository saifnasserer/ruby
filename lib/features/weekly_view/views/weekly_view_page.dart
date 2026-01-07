import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../widgets/unified_chat_view.dart';
import '../../../presentation/widgets/chat_input.dart';
import '../widgets/slideable_task_input.dart';
import '../../../presentation/screens/task_detail_screen.dart';
import '../../../../core/models/task.dart';
import '../../../../features/settings/controllers/settings_controller.dart';
import '../widgets/weekly_view_modals.dart';
import '../widgets/weekly_view_logic_mixin.dart';

class WeeklyViewPage extends StatefulWidget {
  final SettingsController? settingsController;

  const WeeklyViewPage({super.key, this.settingsController});

  @override
  State<WeeklyViewPage> createState() => _WeeklyViewPageState();
}

class _WeeklyViewPageState extends State<WeeklyViewPage>
    with TickerProviderStateMixin, WeeklyViewLogicMixin<WeeklyViewPage> {
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
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
                else if (widget.settingsController?.wallpaperType == 'image' &&
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
                SafeArea(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      children: [
                        Expanded(child: _buildUnifiedChatView()),
                        if (widget.settingsController != null)
                          SlideableTaskInput(
                            dayOfWeek: 'اليوم',
                            onTaskAdded: addTaskToCurrentDay,
                            onTaskRestored: (taskId, dateKey) =>
                                restoreTask(taskId),
                            onVoiceTaskAdded: addVoiceTaskToCurrentDay,
                            settingsController: widget.settingsController!,
                          )
                        else
                          ChatInput(
                            dayOfWeek: 'اليوم',
                            onTaskAdded: addTaskToCurrentDay,
                            onTaskRestored: (taskId, dateKey) =>
                                restoreTask(taskId),
                            onVoiceTaskAdded: addVoiceTaskToCurrentDay,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedChatView() {
    final List<Task> allTasks = [];
    taskController.tasks.forEach((dateKey, tasks) {
      allTasks.addAll(tasks.where((task) => !task.isDeleted));
    });

    return UnifiedChatView(
      tasks: allTasks,
      onTaskTap: (task, dateKey) => _showTaskDetailScreen(task, dateKey),
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
}
