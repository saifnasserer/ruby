import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../responsive.dart';
import '../../../core/models/task.dart';
import '../../../core/models/chat_message.dart';
import '../../../presentation/widgets/chat_message_bubble.dart';
import '../../../presentation/widgets/task_bubble.dart';
import '../../task_management/controllers/task_controller.dart';

/// Mixin for building the unified chat view
mixin ChatViewMixin on State {
  // These will be provided by the main widget
  TaskController get taskController;
  Map<String, List<ChatMessage>> get chatHistory;

  // Methods to be implemented by main widget
  void toggleTaskCompletion(String taskId);
  void showTaskOptions(String taskId);
  void showRestoreDialog(ChatMessage message);

  /// Build unified chat view showing all tasks from all days
  Widget buildUnifiedChatView() {
    // Collect all tasks from all days
    final List<Task> allTasks = [];
    final List<ChatMessage> allMessages = [];

    // Get all tasks and messages
    taskController.tasks.forEach((dateKey, tasks) {
      allTasks.addAll(tasks.where((task) => !task.isDeleted));
    });

    chatHistory.forEach((dateKey, messages) {
      allMessages.addAll(messages);
    });

    // Combine all items
    final List<dynamic> allItems = [...allMessages, ...allTasks];

    // If no items, show empty state
    if (allItems.isEmpty) {
      return Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.xlarge)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: Responsive.text(context, size: TextSize.heading) * 3,
                color: RubyTheme.mediumGray.withOpacity(0.3),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'ابدأ بإضافة مهمتك الأولى',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w500,
                  color: RubyTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group items by their creation date
    final Map<String, List<dynamic>> groupedByDate = {};
    for (var item in allItems) {
      DateTime itemDate;
      if (item is ChatMessage) {
        itemDate = item.timestamp;
      } else if (item is Task) {
        itemDate = item.createdAt;
      } else {
        continue;
      }

      final itemDateKey = getDateKey(itemDate);
      groupedByDate.putIfAbsent(itemDateKey, () => []);
      groupedByDate[itemDateKey]!.add(item);
    }

    // Sort date keys in descending order (newest to oldest)
    // With reverse: false, newest (today) appears at bottom
    // User swipes UP to see older days
    final sortedDateKeys = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order (newest first)

    return ListView.builder(
      reverse: false, // Normal order - today at bottom, swipe up for older
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
        bottom: Responsive.space(context, size: Space.small),
      ),
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupDateKey = sortedDateKeys[groupIndex];
        final groupItems = groupedByDate[groupDateKey]!;

        // Sort items within the group by timestamp
        groupItems.sort((a, b) {
          DateTime aTime;
          DateTime bTime;

          if (a is ChatMessage) {
            aTime = a.timestamp;
          } else if (a is Task) {
            aTime = a.createdAt;
          } else {
            aTime = DateTime.now();
          }

          if (b is ChatMessage) {
            bTime = b.timestamp;
          } else if (b is Task) {
            bTime = b.createdAt;
          } else {
            bTime = DateTime.now();
          }

          return aTime.compareTo(bTime);
        });

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final groupDate = DateTime.parse(groupDateKey);
        final isToday =
            DateTime(groupDate.year, groupDate.month, groupDate.day) == today;

        return Column(
          children: [
            // Date separator (WhatsApp-style)
            buildDateSeparator(groupDateKey),

            // Items for this date
            ...groupItems.map((item) {
              if (item is ChatMessage) {
                return ChatMessageBubble(
                  message: item,
                  showTimestamp: true,
                  onLongPress: () {
                    if (item.type == ChatMessageType.taskDeleted) {
                      showRestoreDialog(item);
                    }
                  },
                );
              } else if (item is Task) {
                return TaskBubble(
                  task: item,
                  isToday: isToday,
                  onTap: () => toggleTaskCompletion(item.id),
                  onLongPress: () => showTaskOptions(item.id),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }

  /// Build WhatsApp-style date separator
  Widget buildDateSeparator(String dateKey) {
    final date = DateTime.parse(dateKey);
    final dateLabel = getRelativeDateLabel(date);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.medium),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.medium),
            vertical: Responsive.space(context, size: Space.small),
          ),
          decoration: BoxDecoration(
            color: RubyTheme.mediumGray.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            border: Border.all(
              color: RubyTheme.mediumGray.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.w600,
              color: RubyTheme.mediumGray,
            ),
          ),
        ),
      ),
    );
  }

  /// Get relative date label (Today, Yesterday, or formatted date)
  String getRelativeDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'اليوم';
    } else if (dateOnly == yesterday) {
      return 'أمس';
    } else {
      // Format as "Day DD Month"
      final weekDays = [
        'الأحد',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];

      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];

      final dayName = weekDays[date.weekday % 7];
      final monthName = months[date.month - 1];

      return '$dayName ${date.day} $monthName';
    }
  }

  /// Helper to get date key from DateTime
  String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
