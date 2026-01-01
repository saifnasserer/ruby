import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';
import '../../core/models/task.dart';

class TaskBubble extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isToday;

  const TaskBubble({
    super.key,
    required this.task,
    this.onTap,
    this.onLongPress,
    this.isToday = false,
  });

  @override
  State<TaskBubble> createState() => _TaskBubbleState();
}

class _TaskBubbleState extends State<TaskBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.5), // Start slightly below
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Only animate if the task is newly created (less than 3 seconds ago)
    final isNew =
        DateTime.now().difference(widget.task.createdAt).inSeconds < 3;
    if (isNew) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: RubyTheme.spacingM(context),
                  vertical: RubyTheme.spacingXS(context),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // RTL alignment
                  children: [
                    // Task bubble
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: RubyTheme.spacingM(context),
                          vertical: RubyTheme.spacingM(context) / 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: widget.task.isCompleted
                              ? null
                              : _getPriorityGradient(),
                          color: widget.task.isCompleted
                              ? RubyTheme.emerald.withOpacity(0.15)
                              : null,
                          borderRadius: BorderRadius.circular(
                            RubyTheme.radiusLarge(context),
                          ),
                          boxShadow: RubyTheme.softShadow,
                          border: widget.task.isCompleted
                              ? Border.all(
                                  color: RubyTheme.emerald.withOpacity(0.3),
                                  width: 1,
                                )
                              : _getPriorityBorder(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Priority indicator bar (left edge)
                            if (!widget.task.isCompleted &&
                                widget.task.priority != TaskPriority.normal)
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            if (!widget.task.isCompleted &&
                                widget.task.priority != TaskPriority.normal)
                              SizedBox(width: RubyTheme.spacingS(context)),

                            // Completion indicator
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: widget.task.isCompleted
                                    ? RubyTheme.emerald
                                    : RubyTheme.pureWhite.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.task.isCompleted
                                    ? Icons.check_rounded
                                    : Icons.circle_outlined,
                                color: widget.task.isCompleted
                                    ? RubyTheme.pureWhite
                                    : RubyTheme.pureWhite.withOpacity(0.8),
                                size: 16,
                              ),
                            ),

                            SizedBox(width: RubyTheme.spacingS(context)),

                            // Task text and metadata
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Task text
                                  Text(
                                    widget.task.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: RubyTheme.bodyLarge(context)
                                        .copyWith(
                                          color: widget.task.isCompleted
                                              ? RubyTheme.darkGray.withOpacity(
                                                  0.7,
                                                )
                                              : RubyTheme.pureWhite,
                                          decoration: widget.task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          fontWeight: widget.task.isCompleted
                                              ? FontWeight.w400
                                              : FontWeight.w500,
                                        ),
                                  ),

                                  // Subtask and Deadline indicators in one row
                                  if (widget.task.subtasks.isNotEmpty ||
                                      (widget.task.deadlineDate != null &&
                                          !widget.task.isCompleted))
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: RubyTheme.spacingXS(context) / 2,
                                      ),
                                      child: Row(
                                        children: [
                                          // Subtask progress indicator
                                          if (widget
                                              .task
                                              .subtasks
                                              .isNotEmpty) ...[
                                            Icon(
                                              Icons.checklist_rounded,
                                              size: 14,
                                              color: widget.task.isCompleted
                                                  ? RubyTheme.darkGray
                                                        .withOpacity(0.5)
                                                  : RubyTheme.pureWhite
                                                        .withOpacity(0.7),
                                            ),
                                            SizedBox(
                                              width:
                                                  RubyTheme.spacingXS(context) /
                                                  2,
                                            ),
                                            Text(
                                              '${widget.task.subtasks.where((s) => s.isCompleted).length}/${widget.task.subtasks.length}',
                                              style: RubyTheme.caption(context)
                                                  .copyWith(
                                                    color:
                                                        widget.task.isCompleted
                                                        ? RubyTheme.darkGray
                                                              .withOpacity(0.5)
                                                        : RubyTheme.pureWhite
                                                              .withOpacity(0.7),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],

                                          // Spacer if both are present to push them apart
                                          if (widget.task.subtasks.isNotEmpty &&
                                              (widget.task.deadlineDate !=
                                                      null &&
                                                  !widget.task.isCompleted))
                                            const Spacer(),

                                          // Deadline indicator
                                          if (widget.task.deadlineDate !=
                                                  null &&
                                              !widget.task.isCompleted)
                                            Builder(
                                              builder: (context) {
                                                final now = DateTime.now();
                                                final deadline =
                                                    widget.task.deadlineDate!;
                                                final daysRemaining = deadline
                                                    .difference(now)
                                                    .inDays;

                                                return Row(
                                                  children: [
                                                    Icon(
                                                      Icons.alarm_rounded,
                                                      size: 14,
                                                      color:
                                                          RubyTheme.pureWhite,
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          RubyTheme.spacingXS(
                                                            context,
                                                          ) /
                                                          2,
                                                    ),
                                                    Text(
                                                      '$daysRemaining يوم للموعد النهائي',
                                                      style:
                                                          RubyTheme.caption(
                                                            context,
                                                          ).copyWith(
                                                            color: RubyTheme
                                                                .pureWhite,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),

                                  // Category and tags
                                  if (widget.task.category != null ||
                                      widget.task.tags.isNotEmpty)
                                    SizedBox(
                                      height: RubyTheme.spacingXS(context) / 2,
                                    ),

                                  if (widget.task.category != null ||
                                      widget.task.tags.isNotEmpty)
                                    Wrap(
                                      spacing: RubyTheme.spacingXS(context),
                                      runSpacing:
                                          RubyTheme.spacingXS(context) / 2,
                                      children: [
                                        // Category badge
                                        if (widget.task.category != null)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  RubyTheme.spacingS(context) /
                                                  2,
                                              vertical:
                                                  RubyTheme.spacingXS(context) /
                                                  2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: widget.task.isCompleted
                                                  ? RubyTheme.mediumGray
                                                        .withOpacity(0.3)
                                                  : RubyTheme.pureWhite
                                                        .withOpacity(0.25),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    RubyTheme.radiusSmall(
                                                      context,
                                                    ),
                                                  ),
                                            ),
                                            child: Text(
                                              widget.task.category!,
                                              style: RubyTheme.caption(context)
                                                  .copyWith(
                                                    color:
                                                        widget.task.isCompleted
                                                        ? RubyTheme.darkGray
                                                              .withOpacity(0.6)
                                                        : RubyTheme.pureWhite
                                                              .withOpacity(0.9),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),

                                        // Tag chips
                                        ...widget.task.tags.map(
                                          (tag) => Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  RubyTheme.spacingS(context) /
                                                  2,
                                              vertical:
                                                  RubyTheme.spacingXS(context) /
                                                  2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: widget.task.isCompleted
                                                  ? RubyTheme.mediumGray
                                                        .withOpacity(0.2)
                                                  : RubyTheme.pureWhite
                                                        .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    RubyTheme.radiusSmall(
                                                      context,
                                                    ),
                                                  ),
                                              border: Border.all(
                                                color: widget.task.isCompleted
                                                    ? RubyTheme.mediumGray
                                                          .withOpacity(0.3)
                                                    : RubyTheme.pureWhite
                                                          .withOpacity(0.3),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              tag,
                                              style: RubyTheme.caption(context)
                                                  .copyWith(
                                                    color:
                                                        widget.task.isCompleted
                                                        ? RubyTheme.darkGray
                                                              .withOpacity(0.5)
                                                        : RubyTheme.pureWhite
                                                              .withOpacity(0.8),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: RubyTheme.spacingS(context)),
                    // Time stamp and migration indicator
                    if (widget.isToday)
                      Container(
                        margin: EdgeInsets.only(
                          left: RubyTheme.spacingS(context),
                          top: RubyTheme.spacingXS(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(widget.task.createdAt),
                              style: RubyTheme.caption(
                                context,
                              ).copyWith(color: RubyTheme.mediumGray),
                            ),
                            if (widget.task.isMigrated)
                              Container(
                                margin: EdgeInsets.only(top: 2),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: RubyTheme.rubyRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'متأخر',
                                  style: RubyTheme.caption(context).copyWith(
                                    color: RubyTheme.rubyRed,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (taskDate == today) {
      // Today - show time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  // Get gradient based on priority
  Gradient _getPriorityGradient() {
    switch (widget.task.priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHighGradient;
      case TaskPriority.normal:
        return RubyTheme.priorityLowGradient;
    }
  }

  // Get priority color for indicator bar
  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHigh;
      case TaskPriority.normal:
        return RubyTheme.priorityLow;
    }
  }

  // Get priority border
  Border? _getPriorityBorder() {
    if (widget.task.priority == TaskPriority.normal) return null;
    return Border.all(color: _getPriorityColor().withOpacity(0.3), width: 1);
  }
}
