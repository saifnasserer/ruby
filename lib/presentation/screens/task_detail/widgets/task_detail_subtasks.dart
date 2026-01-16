import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../responsive.dart';
import '../../../../core/models/task.dart';
import '../../../../core/services/sound_service.dart';
import '../../../widgets/confirmation_dialog.dart';

class TaskDetailSubtasks extends StatefulWidget {
  final List<Subtask> subtasks;
  final TextEditingController subtaskController;
  final Function(String) onAdd;
  final Function(int, Subtask) onUpdate;
  final Function(int) onDelete;

  const TaskDetailSubtasks({
    super.key,
    required this.subtasks,
    required this.subtaskController,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TaskDetailSubtasks> createState() => _TaskDetailSubtasksState();
}

class _TaskDetailSubtasksState extends State<TaskDetailSubtasks> {
  void _toggleSubtask(int index) {
    final subtask = widget.subtasks[index];
    final wasCompleted = subtask.isCompleted;

    widget.onUpdate(index, subtask.copyWith(isCompleted: !subtask.isCompleted));

    // Play sound when subtask is completed (not when uncompleted)
    if (!wasCompleted) {
      SoundService.instance.playSubtaskCompletionSound();
    }
  }

  void _showEditSubtaskDialog(int index) {
    final TextEditingController textController = TextEditingController(
      text: widget.subtasks[index].text,
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'نص التاسك الفرعية...',
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
                        borderSide: BorderSide(
                          color: RubyTheme.sapphire,
                          width: 2,
                        ),
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
                  onPressed: textController.text.trim().isEmpty
                      ? null
                      : () {
                          final newText = textController.text.trim();
                          if (newText.isNotEmpty) {
                            widget.onUpdate(
                              index,
                              widget.subtasks[index].copyWith(text: newText),
                            );
                          }
                          Navigator.pop(context);
                        },
                  style: IconButton.styleFrom(
                    shape: CircleBorder(),
                    backgroundColor: textController.text.trim().isEmpty
                        ? RubyTheme.mediumGray.withOpacity(0.3)
                        : RubyTheme.sapphire,
                  ),
                  icon: Icon(
                    Icons.check,
                    color: textController.text.trim().isEmpty
                        ? RubyTheme.textSecondary(context).withOpacity(0.5)
                        : RubyTheme.pureWhite,
                    size: 20,
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            );
          },
        ),
      ),
    );
  }

  void _showSubtaskDescriptionDialog(int index) {
    final TextEditingController descriptionController = TextEditingController(
      text: widget.subtasks[index].description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                    onChanged: (value) => setState(() {}),
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
                        borderSide: BorderSide(
                          color: RubyTheme.sapphire,
                          width: 2,
                        ),
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
                  icon: Icon(
                    Icons.close,
                    color: RubyTheme.mediumGray,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: descriptionController.text.trim().isEmpty
                      ? null
                      : () {
                          final newDescription = descriptionController.text
                              .trim();
                          widget.onUpdate(
                            index,
                            widget.subtasks[index].copyWith(
                              description: newDescription.isEmpty
                                  ? const NullableValue(null)
                                  : newDescription,
                            ),
                          );
                          Navigator.pop(context);
                        },
                  style: IconButton.styleFrom(
                    shape: CircleBorder(),
                    backgroundColor: descriptionController.text.trim().isEmpty
                        ? RubyTheme.mediumGray.withOpacity(0.3)
                        : RubyTheme.sapphire,
                  ),
                  icon: Icon(
                    Icons.check,
                    color: descriptionController.text.trim().isEmpty
                        ? RubyTheme.textSecondary(context).withOpacity(0.5)
                        : RubyTheme.pureWhite,
                    size: 20,
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            );
          },
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
            'التاسكات الفرعية (${widget.subtasks.where((s) => s.isCompleted).length}/${widget.subtasks.length})',
            style: RubyTheme.heading2(context).copyWith(
              color: RubyTheme.textPrimary(context),
              fontSize: Responsive.text(context, size: TextSize.medium),
            ),
          ),
        ),
        // Add subtask input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.subtaskController,
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
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                ),
                onSubmitted: widget.onAdd,
              ),
            ),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            IconButton(
              onPressed: () => widget.onAdd(widget.subtaskController.text),
              icon: Icon(
                Icons.add_circle,
                color: RubyTheme.sapphire,
                size: Responsive.text(context, size: TextSize.heading),
              ),
            ),
          ],
        ),

        // Subtasks list
        if (widget.subtasks.isNotEmpty) ...[
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          ...widget.subtasks.asMap().entries.map((entry) {
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
                  _showEditSubtaskDialog(index);
                  return false;
                }
                // Show confirmation dialog for deletion
                final confirmed = await showConfirmationDialog(
                  context: context,
                  title: 'هل أنت متأكد من حذف هذه التاسك الفرعية؟',
                  message: 'لا يمكن التراجع عن هذا الإجراء.',
                  onConfirm: () {},
                );
                return confirmed ?? false;
              },
              onDismissed: (_) => widget.onDelete(index),
              child: Container(
                margin: EdgeInsets.only(
                  bottom: Responsive.space(context, size: Space.small),
                ),
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.small),
                ),
                decoration: BoxDecoration(
                  color: subtask.isCompleted
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? RubyTheme.emerald.withOpacity(0.15)
                            : RubyTheme.emerald.withOpacity(0.05))
                      : (Theme.of(context).brightness == Brightness.dark
                            ? RubyTheme.surface(context)
                            : RubyTheme.softGray),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.xlarge),
                  ),
                  border: Border.all(
                    color: subtask.isCompleted
                        ? RubyTheme.emerald.withOpacity(0.3)
                        : RubyTheme.mediumGray.withOpacity(0.2),
                  ),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleSubtask(index),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                            Text(
                              subtask.text,
                              style: RubyTheme.bodyMedium(context).copyWith(
                                decoration: subtask.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: subtask.isCompleted
                                    ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? RubyTheme.textSecondary(
                                              context,
                                            ).withOpacity(0.7)
                                          : RubyTheme.mediumGray)
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? RubyTheme.textPrimary(context)
                                          : RubyTheme.darkGray),
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
                                style: RubyTheme.caption(context).copyWith(
                                  color: subtask.isCompleted
                                      ? RubyTheme.mediumGray.withOpacity(0.7)
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
                          color: RubyTheme.sapphire,
                        ),
                        onPressed: () => _showSubtaskDescriptionDialog(index),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
