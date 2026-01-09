import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../responsive.dart';

class TaskDetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const TaskDetailCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        boxShadow: RubyTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: RubyTheme.heading2(context).copyWith(
              color: RubyTheme.textPrimary(context),
              fontSize: Responsive.text(context, size: TextSize.medium),
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          ...children,
        ],
      ),
    );
  }
}
