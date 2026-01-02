import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../../core/theme/ruby_theme.dart';
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
  void _handleShowTaskOptions(String taskId) {
    // Find task
    Task? task;
    for (var entry in taskController.tasks.entries) {
      final found = entry.value.firstWhere(
        (t) => t.id == taskId,
        orElse: () =>
            Task(id: '', text: '', createdAt: DateTime.now(), dayOfWeek: ''),
      );
      if (found.id.isNotEmpty) {
        task = found;
        break;
      }
    }

    if (task != null) {
      WeeklyViewModals.showTaskOptions(
        context,
        taskId: taskId,
        task: task,
        onDelete: () => deleteTask(taskId),
        onEdit: (t) => _handleShowTaskDetail(t),
        onChangePriority: (t) => _handleShowPrioritySelector(t),
        onMove: (t) => _handleShowMoveTask(t),
      );
    }
  }

  void _handleShowTaskDetail(Task task) {
    WeeklyViewModals.showTaskDetailModal(
      context,
      task: task,
      currentDateKey: weeklyViewController.getCurrentDateKey(),
      taskController: taskController,
      onLoadHistory: loadChatHistoryForDay,
    );
  }

  void _handleShowPrioritySelector(Task task) {
    WeeklyViewModals.showPrioritySelector(
      context,
      task: task,
      currentDateKey: weeklyViewController.getCurrentDateKey(),
      taskController: taskController,
      onLoadHistory: loadChatHistoryForDay,
    );
  }

  void _handleShowMoveTask(Task task) {
    WeeklyViewModals.showMoveTaskModal(
      context,
      task: task,
      currentDateKey: weeklyViewController.getCurrentDateKey(),
      weeklyViewController: weeklyViewController,
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
    Color backgroundColor = RubyTheme.softGray;
    if (widget.settingsController?.wallpaperType == 'color') {
      backgroundColor = widget.settingsController!.backgroundColor;
    }

    final isLightBackground = backgroundColor.computeLuminance() > 0.5;
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
        backgroundColor: widget.settingsController?.wallpaperType == 'image'
            ? Colors.transparent
            : backgroundColor,
        body: Container(
          decoration:
              widget.settingsController?.wallpaperType == 'image' &&
                  widget.settingsController?.wallpaperPath != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(
                      File(widget.settingsController!.wallpaperPath!),
                    ),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Expanded(child: _buildUnifiedChatView()),
                  if (widget.settingsController != null)
                    SlideableTaskInput(
                      dayOfWeek: 'اليوم',
                      onTaskAdded: addTaskToCurrentDay,
                      onTaskRestored: (taskId, dateKey) => restoreTask(taskId),
                      onVoiceTaskAdded: addVoiceTaskToCurrentDay,
                      settingsController: widget.settingsController!,
                    )
                  else
                    ChatInput(
                      dayOfWeek: 'اليوم',
                      onTaskAdded: addTaskToCurrentDay,
                      onTaskRestored: (taskId, dateKey) => restoreTask(taskId),
                      onVoiceTaskAdded: addVoiceTaskToCurrentDay,
                    ),
                ],
              ),
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
      onTaskLongPress: (taskId) => _handleShowTaskOptions(taskId),
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
