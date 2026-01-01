import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../responsive.dart';

class CustomTabBar extends StatelessWidget {
  final List<DateTime> currentWeekDates;
  final int selectedIndex;
  final Function(int) onTabTap;
  final bool Function(int) isTodayIndex;
  final String Function(DateTime, bool) getDateDisplayText;
  final ScrollController tabScrollController;

  const CustomTabBar({
    super.key,
    required this.currentWeekDates,
    required this.selectedIndex,
    required this.onTabTap,
    required this.isTodayIndex,
    required this.getDateDisplayText,
    required this.tabScrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: SingleChildScrollView(
        controller: tabScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(currentWeekDates.length, (index) {
            final isSelected = selectedIndex == index;
            final isToday = isTodayIndex(index);
            final date = currentWeekDates[index];
            final displayText = getDateDisplayText(date, false);

            return GestureDetector(
              onTap: () => onTabTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                margin: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.tiny),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                  vertical: Responsive.space(context, size: Space.small),
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? RubyTheme.rubyGradient : null,
                  color: isSelected ? null : RubyTheme.pureWhite,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: RubyTheme.rubyRed.withOpacity(0.5),
                          width: 2,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withOpacity(0.3),
                            blurRadius: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isToday)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          width:
                              Responsive.space(context, size: Space.tiny) * 2,
                          height:
                              Responsive.space(context, size: Space.tiny) * 2,
                          margin: EdgeInsets.only(
                            left: Responsive.space(context, size: Space.tiny),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? RubyTheme.pureWhite
                                : RubyTheme.rubyRed,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: RubyTheme.pureWhite.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        style: TextStyle(
                          color: isSelected
                              ? RubyTheme.pureWhite
                              : RubyTheme.charcoal,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          height: 1.2,
                        ),
                        child: Text(displayText),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
