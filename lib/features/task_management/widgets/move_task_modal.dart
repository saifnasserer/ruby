import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';

class MoveTaskModal extends StatefulWidget {
  final List<DateTime> weekDates;
  final String currentDateKey;
  final Function(String) onDateSelected;
  final String Function(DateTime) getDateKey;
  final String Function(DateTime, bool) getDateDisplayText;

  const MoveTaskModal({
    super.key,
    required this.weekDates,
    required this.currentDateKey,
    required this.onDateSelected,
    required this.getDateKey,
    required this.getDateDisplayText,
  });

  @override
  State<MoveTaskModal> createState() => _MoveTaskModalState();
}

class _MoveTaskModalState extends State<MoveTaskModal> {
  String? _selectedDateKey;

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
                  Text('نقل التاسك إلى', style: RubyTheme.heading2(context)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: RubyTheme.spacingL(context)),

              // Week days list
              ...widget.weekDates.map((date) {
                final dateKey = widget.getDateKey(date);
                final isCurrentDay = dateKey == widget.currentDateKey;
                final isSelected = _selectedDateKey == dateKey;
                final displayText = widget.getDateDisplayText(date, false);

                return Container(
                  margin: EdgeInsets.only(bottom: RubyTheme.spacingS(context)),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isCurrentDay
                          ? null
                          : () {
                              setState(() {
                                _selectedDateKey = dateKey;
                              });
                            },
                      borderRadius: BorderRadius.circular(
                        RubyTheme.radiusMedium(context),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(RubyTheme.spacingM(context)),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? RubyTheme.rubyRed.withOpacity(0.1)
                              : isCurrentDay
                              ? RubyTheme.mediumGray.withOpacity(0.1)
                              : RubyTheme.softGray,
                          borderRadius: BorderRadius.circular(
                            RubyTheme.radiusMedium(context),
                          ),
                          border: Border.all(
                            color: isSelected
                                ? RubyTheme.rubyRed
                                : isCurrentDay
                                ? RubyTheme.mediumGray.withOpacity(0.3)
                                : Colors.transparent,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCurrentDay
                                  ? Icons.block
                                  : isSelected
                                  ? Icons.check_circle
                                  : Icons.calendar_today_outlined,
                              color: isCurrentDay
                                  ? RubyTheme.mediumGray
                                  : isSelected
                                  ? RubyTheme.rubyRed
                                  : RubyTheme.darkGray,
                            ),
                            SizedBox(width: RubyTheme.spacingM(context)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayText,
                                    style: RubyTheme.bodyLarge(context)
                                        .copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isCurrentDay
                                              ? RubyTheme.mediumGray
                                              : isSelected
                                              ? RubyTheme.rubyRed
                                              : RubyTheme.charcoal,
                                        ),
                                  ),
                                  if (isCurrentDay)
                                    Text(
                                      'اليوم الحالي',
                                      style: RubyTheme.caption(
                                        context,
                                      ).copyWith(color: RubyTheme.mediumGray),
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
              }),

              SizedBox(height: RubyTheme.spacingL(context)),

              // Move button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedDateKey == null
                      ? null
                      : () {
                          widget.onDateSelected(_selectedDateKey!);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RubyTheme.rubyRed,
                    foregroundColor: RubyTheme.pureWhite,
                    disabledBackgroundColor: RubyTheme.mediumGray.withOpacity(
                      0.3,
                    ),
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
                    'نقل التاسك',
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
    );
  }
}
