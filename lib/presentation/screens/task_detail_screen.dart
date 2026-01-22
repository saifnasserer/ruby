import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/ruby_theme.dart';
import '../../responsive.dart';
import '../../core/models/task.dart';
import '../../features/task_management/controllers/task_controller.dart';
import '../widgets/confirmation_dialog.dart';
import 'task_detail/widgets/task_detail_title_and_audio.dart';
import 'task_detail/widgets/task_detail_properties.dart';
import 'task_detail/widgets/task_detail_subtasks.dart';

/// Full-screen task detail view
class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final TaskController taskController;
  final String dateKey;
  final VoidCallback? onTaskUpdated;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.taskController,
    required this.dateKey,
    this.onTaskUpdated,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _subtaskController;
  late List<Subtask> _subtasks;
  Task? _currentTask;
  late String _currentDateKey; // Track current date key

  @override
  void initState() {
    super.initState();
    _subtaskController = TextEditingController();
    _currentTask = widget.task;
    _currentDateKey = widget.dateKey; // Initialize with original date key
    _subtasks = List.from(_currentTask!.subtasks);

    // Load subtask draft
    final draft = widget.taskController.getSubtaskDraft(widget.task.id);
    _subtaskController.text = draft;
  }

  @override
  void dispose() {
    // Save subtask draft
    widget.taskController.setSubtaskDraft(
      widget.task.id,
      _subtaskController.text,
    );
    _subtaskController.dispose();
    super.dispose();
  }

  void _onTaskUpdated() {
    widget.onTaskUpdated?.call();
    if (mounted) {
      setState(() {
        // Refresh task data ensuring we have the latest state
        final currentId = _currentTask?.id ?? widget.task.id;

        // Search for the task across all dates to find its current location
        Task? updatedTask;
        String? foundDateKey;

        for (final entry in widget.taskController.tasks.entries) {
          final task = entry.value.cast<Task?>().firstWhere(
            (t) => t?.id == currentId,
            orElse: () => null,
          );
          if (task != null) {
            updatedTask = task;
            foundDateKey = entry.key;
            break;
          }
        }

        if (updatedTask != null && foundDateKey != null) {
          _currentTask = updatedTask;
          _currentDateKey = foundDateKey; // Update current date key
          _subtasks = List.from(_currentTask!.subtasks);
        }
      });
    }
  }

  void _saveSubtasks() {
    widget.taskController.updateTaskSubtasks(
      _currentDateKey,
      widget.task.id,
      _subtasks,
    );
    _onTaskUpdated();
  }

  void _addSubtask(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _subtasks.add(
        Subtask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      // Clear draft
      widget.taskController.setSubtaskDraft(widget.task.id, '');
      _subtaskController.clear();
    });
    _saveSubtasks();
  }

  void _updateSubtask(int index, Subtask subtask) {
    setState(() {
      _subtasks[index] = subtask;
    });
    _saveSubtasks();
  }

  void _deleteSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
    _saveSubtasks();
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showConfirmationDialog(
      context: context,
      title: 'هل أنت متأكد من حذف هذه التاسك؟',
      message: 'لا يمكن التراجع عن هذا الإجراء.',
      onConfirm: () {
        widget.taskController.deleteTask(_currentDateKey, widget.task.id);
        widget.onTaskUpdated?.call();
        Navigator.pop(context); // Close detail screen
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine status bar style
    final brightness = Theme.of(context).brightness;
    final systemOverlayStyle = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    final taskToDisplay = _currentTask ?? widget.task;

    return Scaffold(
      backgroundColor: RubyTheme.background(context),
      appBar: AppBar(
        backgroundColor: RubyTheme.background(context),
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: systemOverlayStyle,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RubyTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              (taskToDisplay.isPinned)
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              color: RubyTheme.sapphire,
            ),
            onPressed: () {
              widget.taskController.toggleTaskPin(
                _currentDateKey,
                widget.task.id,
              );
              _onTaskUpdated();
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: RubyTheme.priorityHigh),
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
          SizedBox(width: 8),
        ],
        title: Text('تفاصيل التاسك', style: RubyTheme.heading2(context)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  RubyTheme.rubyRed.withOpacity(0.1),
                  RubyTheme.emerald.withOpacity(0.1),
                  RubyTheme.sapphire.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title, Completion, Audio
              TaskDetailTitleAndAudio(
                task: taskToDisplay,
                taskController: widget.taskController,
                dateKey: _currentDateKey,
                onTaskUpdated: _onTaskUpdated,
              ),

              SizedBox(height: Responsive.space(context, size: Space.large)),

              // Properties (Category, Priority, Deadline, Move)
              TaskDetailProperties(
                task: taskToDisplay,
                taskController: widget.taskController,
                dateKey: _currentDateKey,
                onTaskUpdated: _onTaskUpdated,
              ),

              SizedBox(height: Responsive.space(context, size: Space.large)),

              // Subtasks
              TaskDetailSubtasks(
                subtasks: _subtasks,
                subtaskController: _subtaskController,
                onAdd: _addSubtask,
                onUpdate: _updateSubtask,
                onDelete: _deleteSubtask,
              ),

              // Extra bottom padding
              SizedBox(height: Responsive.space(context, size: Space.xlarge)),
            ],
          ),
        ),
      ),
    );
  }
}
