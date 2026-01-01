import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';
import '../../responsive.dart';
import '../../core/models/task.dart';
import '../../features/task_management/controllers/task_controller.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
  late List<Subtask> _subtasks;
  final TextEditingController _subtaskController = TextEditingController();

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
  }

  @override
  void dispose() {
    widget.taskController.removeListener(_onTaskUpdated);
    _subtaskController.dispose();
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
    Navigator.pop(context);
  }

  void _showPrioritySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
        decoration: BoxDecoration(
          color: RubyTheme.pureWhite,
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
          color: isSelected ? color.withOpacity(0.1) : RubyTheme.softGray,
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
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
                  'يجب أن يكون الموعد النهائي في المستقبل',
                  style: RubyTheme.bodyMedium(
                    context,
                  ).copyWith(color: RubyTheme.pureWhite),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RubyTheme.softGray,
      appBar: AppBar(
        backgroundColor: RubyTheme.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RubyTheme.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('تفاصيل التاسك', style: RubyTheme.heading2(context)),
        centerTitle: true,
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
              Container(
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
                    // Status badge (tappable to toggle completion)
                    GestureDetector(
                      onTap: _toggleTaskCompletion,
                      child: Row(
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
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            _currentTask.isCompleted ? 'مكتملة' : 'قيد التنفيذ',
                            style: RubyTheme.bodyLarge(context).copyWith(
                              color: RubyTheme.pureWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: RubyTheme.pureWhite.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Task text
                    Text(
                      _currentTask.text,
                      style: RubyTheme.heading2(
                        context,
                      ).copyWith(color: RubyTheme.pureWhite, height: 1.5),
                    ),
                  ],
                ),
              ),

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
                      trailing: Icon(
                        Icons.edit,
                        size: 16,
                        color: RubyTheme.mediumGray,
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
                      trailing: Icon(
                        Icons.edit,
                        size: 16,
                        color: RubyTheme.mediumGray,
                      ),
                    ),
                  ),

                  // Deadline
                  GestureDetector(
                    onTap: _selectDeadline,
                    child: _buildDetailRow(
                      context,
                      icon: Icons.access_time_rounded,
                      label: 'الموعد النهائي',
                      value: _currentTask.deadlineDate != null
                          ? _formatDate(_currentTask.deadlineDate!)
                          : 'غير محدد',
                      valueColor: _currentTask.deadlineDate != null
                          ? RubyTheme.rubyRed
                          : RubyTheme.mediumGray,
                      trailing: Icon(
                        Icons.edit,
                        size: 16,
                        color: RubyTheme.mediumGray,
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
                            ).copyWith(color: RubyTheme.mediumGray),
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
                        direction: DismissDirection.endToStart,
                        background: Container(
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
                            children: [
                              Checkbox(
                                value: subtask.isCompleted,
                                onChanged: (_) => _toggleSubtask(index),
                                activeColor: RubyTheme.emerald,
                              ),
                              Expanded(
                                child: Text(
                                  subtask.text,
                                  style: RubyTheme.bodyMedium(context).copyWith(
                                    decoration: subtask.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: subtask.isCompleted
                                        ? RubyTheme.mediumGray
                                        : RubyTheme.darkGray,
                                  ),
                                ),
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

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      decoration: BoxDecoration(
        color: RubyTheme.pureWhite,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        boxShadow: [
          BoxShadow(
            color: RubyTheme.darkGray.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: RubyTheme.heading2(context).copyWith(
              color: RubyTheme.darkGray,
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
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: Responsive.text(context, size: TextSize.medium),
            color: RubyTheme.mediumGray,
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
                  ).copyWith(color: RubyTheme.mediumGray),
                ),
                SizedBox(
                  height: Responsive.space(context, size: Space.small) / 2,
                ),
                Text(
                  value,
                  style: RubyTheme.bodyLarge(context).copyWith(
                    color: valueColor ?? RubyTheme.darkGray,
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
      return 'اليوم ${DateFormat('HH:mm').format(date)}';
    } else if (dateOnly == yesterday) {
      return 'أمس ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
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
