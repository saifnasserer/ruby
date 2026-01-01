import 'package:flutter/material.dart';
import '../../../../core/models/task.dart';
import '../../../../core/theme/ruby_theme.dart';

class TaskDetailModal extends StatefulWidget {
  final Task task;
  final Function(String) onTextChanged;
  final Function(TaskPriority) onPriorityChanged;
  final Function(String?) onCategoryChanged;
  final Function(List<String>) onTagsChanged;
  final Function(DateTime?) onDeadlineChanged;

  const TaskDetailModal({
    super.key,
    required this.task,
    required this.onTextChanged,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.onTagsChanged,
    required this.onDeadlineChanged,
  });

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  late TextEditingController _textController;
  late TextEditingController _categoryController;
  late TextEditingController _tagController;
  late TaskPriority _selectedPriority;
  late List<String> _tags;
  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.task.text);
    _categoryController = TextEditingController(
      text: widget.task.category ?? '',
    );
    _tagController = TextEditingController();
    _selectedPriority = widget.task.priority;
    _tags = List.from(widget.task.tags);
    _selectedDeadline = widget.task.deadlineDate;
  }

  @override
  void dispose() {
    _textController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _save() {
    final newText = _textController.text.trim();
    if (newText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن أن تكون التاسك فارغة',
            style: RubyTheme.bodyMedium(
              context,
            ).copyWith(color: RubyTheme.pureWhite),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newText != widget.task.text) {
      widget.onTextChanged(newText);
    }

    if (_selectedPriority != widget.task.priority) {
      widget.onPriorityChanged(_selectedPriority);
    }

    final newCategory = _categoryController.text.trim();
    if (newCategory != widget.task.category) {
      widget.onCategoryChanged(newCategory.isEmpty ? null : newCategory);
    }

    if (_tags.toSet().difference(widget.task.tags.toSet()).isNotEmpty ||
        widget.task.tags.toSet().difference(_tags.toSet()).isNotEmpty) {
      widget.onTagsChanged(_tags);
    }

    if (_selectedDeadline != widget.task.deadlineDate) {
      widget.onDeadlineChanged(_selectedDeadline);
    }

    Navigator.pop(context);
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final initialDate = _selectedDeadline ?? now.add(const Duration(days: 1));

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
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? now),
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
          setState(() {
            _selectedDeadline = selectedDateTime;
          });
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

  void _clearDeadline() {
    setState(() {
      _selectedDeadline = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(RubyTheme.spacingM(context)),
      decoration: BoxDecoration(
        color: RubyTheme.pureWhite,
        borderRadius: BorderRadius.circular(RubyTheme.radiusLarge(context)),
        boxShadow: RubyTheme.mediumShadow,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(RubyTheme.spacingL(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تعديل التاسك', style: RubyTheme.heading2(context)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: RubyTheme.spacingL(context)),

                // Task text input
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'نص التاسك',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        RubyTheme.radiusMedium(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        RubyTheme.radiusMedium(context),
                      ),
                      borderSide: BorderSide(
                        color: RubyTheme.rubyRed,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: RubyTheme.spacingL(context)),

                // Priority selector
                Text(
                  'الأولوية',
                  style: RubyTheme.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: RubyTheme.spacingS(context)),
                Wrap(
                  spacing: RubyTheme.spacingS(context),
                  children: TaskPriority.values.map((priority) {
                    final isSelected = _selectedPriority == priority;
                    return ChoiceChip(
                      label: Text(priority.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPriority = priority;
                        });
                      },
                      selectedColor: _getPriorityColor(priority),
                      backgroundColor: RubyTheme.softGray,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? RubyTheme.pureWhite
                            : RubyTheme.darkGray,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: RubyTheme.spacingL(context)),

                // Category input
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'الفئة (اختياري)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        RubyTheme.radiusMedium(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        RubyTheme.radiusMedium(context),
                      ),
                      borderSide: BorderSide(
                        color: RubyTheme.rubyRed,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: RubyTheme.spacingL(context)),

                // Deadline section
                Text(
                  'تاريخ الانتهاء (اختياري)',
                  style: RubyTheme.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: RubyTheme.spacingS(context)),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: RubyTheme.mediumGray, width: 1),
                    borderRadius: BorderRadius.circular(
                      RubyTheme.radiusMedium(context),
                    ),
                  ),
                  padding: EdgeInsets.all(RubyTheme.spacingM(context)),
                  child: Row(
                    children: [
                      Expanded(
                        child: _selectedDeadline != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'التاريخ والوقت:',
                                    style: RubyTheme.caption(
                                      context,
                                    ).copyWith(color: RubyTheme.mediumGray),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year} - ${_selectedDeadline!.hour.toString().padLeft(2, '0')}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}',
                                    style: RubyTheme.bodyLarge(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            : Text(
                                'لم يتم تحديد موعد نهائي',
                                style: RubyTheme.bodyMedium(
                                  context,
                                ).copyWith(color: RubyTheme.mediumGray),
                              ),
                      ),
                      SizedBox(width: RubyTheme.spacingS(context)),
                      if (_selectedDeadline != null)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearDeadline,
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          tooltip: 'إزالة الموعد النهائي',
                        ),
                      IconButton(
                        icon: Icon(
                          _selectedDeadline != null
                              ? Icons.edit
                              : Icons.calendar_today,
                        ),
                        onPressed: _selectDeadline,
                        style: IconButton.styleFrom(
                          backgroundColor: RubyTheme.rubyRed,
                          foregroundColor: RubyTheme.pureWhite,
                        ),
                        tooltip: _selectedDeadline != null
                            ? 'تعديل'
                            : 'اختر تاريخ',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: RubyTheme.spacingL(context)),

                // Tags section
                Text(
                  'الوسوم',
                  style: RubyTheme.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: RubyTheme.spacingS(context)),

                // Tag input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: 'أضف وسم',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              RubyTheme.radiusMedium(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              RubyTheme.radiusMedium(context),
                            ),
                            borderSide: BorderSide(
                              color: RubyTheme.rubyRed,
                              width: 2,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    SizedBox(width: RubyTheme.spacingS(context)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                      style: IconButton.styleFrom(
                        backgroundColor: RubyTheme.rubyRed,
                        foregroundColor: RubyTheme.pureWhite,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: RubyTheme.spacingS(context)),

                // Tag chips
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: RubyTheme.spacingS(context),
                    runSpacing: RubyTheme.spacingS(context),
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        backgroundColor: RubyTheme.rubyLight,
                        labelStyle: RubyTheme.bodyMedium(
                          context,
                        ).copyWith(color: RubyTheme.rubyDark),
                      );
                    }).toList(),
                  ),
                SizedBox(height: RubyTheme.spacingL(context)),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RubyTheme.rubyRed,
                      foregroundColor: RubyTheme.pureWhite,
                      padding: EdgeInsets.symmetric(
                        vertical: RubyTheme.spacingM(context),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          RubyTheme.radiusMedium(context),
                        ),
                      ),
                    ),
                    child: Text(
                      'حفظ التغييرات',
                      style: RubyTheme.bodyLarge(context).copyWith(
                        color: RubyTheme.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHigh;
      case TaskPriority.normal:
        return RubyTheme.priorityMedium;
      case TaskPriority.normal:
        return RubyTheme.priorityLow;
      case TaskPriority.normal:
        return RubyTheme.mediumGray;
    }
  }
}
