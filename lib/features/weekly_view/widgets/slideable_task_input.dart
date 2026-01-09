import 'package:flutter/material.dart';
import '../../../core/theme/ruby_theme.dart';
import '../../../core/models/task_filter.dart';
import '../../../presentation/widgets/chat_input.dart';
import '../../settings/views/settings_screen.dart';
import '../../settings/controllers/settings_controller.dart';

class SlideableTaskInput extends StatefulWidget {
  final String dayOfWeek;
  final Function(String) onTaskAdded;
  final Function(String, String)? onTaskRestored;
  final Function(String, String?)? onVoiceTaskAdded;

  final SettingsController settingsController;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final TaskFilter? currentFilter;

  const SlideableTaskInput({
    super.key,
    required this.dayOfWeek,
    required this.onTaskAdded,
    required this.settingsController,
    this.onTaskRestored,
    this.onVoiceTaskAdded,
    this.onSearchTap,
    this.onFilterTap,
    this.currentFilter,
  });

  @override
  State<SlideableTaskInput> createState() => _SlideableTaskInputState();
}

class _SlideableTaskInputState extends State<SlideableTaskInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  final double _actionThreshold = 0.4; // 40% swipe to snap

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_animationController);

    _animationController.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_animationController.isAnimating) return;

    // RTL: Dragging RIGHT (positive delta) reveals LEFT actions
    // So we add the delta to the offset
    double newOffset = _dragOffset + details.primaryDelta!;

    // STRICT CLAMPING: 0 to maxWidth
    // 0 = Closed (Input visible)
    // maxWidth = Open (Actions visible)
    newOffset = newOffset.clamp(0.0, maxWidth);

    setState(() {
      _dragOffset = newOffset;
    });
  }

  void _handleDragEnd(DragEndDetails details, double maxWidth) {
    // Determine snap target
    final velocity = details.primaryVelocity ?? 0;
    final double targetOffset;

    // Snap logic:
    // If velocity is high towards Right (> 500) -> Open
    // If velocity is high towards Left (< -500) -> Close
    // Otherwise, check position threshold
    if (velocity > 500) {
      targetOffset = maxWidth; // Open
    } else if (velocity < -500) {
      targetOffset = 0; // Close
    } else {
      if (_dragOffset > maxWidth * _actionThreshold) {
        targetOffset = maxWidth; // Open
      } else {
        targetOffset = 0; // Close
      }
    }

    _animateTo(targetOffset);
  }

  void _animateTo(double target) {
    _animation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(RubyTheme.spacingM(context)),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(100),
        boxShadow: RubyTheme.softShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;

            return GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  _handleDragUpdate(details, maxWidth),
              onHorizontalDragEnd: (details) =>
                  _handleDragEnd(details, maxWidth),
              child: Stack(
                children: [
                  // Layer 1: Background Actions (Always visible underneath)
                  Positioned.fill(child: _buildQuickActionsRow(context)),

                  // Layer 2: Foreground Input (Sliding)
                  // We use Transform to slide it right
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Container(
                      // Ensure opaque background to hide actions when closed
                      color: RubyTheme.surface(context),
                      child: ChatInput(
                        dayOfWeek: widget.dayOfWeek,
                        onTaskAdded: widget.onTaskAdded,
                        onTaskRestored: widget.onTaskRestored,
                        onVoiceTaskAdded: widget.onVoiceTaskAdded,
                        settingsController: widget.settingsController,
                        hasActiveFilters:
                            widget.currentFilter?.hasActiveFilters ?? false,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    // Match theme color from ChatInput
    final themeColor = RubyTheme.surface(context);

    return Container(
      color: themeColor,
      padding: EdgeInsets.symmetric(horizontal: RubyTheme.spacingM(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildQuickActionButton(
            context,
            icon: Icons.settings,
            color: RubyTheme.surfaceVariant(context),
            label: 'الإعدادات',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    settingsController: widget.settingsController,
                  ),
                ),
              );
              _animateTo(0); // Return to input
            },
          ),
          SizedBox(width: 15), // Reduced Spacing (Closer)
          _buildQuickActionButton(
            context,
            icon: Icons.search,
            color: RubyTheme.surfaceVariant(context),
            label: 'بحث',
            onTap: () {
              widget.onSearchTap?.call();
              _animateTo(0);
            },
          ),
          SizedBox(width: 15),
          // Filter button with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildQuickActionButton(
                context,
                icon: Icons.filter_list,
                color: RubyTheme.surfaceVariant(context),
                label: 'تصفية',
                onTap: () {
                  widget.onFilterTap?.call();
                  _animateTo(0);
                },
              ),
              if (widget.currentFilter?.hasActiveFilters ?? false)
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: RubyTheme.priorityHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: RubyTheme.surface(context),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              color, // Passed from buildQuickActionsRow, which is surfaceVariant
          shape: BoxShape.circle,
          // boxShadow: RubyTheme.softShadow,
        ),
        child: Icon(
          icon,
          color: RubyTheme.textPrimary(context),
          size: 24,
        ), // Bigger icon (26->28)
      ),
    );
  }
}
