import 'package:flutter/material.dart';
import '../../../core/theme/ruby_theme.dart';
import '../../../presentation/widgets/chat_input.dart';
import '../../settings/views/settings_screen.dart';
import '../../settings/controllers/settings_controller.dart';

class SlideableTaskInput extends StatefulWidget {
  final String dayOfWeek;
  final Function(String) onTaskAdded;
  final Function(String, String)? onTaskRestored;
  final Function(String)? onVoiceTaskAdded;
  final SettingsController settingsController;

  const SlideableTaskInput({
    super.key,
    required this.dayOfWeek,
    required this.onTaskAdded,
    required this.settingsController,
    this.onTaskRestored,
    this.onVoiceTaskAdded,
  });

  @override
  State<SlideableTaskInput> createState() => _SlideableTaskInputState();
}

class _SlideableTaskInputState extends State<SlideableTaskInput>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  double get _screenWidth => MediaQuery.of(context).size.width;

  @override
  void initState() {
    super.initState();
    // Layout: [Input, Buttons].
    // RTL: Input is at Start (Right). Buttons at End (Left).
    // Start at 0 (Input).
    _scrollController = ScrollController(); // Starts at 0

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_animationController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_scrollController.hasClients) return;
    // Inverted Drag Logic:
    // Drag Right (Delta > 0) -> Increase Offset (Move towards Buttons).
    // Drag Left (Delta < 0) -> Decrease Offset (Move towards Input).
    _scrollController.jumpTo(_scrollController.offset + details.primaryDelta!);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = _screenWidth / 2;

    double targetOffset;

    // Snapping logic
    // 0 = Input. Width = Buttons.
    // If we are closer to Width (Buttons) or velocity throws us there (Right Swipe > 0):
    if (velocity > 500 || (velocity > -500 && currentOffset > threshold)) {
      targetOffset = _screenWidth; // Show Buttons
    } else {
      targetOffset = 0; // Show Input
    }

    _animateTo(targetOffset);
  }

  void _animateTo(double target) {
    final start = _scrollController.offset;
    _animation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.reset();
    _animationController.forward();
    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_animation.value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Manual control
        child: IntrinsicHeight(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Child 0: Input Field (Right side in RTL, Offset 0)
                SizedBox(
                  width: _screenWidth,
                  child: ChatInput(
                    dayOfWeek: widget.dayOfWeek,
                    onTaskAdded: widget.onTaskAdded,
                    onTaskRestored: widget.onTaskRestored,
                    onVoiceTaskAdded: widget.onVoiceTaskAdded,
                    settingsController: widget.settingsController,
                  ),
                ),

                // Child 1: Quick Actions (Left side in RTL, Offset Width)
                SizedBox(
                  width: _screenWidth,
                  child: _buildQuickActionsRow(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    // Match theme color from ChatInput
    final themeColor = widget.settingsController.backgroundColor;

    return Container(
      color: themeColor,
      padding: EdgeInsets.symmetric(horizontal: RubyTheme.spacingM(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildQuickActionButton(
            context,
            icon: Icons.settings,
            color: RubyTheme.mediumGray,
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
            icon: Icons.calendar_month,
            color: RubyTheme.mediumGray,
            label: 'التاريخ',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الذهاب للتاريخ (قريباً)')),
              );
            },
          ),
          SizedBox(width: 15), // Reduced Spacing
          _buildQuickActionButton(
            context,
            icon: Icons.search,
            color: RubyTheme.mediumGray,
            label: 'بحث',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('البحث (قريباً)')));
            },
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
          color: RubyTheme.mediumGray,
          shape: BoxShape.circle,
          // boxShadow: RubyTheme.softShadow,
        ),
        child: Icon(
          icon,
          color: RubyTheme.pureWhite,
          size: 24,
        ), // Bigger icon (26->28)
      ),
    );
  }
}
