import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';
import '../../core/models/task_filter.dart';
import '../../responsive.dart';

/// Shows a bottom sheet with filter options for tasks
Future<TaskFilter?> showFilterBottomSheet({
  required BuildContext context,
  required TaskFilter currentFilter,
}) {
  return showModalBottomSheet<TaskFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterBottomSheet(currentFilter: currentFilter),
  );
}

class FilterBottomSheet extends StatefulWidget {
  final TaskFilter currentFilter;

  const FilterBottomSheet({super.key, required this.currentFilter});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TaskFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('تصفية التاسكات', style: RubyTheme.heading1(context)),
                  if (_filter.hasActiveFilters)
                    Row(
                      children: [
                        SizedBox(
                          width: Responsive.space(context, size: Space.large),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: RubyTheme.sapphire),
                          onPressed: () {
                            setState(() {
                              _filter = _filter.reset();
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),

            Divider(height: 1),

            // Filter Options
            Padding(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Completion Status Filter
                  _buildFilterSection(
                    context,
                    title: 'حالة الإكمال',
                    children: [
                      _buildFilterChip(
                        context,
                        label: TaskCompletionFilter.all.displayName,
                        isSelected:
                            _filter.completionFilter ==
                            TaskCompletionFilter.all,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              completionFilter: TaskCompletionFilter.all,
                            );
                          });
                        },
                      ),
                      _buildFilterChip(
                        context,
                        label: TaskCompletionFilter.completed.displayName,
                        isSelected:
                            _filter.completionFilter ==
                            TaskCompletionFilter.completed,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              completionFilter: TaskCompletionFilter.completed,
                            );
                          });
                        },
                      ),
                      _buildFilterChip(
                        context,
                        label: TaskCompletionFilter.uncompleted.displayName,
                        isSelected:
                            _filter.completionFilter ==
                            TaskCompletionFilter.uncompleted,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              completionFilter:
                                  TaskCompletionFilter.uncompleted,
                            );
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(
                    height: Responsive.space(context, size: Space.large),
                  ),

                  // Priority Filter
                  _buildFilterSection(
                    context,
                    title: 'الأولوية',
                    children: [
                      _buildFilterChip(
                        context,
                        label: 'الكل',
                        isSelected: _filter.priorityFilter == null,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              clearPriorityFilter: true,
                            );
                          });
                        },
                      ),
                      _buildFilterChip(
                        context,
                        label: TaskPriorityFilter.important.displayName,
                        isSelected:
                            _filter.priorityFilter ==
                            TaskPriorityFilter.important,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              priorityFilter: TaskPriorityFilter.important,
                            );
                          });
                        },
                      ),
                      _buildFilterChip(
                        context,
                        label: TaskPriorityFilter.normal.displayName,
                        isSelected:
                            _filter.priorityFilter == TaskPriorityFilter.normal,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              priorityFilter: TaskPriorityFilter.normal,
                            );
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(
                    height: Responsive.space(context, size: Space.large),
                  ),

                  // Date Filter
                  _buildFilterSection(
                    context,
                    title: 'التاريخ',
                    children: [
                      _buildFilterChip(
                        context,
                        label: TaskDateFilter.all.displayName,
                        isSelected: _filter.dateFilter == TaskDateFilter.all,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              dateFilter: TaskDateFilter.all,
                            );
                          });
                        },
                      ),
                      _buildFilterChip(
                        context,
                        label: TaskDateFilter.today.displayName,
                        isSelected: _filter.dateFilter == TaskDateFilter.today,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              dateFilter: TaskDateFilter.today,
                            );
                          });
                        },
                      ),
                      _buildFilterChip(
                        context,
                        label: TaskDateFilter.thisWeek.displayName,
                        isSelected:
                            _filter.dateFilter == TaskDateFilter.thisWeek,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              dateFilter: TaskDateFilter.thisWeek,
                            );
                          });
                        },
                      ),
                      _buildFilterChip(
                        context,
                        label: TaskDateFilter.past.displayName,
                        isSelected: _filter.dateFilter == TaskDateFilter.past,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              dateFilter: TaskDateFilter.past,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Apply Button
            Padding(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _filter),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RubyTheme.sapphire,
                    foregroundColor: RubyTheme.pureWhite,
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.space(context, size: Space.medium),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    'تطبيق',
                    style: RubyTheme.heading2(
                      context,
                    ).copyWith(color: RubyTheme.pureWhite),
                  ),
                ),
              ),
            ),

            // Bottom safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: RubyTheme.bodyLarge(context).copyWith(
            fontWeight: FontWeight.bold,
            color: RubyTheme.textPrimary(context),
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Wrap(
          spacing: Responsive.space(context, size: Space.small),
          runSpacing: Responsive.space(context, size: Space.small),
          children: children,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? RubyTheme.sapphire
              : RubyTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? RubyTheme.sapphire
                : RubyTheme.mediumGray.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: RubyTheme.bodyMedium(context).copyWith(
            color: isSelected
                ? RubyTheme.pureWhite
                : RubyTheme.textPrimary(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
