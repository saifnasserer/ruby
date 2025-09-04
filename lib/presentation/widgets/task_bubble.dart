import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/theme/ruby_theme.dart';

class TaskBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: RubyTheme.spacingM(context),
            vertical: RubyTheme.spacingXS(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end, // RTL alignment
            children: [
              // Time stamp and migration indicator
              if (isToday)
                Container(
                  margin: EdgeInsets.only(
                    left: RubyTheme.spacingS(context),
                    top: RubyTheme.spacingXS(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(task.createdAt),
                        style: RubyTheme.caption(
                          context,
                        ).copyWith(color: RubyTheme.mediumGray),
                      ),
                      if (task.isMigrated)
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
                            'منتقل',
                            style: RubyTheme.caption(
                              context,
                            ).copyWith(color: RubyTheme.rubyRed, fontSize: 8),
                          ),
                        ),
                    ],
                  ),
                ),

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
                    gradient: task.isCompleted ? null : RubyTheme.rubyGradient,
                    color: task.isCompleted
                        ? RubyTheme.emerald.withOpacity(0.15)
                        : null,
                    borderRadius: BorderRadius.circular(
                      RubyTheme.radiusLarge(context),
                    ), // Completely rounded
                    boxShadow: RubyTheme.softShadow,
                    border: task.isCompleted
                        ? Border.all(
                            color: RubyTheme.emerald.withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Task text
                      Flexible(
                        child: Text(
                          task.text,
                          style: RubyTheme.bodyLarge(context).copyWith(
                            color: task.isCompleted
                                ? RubyTheme.darkGray.withOpacity(0.7)
                                : RubyTheme.pureWhite,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            fontWeight: task.isCompleted
                                ? FontWeight.w400
                                : FontWeight.w500,
                          ),
                        ),
                      ),

                      // Completion indicator
                      SizedBox(width: RubyTheme.spacingS(context)),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? RubyTheme.emerald
                              : RubyTheme.pureWhite.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          task.isCompleted
                              ? Icons.check_rounded
                              : Icons.circle_outlined,
                          color: task.isCompleted
                              ? RubyTheme.pureWhite
                              : RubyTheme.pureWhite.withOpacity(0.8),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
