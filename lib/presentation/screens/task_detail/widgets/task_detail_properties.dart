import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/ruby_theme.dart';
import '../../../../responsive.dart';
import '../../../../core/models/task.dart';
import '../../../../features/task_management/controllers/task_controller.dart';
import '../../../../core/utils/date_formatter.dart';

class TaskDetailProperties extends StatefulWidget {
  final Task task;
  final TaskController taskController;
  final String dateKey;
  final VoidCallback onTaskUpdated;

  const TaskDetailProperties({
    super.key,
    required this.task,
    required this.taskController,
    required this.dateKey,
    required this.onTaskUpdated,
  });

  @override
  State<TaskDetailProperties> createState() => _TaskDetailPropertiesState();
}

class _TaskDetailPropertiesState extends State<TaskDetailProperties> {
  Color _getPriorityColorForPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHigh;
      case TaskPriority.normal:
        return RubyTheme.sapphire;
    }
  }

  Future<void> _moveTask() async {
    final now = DateTime.now();
    final taskCreationDate = widget.task.createdAt;

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
        widget.onTaskUpdated();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم نقل التاسك بنجاح',
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
        widget.task.deadlineDate ?? now.add(const Duration(days: 1));

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
        initialTime: TimeOfDay.fromDateTime(widget.task.deadlineDate ?? now),
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
          widget.onTaskUpdated();
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
    widget.onTaskUpdated();

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'النهاردة ${DateFormatter.formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'امبارح ${DateFormatter.formatTime(date)}';
    } else {
      return '${DateFormat('dd/MM/yyyy').format(date)} ${DateFormatter.formatTime(date)}';
    }
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
        widget.onTaskUpdated();
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
                    widget.task.priority == TaskPriority.normal,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                Expanded(
                  child: _buildPriorityOption(
                    context,
                    TaskPriority.important,
                    widget.task.priority == TaskPriority.important,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.space(context, size: Space.medium),
            right: Responsive.space(context, size: Space.small),
          ),
          child: Text(
            'التفاصيل',
            style: RubyTheme.heading2(context).copyWith(
              color: RubyTheme.textPrimary(context),
              fontSize: Responsive.text(context, size: TextSize.medium),
            ),
          ),
        ),
        // Priority Row
        GestureDetector(
          onTap: _showPrioritySelector,
          child: _buildDetailRow(
            context,
            icon: Icons.flag_outlined,
            label: 'الأولوية',
            value: widget.task.priority.displayName,
            valueColor: _getPriorityColorForPriority(widget.task.priority),
            isClickable: true,
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, size: Space.small),
                vertical: Responsive.space(context, size: Space.small) / 2,
              ),
              decoration: BoxDecoration(
                color: RubyTheme.sapphire.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 14, color: RubyTheme.sapphire),
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

        if (widget.task.category != null)
          _buildDetailRow(
            context,
            icon: Icons.category_outlined,
            label: 'الفئة',
            value: widget.task.category!,
          ),

        // Move Task
        GestureDetector(
          onTap: _moveTask,
          child: _buildDetailRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'تاريخ التاسك (نقل)',
            value: _formatDate(widget.task.createdAt),
            isClickable: true,
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, size: Space.small),
                vertical: Responsive.space(context, size: Space.small) / 2,
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
            value: widget.task.deadlineDate != null
                ? _formatDate(widget.task.deadlineDate!)
                : 'غير محدد',
            valueColor: widget.task.deadlineDate != null
                ? RubyTheme.rubyRed
                : RubyTheme.mediumGray,
            isClickable: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.task.deadlineDate != null) ...[
                  GestureDetector(
                    onTap: () {
                      _resetDeadline();
                    },
                    child: Container(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.small) / 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.close, size: 16, color: Colors.red),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                ],
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.small),
                    vertical: Responsive.space(context, size: Space.small) / 2,
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
                        widget.task.deadlineDate != null ? 'تعديل' : 'تحديد',
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

        if (widget.task.completedAt != null)
          _buildDetailRow(
            context,
            icon: Icons.check_circle_outline,
            label: 'تاريخ الإكمال',
            value: _formatDate(widget.task.completedAt!),
          ),

        // Tags Section (Keep this in card)
        if (widget.task.tags.isNotEmpty) ...[
          SizedBox(height: Responsive.space(context, size: Space.large)),
          Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.space(context, size: Space.medium),
              right: Responsive.space(context, size: Space.small),
            ),
            child: Text(
              'الوسوم',
              style: RubyTheme.heading2(context).copyWith(
                color: RubyTheme.textPrimary(context),
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
          ),
          Wrap(
            spacing: Responsive.space(context, size: Space.small),
            runSpacing: Responsive.space(context, size: Space.small),
            children: widget.task.tags.map((tag) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                  vertical: Responsive.space(context, size: Space.small),
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
      ],
    );
  }
}
