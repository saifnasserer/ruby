import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/ruby_theme.dart';
import '../../responsive.dart';
import '../../core/models/task.dart';
import '../../features/task_management/controllers/task_controller.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/utils/date_formatter.dart';

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

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late List<Subtask> _subtasks;
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _transcriptionController =
      TextEditingController();
  final TextEditingController _taskTextController = TextEditingController();
  bool _isEditingTaskText = false;

  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Animation for completion toggle
  late AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;

  // Get current task from controller to reflect updates
  Task get _currentTask {
    final tasks = widget.taskController.getTasksForDate(widget.dateKey);
    return tasks.firstWhere(
      (t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );
  }

  @override
  void initState() {
    super.initState();
    _subtasks = List.from(widget.task.subtasks);

    // Listen to task controller changes
    widget.taskController.addListener(_onTaskUpdated);

    _transcriptionController.text = widget.task.text;
    _taskTextController.text = widget.task.text;

    // Load saved draft if exists
    final savedDraft = widget.taskController.getSubtaskDraft(widget.task.id);
    if (savedDraft.isNotEmpty) {
      _subtaskController.text = savedDraft;
    }

    // Initialize scale animation
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _setupAudioPlayer();
    _initAudioSource();
  }

  Future<void> _initAudioSource() async {
    if (widget.task.audioPath != null) {
      await _audioPlayer.setSource(DeviceFileSource(widget.task.audioPath!));
    }
  }

  void _setupAudioPlayer() {
    if (widget.task.audioPath == null) return;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _toggleAudio() async {
    if (widget.task.audioPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _saveTranscription(String text) {
    widget.taskController.editTask(widget.dateKey, widget.task.id, text);
    widget.onTaskUpdated?.call();
  }

  @override
  void dispose() {
    widget.taskController.removeListener(_onTaskUpdated);

    // Save draft text to controller instead of auto-adding
    widget.taskController.setSubtaskDraft(
      widget.task.id,
      _subtaskController.text,
    );

    _subtaskController.dispose();
    _transcriptionController.dispose();
    _taskTextController.dispose();
    _scaleAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onTaskUpdated() {
    setState(() {
      // Rebuild to show updated task data
    });
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isEmpty) return;

    setState(() {
      _subtasks.add(
        Subtask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: _subtaskController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      // Clear draft
      widget.taskController.setSubtaskDraft(widget.task.id, '');
      _subtaskController.clear();
    });
    _saveSubtasks();
  }

  void _toggleSubtask(int index) {
    setState(() {
      _subtasks[index] = _subtasks[index].copyWith(
        isCompleted: !_subtasks[index].isCompleted,
      );
    });
    _saveSubtasks();
  }

  void _deleteSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
    _saveSubtasks();
  }

  void _showEditSubtaskDialog(int index) {
    final TextEditingController textController = TextEditingController(
      text: _subtasks[index].text,
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: RubyTheme.surface(context),
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 10,
                minLines: 1,
                autofocus: true,
                textDirection: TextDirection.rtl,
                style: RubyTheme.bodyMedium(context),
                decoration: InputDecoration(
                  hintText: 'نص المهمة الفرعية...',
                  hintStyle: RubyTheme.bodyMedium(
                    context,
                  ).copyWith(color: RubyTheme.textSecondary(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: RubyTheme.mediumGray.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: RubyTheme.mediumGray.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: RubyTheme.sapphire, width: 2),
                  ),
                  filled: true,
                  fillColor: RubyTheme.surfaceVariant(context),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: RubyTheme.surfaceVariant(context),
              ),
              icon: Icon(
                Icons.close,
                color: RubyTheme.textSecondary(context),
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () {
                final newText = textController.text.trim();
                if (newText.isNotEmpty) {
                  setState(() {
                    _subtasks[index] = _subtasks[index].copyWith(text: newText);
                  });
                  _saveSubtasks();
                }
                Navigator.pop(context);
              },
              style: IconButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: RubyTheme.sapphire,
              ),
              icon: Icon(Icons.check, color: RubyTheme.pureWhite, size: 20),
            ),
          ],
          actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 12),
        ),
      ),
    );
  }

  void _showSubtaskDescriptionDialog(int index) {
    final TextEditingController descriptionController = TextEditingController(
      text: _subtasks[index].description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: RubyTheme.surface(context),
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                maxLines: 10,
                minLines: 2,
                autofocus: true,
                textDirection: TextDirection.rtl,
                style: RubyTheme.bodyMedium(context),
                decoration: InputDecoration(
                  hintText: 'وصف...',
                  hintStyle: RubyTheme.bodyMedium(
                    context,
                  ).copyWith(color: RubyTheme.mediumGray),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: RubyTheme.mediumGray.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: RubyTheme.mediumGray.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: RubyTheme.sapphire, width: 2),
                  ),
                  filled: true,
                  fillColor: RubyTheme.surfaceVariant(context),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: RubyTheme.softGray,
              ),
              icon: Icon(Icons.close, color: RubyTheme.mediumGray, size: 20),
            ),
            IconButton(
              onPressed: () {
                final newDescription = descriptionController.text.trim();
                setState(() {
                  _subtasks[index] = _subtasks[index].copyWith(
                    description: newDescription.isEmpty
                        ? const NullableValue(null)
                        : newDescription,
                  );
                });
                _saveSubtasks();
                Navigator.pop(context);
              },
              style: IconButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: RubyTheme.sapphire,
              ),
              icon: Icon(Icons.check, color: RubyTheme.pureWhite, size: 20),
            ),
          ],
          actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 12),
        ),
      ),
    );
  }

  void _saveSubtasks() {
    // Update the task with new subtasks
    widget.taskController.updateTaskSubtasks(
      widget.dateKey,
      widget.task.id,
      _subtasks,
    );
    widget.onTaskUpdated?.call();
  }

  void _toggleTaskCompletion() {
    widget.taskController.toggleTaskCompletion(widget.dateKey, widget.task.id);
    widget.onTaskUpdated?.call();
    // Don't navigate away - let user stay on detail screen
  }

  void _showPrioritySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
        decoration: BoxDecoration(
          color: RubyTheme.surface(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              Responsive.space(context, size: Space.large),
            ),
            topRight: Radius.circular(
              Responsive.space(context, size: Space.large),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تغيير الأولوية', style: RubyTheme.heading2(context)),
            SizedBox(height: Responsive.space(context, size: Space.large)),
            Row(
              children: [
                Expanded(
                  child: _buildPriorityOption(
                    context,
                    TaskPriority.normal,
                    _currentTask.priority == TaskPriority.normal,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                Expanded(
                  child: _buildPriorityOption(
                    context,
                    TaskPriority.important,
                    _currentTask.priority == TaskPriority.important,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityOption(
    BuildContext context,
    TaskPriority priority,
    bool isSelected,
  ) {
    final color = _getPriorityColorForPriority(priority);
    return GestureDetector(
      onTap: () {
        widget.taskController.updateTaskPriority(
          widget.dateKey,
          widget.task.id,
          priority,
        );
        widget.onTaskUpdated?.call();
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: Responsive.space(context, size: Space.medium),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : RubyTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              priority == TaskPriority.important
                  ? Icons.flag_rounded
                  : Icons.flag_outlined,
              color: isSelected ? color : RubyTheme.mediumGray,
              size: 28,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              priority.displayName,
              style: RubyTheme.bodyLarge(context).copyWith(
                color: isSelected ? color : RubyTheme.darkGray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColorForPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHigh;
      case TaskPriority.normal:
        return RubyTheme.priorityMedium;
      case TaskPriority.normal:
        return RubyTheme.priorityLow;
      case TaskPriority.normal:
        return RubyTheme.sapphire;
    }
  }

  Future<void> _moveTask() async {
    final now = DateTime.now();
    final taskCreationDate = _currentTask.createdAt;

    // Calculate valid date range: from creation date to today
    final firstValidDate = DateTime(
      taskCreationDate.year,
      taskCreationDate.month,
      taskCreationDate.day,
    );
    final lastValidDate = DateTime(now.year, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: lastValidDate,
      firstDate: firstValidDate,
      lastDate: lastValidDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: RubyTheme.rubyRed,
              onPrimary: RubyTheme.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      // Calculate date key for the picked date
      final newDateKey =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

      if (newDateKey != widget.dateKey) {
        // Move task
        widget.taskController.moveTask(
          widget.dateKey,
          newDateKey,
          widget.task.id,
        );

        // Notify and pop
        widget.onTaskUpdated?.call();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم نقل المهمة بنجاح',
              style: RubyTheme.bodyMedium(
                context,
              ).copyWith(color: RubyTheme.pureWhite),
            ),
            backgroundColor: RubyTheme.emerald,
          ),
        );
      }
    }
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final initialDate =
        _currentTask.deadlineDate ?? now.add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now)
          ? now.add(const Duration(days: 1))
          : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: RubyTheme.rubyRed,
              onPrimary: RubyTheme.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_currentTask.deadlineDate ?? now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: RubyTheme.rubyRed,
                onPrimary: RubyTheme.pureWhite,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (selectedDateTime.isAfter(now)) {
          widget.taskController.updateTaskDeadline(
            widget.dateKey,
            widget.task.id,
            selectedDateTime,
          );
          widget.onTaskUpdated?.call();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'يجب أن يكون الديدلاين في المستقبل',
                  style: RubyTheme.bodyMedium(
                    context,
                  ).copyWith(color: RubyTheme.pureWhite),
                ),
                backgroundColor: RubyTheme.priorityHigh,
              ),
            );
          }
        }
      }
    }
  }

  void _resetDeadline() {
    widget.taskController.updateTaskDeadline(
      widget.dateKey,
      widget.task.id,
      null,
    );
    widget.onTaskUpdated?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إلغاء الديدلاين',
            style: RubyTheme.bodyMedium(
              context,
            ).copyWith(color: RubyTheme.pureWhite),
          ),
          backgroundColor: RubyTheme.emerald,
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: RubyTheme.surface(context),
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'هل أنت متأكد من حذف هذه المهمة؟',
                style: RubyTheme.heading2(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'لا يمكن التراجع عن هذا الإجراء.',
                style: RubyTheme.bodyMedium(
                  context,
                ).copyWith(color: RubyTheme.mediumGray),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: RubyTheme.softGray,
              ),
              icon: Icon(Icons.close, color: RubyTheme.mediumGray, size: 20),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                widget.taskController.deleteTask(
                  widget.dateKey,
                  widget.task.id,
                );
                widget.onTaskUpdated?.call();
                Navigator.pop(context); // Close detail screen
              },
              style: IconButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: RubyTheme.priorityHigh,
              ),
              icon: Icon(
                Icons.delete_outline,
                color: RubyTheme.pureWhite,
                size: 20,
              ),
            ),
          ],
          actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RubyTheme.background(context),
      appBar: AppBar(
        backgroundColor: RubyTheme.background(context),
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RubyTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
              // Task status card
              ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () async {
                    // Don't toggle completion if in edit mode
                    if (_isEditingTaskText) return;

                    // Animate scale down then up
                    await _scaleAnimationController.forward();
                    await _scaleAnimationController.reverse();
                    _toggleTaskCompletion();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.large),
                    ),
                    decoration: BoxDecoration(
                      gradient: _currentTask.isCompleted
                          ? LinearGradient(
                              colors: [
                                RubyTheme.emerald,
                                RubyTheme.emerald.withOpacity(0.8),
                              ],
                            )
                          : _getPriorityGradient(),
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.medium),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_currentTask.isCompleted
                                      ? RubyTheme.emerald
                                      : _getPriorityColor())
                                  .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge and edit button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Status badge
                            Row(
                              children: [
                                Icon(
                                  _currentTask.isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: RubyTheme.pureWhite,
                                  size: Responsive.text(
                                    context,
                                    size: TextSize.heading,
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(
                                  _currentTask.isCompleted
                                      ? 'مكتملة'
                                      : 'قيد التنفيذ',
                                  style: RubyTheme.bodyLarge(context).copyWith(
                                    color: RubyTheme.pureWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Icon(
                                  Icons.touch_app,
                                  size: 16,
                                  color: RubyTheme.pureWhite.withOpacity(0.5),
                                ),
                              ],
                            ),

                            // Edit button (only show for non-audio tasks)
                            if (widget.task.audioPath == null)
                              GestureDetector(
                                onTap: () {
                                  if (_isEditingTaskText) {
                                    // Save the changes when clicking checkmark
                                    final newText = _taskTextController.text
                                        .trim();
                                    if (newText.isNotEmpty &&
                                        newText != _currentTask.text) {
                                      widget.taskController.editTask(
                                        widget.dateKey,
                                        widget.task.id,
                                        newText,
                                      );
                                      widget.onTaskUpdated?.call();
                                    }
                                  }
                                  setState(() {
                                    _isEditingTaskText = !_isEditingTaskText;
                                    if (_isEditingTaskText) {
                                      _taskTextController.text =
                                          _currentTask.text;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: RubyTheme.pureWhite.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isEditingTaskText
                                        ? Icons.check
                                        : Icons.edit,
                                    color: RubyTheme.pureWhite,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),

                        // Task text (editable or display)
                        if (widget.task.audioPath != null)
                          _buildAudioPlayerDetail()
                        else if (_isEditingTaskText)
                          TextField(
                            controller: _taskTextController,
                            maxLines: null,
                            autofocus: true,
                            textDirection: TextDirection.rtl,
                            style: RubyTheme.heading2(
                              context,
                            ).copyWith(color: RubyTheme.pureWhite, height: 1.5),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: RubyTheme.pureWhite.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: RubyTheme.pureWhite.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: RubyTheme.pureWhite,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: RubyTheme.pureWhite.withOpacity(0.1),
                            ),
                            onSubmitted: (value) {
                              final trimmedValue = value.trim();
                              if (trimmedValue.isNotEmpty &&
                                  trimmedValue != _currentTask.text) {
                                widget.taskController.editTask(
                                  widget.dateKey,
                                  widget.task.id,
                                  trimmedValue,
                                );
                                widget.onTaskUpdated?.call();
                              }
                              setState(() {
                                _isEditingTaskText = false;
                              });
                            },
                          )
                        else
                          Text(
                            _currentTask.text,
                            style: RubyTheme.heading2(
                              context,
                            ).copyWith(color: RubyTheme.pureWhite, height: 1.5),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (widget.task.audioPath != null) ...[
                SizedBox(height: Responsive.space(context, size: Space.large)),
                _buildDetailCard(
                  context,
                  title: 'التاسك',
                  children: [
                    TextField(
                      controller: _transcriptionController,
                      maxLines: null,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'اكتب التاسك هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: RubyTheme.surfaceVariant(context),
                      ),
                      onChanged: _saveTranscription,
                    ),
                  ],
                ),
              ],

              SizedBox(height: Responsive.space(context, size: Space.large)),

              // Details section
              _buildDetailCard(
                context,
                title: 'التفاصيل',
                children: [
                  GestureDetector(
                    onTap: _showPrioritySelector,
                    child: _buildDetailRow(
                      context,
                      icon: Icons.flag_outlined,
                      label: 'الأولوية',
                      value: _currentTask.priority.displayName,
                      valueColor: _getPriorityColor(),
                      isClickable: true,
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          vertical:
                              Responsive.space(context, size: Space.small) / 2,
                        ),
                        decoration: BoxDecoration(
                          color: RubyTheme.sapphire.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: RubyTheme.sapphire,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'تعديل',
                              style: RubyTheme.caption(context).copyWith(
                                color: RubyTheme.sapphire,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_currentTask.category != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.category_outlined,
                      label: 'الفئة',
                      value: _currentTask.category!,
                    ),
                  // Task Date (Move Task)
                  GestureDetector(
                    onTap: _moveTask,
                    child: _buildDetailRow(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: 'تاريخ المهمة (نقل)',
                      value: _formatDate(_currentTask.createdAt),
                      isClickable: true,
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          vertical:
                              Responsive.space(context, size: Space.small) / 2,
                        ),
                        decoration: BoxDecoration(
                          color: RubyTheme.emerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.drive_file_move_outlined,
                              size: 14,
                              color: RubyTheme.emerald,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'نقل',
                              style: RubyTheme.caption(context).copyWith(
                                color: RubyTheme.emerald,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Deadline
                  GestureDetector(
                    onTap: _selectDeadline,
                    child: _buildDetailRow(
                      context,
                      icon: Icons.access_time_rounded,
                      label: 'الديدلاين',
                      value: _currentTask.deadlineDate != null
                          ? _formatDate(_currentTask.deadlineDate!)
                          : 'غير محدد',
                      valueColor: _currentTask.deadlineDate != null
                          ? RubyTheme.rubyRed
                          : RubyTheme.mediumGray,
                      isClickable: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentTask.deadlineDate != null) ...[
                            GestureDetector(
                              onTap: () {
                                _resetDeadline();
                              },
                              child: Container(
                                padding: EdgeInsets.all(
                                  Responsive.space(context, size: Space.small) /
                                      2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              vertical:
                                  Responsive.space(context, size: Space.small) /
                                  2,
                            ),
                            decoration: BoxDecoration(
                              color: RubyTheme.rubyRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_calendar,
                                  size: 14,
                                  color: RubyTheme.rubyRed,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _currentTask.deadlineDate != null
                                      ? 'تعديل'
                                      : 'تحديد',
                                  style: RubyTheme.caption(context).copyWith(
                                    color: RubyTheme.rubyRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_currentTask.completedAt != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.check_circle_outline,
                      label: 'تاريخ الإكمال',
                      value: _formatDate(_currentTask.completedAt!),
                    ),
                ],
              ),

              // Tags section
              if (_currentTask.tags.isNotEmpty) ...[
                SizedBox(height: Responsive.space(context, size: Space.large)),
                _buildDetailCard(
                  context,
                  title: 'الوسوم',
                  children: [
                    Wrap(
                      spacing: Responsive.space(context, size: Space.small),
                      runSpacing: Responsive.space(context, size: Space.small),
                      children: _currentTask.tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                            vertical: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                RubyTheme.sapphire.withOpacity(0.1),
                                RubyTheme.sapphire.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                            border: Border.all(
                              color: RubyTheme.sapphire.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: RubyTheme.bodyMedium(context).copyWith(
                              color: RubyTheme.sapphire,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],

              // Subtasks section
              SizedBox(height: Responsive.space(context, size: Space.large)),
              _buildDetailCard(
                context,
                title:
                    'المهام الفرعية (${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length})',
                children: [
                  // Add subtask input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          textDirection: TextDirection.rtl,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'أضف مهمة فرعية...',
                            hintStyle: RubyTheme.bodyMedium(
                              context,
                            ).copyWith(color: RubyTheme.textSecondary(context)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.medium),
                              ),
                              borderSide: BorderSide(
                                color: RubyTheme.mediumGray.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                              vertical: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      IconButton(
                        onPressed: _addSubtask,
                        icon: Icon(
                          Icons.add_circle,
                          color: RubyTheme.sapphire,
                          size: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Subtasks list
                  if (_subtasks.isNotEmpty) ...[
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    ..._subtasks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final subtask = entry.value;

                      return Dismissible(
                        key: Key(subtask.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(
                            right: Responsive.space(context, size: Space.large),
                          ),
                          decoration: BoxDecoration(
                            color: RubyTheme.sapphire.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.small),
                            ),
                          ),
                          child: Icon(Icons.edit, color: RubyTheme.sapphire),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(
                            left: Responsive.space(context, size: Space.large),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.small),
                            ),
                          ),
                          child: Icon(Icons.delete, color: Colors.red),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Edit action
                            _showEditSubtaskDialog(index);
                            return false; // Don't dismiss
                          }
                          return true; // Allow dismiss for delete
                        },
                        onDismissed: (_) => _deleteSubtask(index),
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                          ),
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          decoration: BoxDecoration(
                            color: subtask.isCompleted
                                ? RubyTheme.emerald.withOpacity(0.05)
                                : RubyTheme.softGray,
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.xlarge),
                            ),
                            border: Border.all(
                              color: subtask.isCompleted
                                  ? RubyTheme.emerald.withOpacity(0.3)
                                  : RubyTheme.mediumGray.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: subtask.isCompleted,
                                onChanged: (_) => _toggleSubtask(index),
                                activeColor: RubyTheme.emerald,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 12),
                                    Text(
                                      subtask.text,
                                      style: RubyTheme.bodyMedium(context)
                                          .copyWith(
                                            decoration: subtask.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: subtask.isCompleted
                                                ? RubyTheme.mediumGray
                                                : RubyTheme.darkGray,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (subtask.description != null &&
                                        subtask.description!.isNotEmpty &&
                                        !subtask.isCompleted) ...[
                                      SizedBox(
                                        height:
                                            Responsive.space(
                                              context,
                                              size: Space.small,
                                            ) /
                                            2,
                                      ),
                                      Text(
                                        subtask.description!,
                                        style: RubyTheme.caption(context)
                                            .copyWith(
                                              color: subtask.isCompleted
                                                  ? RubyTheme.mediumGray
                                                        .withOpacity(0.7)
                                                  : RubyTheme.mediumGray,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  subtask.description != null &&
                                          subtask.description!.isNotEmpty
                                      ? Icons.info
                                      : Icons.info_outline,
                                  size: 20,
                                  color:
                                      subtask.description != null &&
                                          subtask.description!.isNotEmpty
                                      ? RubyTheme.sapphire
                                      : RubyTheme.mediumGray,
                                ),
                                onPressed: () =>
                                    _showSubtaskDescriptionDialog(index),
                                tooltip: 'إضافة/تعديل الوصف',
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayerDetail() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RubyTheme.rubyRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: RubyTheme.primary(context),
            ),
            onPressed: _toggleAudio,
            iconSize: 40,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: RubyTheme.primary(context),
                inactiveTrackColor: RubyTheme.textSecondary(
                  context,
                ).withOpacity(0.2),
                thumbColor: RubyTheme.primary(context),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble() > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: (value) {
                  setState(() {
                    _position = Duration(milliseconds: value.toInt());
                  });
                },
                onChangeEnd: (value) async {
                  final position = Duration(milliseconds: value.toInt());
                  try {
                    await _audioPlayer.seek(position);
                  } catch (e) {
                    print('Error seeking: $e');
                  }
                },
              ),
            ),
          ),
          Text(
            '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
            style: RubyTheme.caption(context).copyWith(
              color: RubyTheme.primary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        boxShadow: RubyTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: RubyTheme.heading2(context).copyWith(
              color: RubyTheme.textPrimary(context),
              fontSize: Responsive.text(context, size: TextSize.medium),
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
    bool isClickable = false,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: isClickable
            ? RubyTheme.surfaceVariant(context).withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: isClickable
            ? Border.all(
                color: RubyTheme.textSecondary(context).withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: Responsive.text(context, size: TextSize.medium),
            color: isClickable
                ? RubyTheme.textPrimary(context)
                : RubyTheme.textSecondary(context),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: RubyTheme.caption(
                    context,
                  ).copyWith(color: RubyTheme.textSecondary(context)),
                ),
                SizedBox(
                  height: Responsive.space(context, size: Space.small) / 2,
                ),
                Text(
                  value,
                  style: RubyTheme.bodyLarge(context).copyWith(
                    color: valueColor ?? RubyTheme.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'اليوم ${DateFormatter.formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'أمس ${DateFormatter.formatTime(date)}';
    } else {
      return '${DateFormat('dd/MM/yyyy').format(date)} ${DateFormatter.formatTime(date)}';
    }
  }

  Color _getPriorityColor() {
    switch (_currentTask.priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHigh;
      case TaskPriority.normal:
        return RubyTheme.sapphire;
    }
  }

  Gradient _getPriorityGradient() {
    switch (_currentTask.priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHighGradient;
      case TaskPriority.normal:
        return LinearGradient(
          colors: [RubyTheme.sapphire, RubyTheme.sapphire.withOpacity(0.8)],
        );
    }
  }
}
