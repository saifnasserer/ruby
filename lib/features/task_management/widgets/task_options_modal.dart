import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';

class TaskOptionsModal extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onChangePriority;
  final VoidCallback? onMove;
  final VoidCallback? onManageCategory;

  const TaskOptionsModal({
    super.key,
    required this.onDelete,
    this.onEdit,
    this.onChangePriority,
    this.onMove,
    this.onManageCategory,
  });

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: RubyTheme.spacingM(context)),
              decoration: BoxDecoration(
                color: RubyTheme.mediumGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: RubyTheme.spacingL(context)),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: RubyTheme.spacingL(context),
              ),
              child: Text(
                'خيارات التاسك',
                style: RubyTheme.heading2(
                  context,
                ).copyWith(color: RubyTheme.charcoal),
              ),
            ),
            SizedBox(height: RubyTheme.spacingL(context)),

            // Edit option
            if (onEdit != null)
              _buildOption(
                context,
                icon: Icons.edit_outlined,
                iconColor: RubyTheme.sapphire,
                title: 'تعديل التاسك',
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),

            // Change priority option
            if (onChangePriority != null)
              _buildOption(
                context,
                icon: Icons.star_outline,
                iconColor: RubyTheme.gold,
                title: 'تغيير الأولوية',
                onTap: () {
                  Navigator.pop(context);
                  onChangePriority!();
                },
              ),

            // Delete option
            _buildOption(
              context,
              icon: Icons.delete_outline,
              iconColor: Colors.red,
              title: 'حذف التاسك',
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            SizedBox(height: RubyTheme.spacingL(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(RubyTheme.radiusMedium(context)),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: RubyTheme.bodyLarge(context).copyWith(
          color: iconColor == Colors.red ? Colors.red : RubyTheme.charcoal,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
