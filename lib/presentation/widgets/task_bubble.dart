import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/theme/ruby_theme.dart';

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
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _animationController.forward();
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
        return Transform.scale(
          scale: _scaleAnimation.value,
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
                              : RubyTheme.rubyGradient,
                          color: widget.task.isCompleted
                              ? RubyTheme.emerald.withOpacity(0.15)
                              : null,
                          borderRadius: BorderRadius.circular(
                            RubyTheme.radiusLarge(context),
                          ), // Completely rounded
                          boxShadow: RubyTheme.softShadow,
                          border: widget.task.isCompleted
                              ? Border.all(
                                  color: RubyTheme.emerald.withOpacity(0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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

                            // Completion indicator
                            SizedBox(width: RubyTheme.spacingS(context)),

                            // Task text
                            Flexible(
                              child: Text(
                                widget.task.text,
                                style: RubyTheme.bodyLarge(context).copyWith(
                                  color: widget.task.isCompleted
                                      ? RubyTheme.darkGray.withOpacity(0.7)
                                      : RubyTheme.pureWhite,
                                  decoration: widget.task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: widget.task.isCompleted
                                      ? FontWeight.w400
                                      : FontWeight.w500,
                                ),
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
}
