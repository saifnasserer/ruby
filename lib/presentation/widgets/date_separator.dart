import 'package:flutter/material.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/ruby_theme.dart';
import '../../responsive.dart';

class DateSeparator extends StatelessWidget {
  final String dateKey;

  const DateSeparator({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateKey);
    final dateLabel = DateFormatter.getRelativeDateLabel(date);

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
}
