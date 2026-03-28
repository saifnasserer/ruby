import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../../core/theme/ruby_theme.dart';
import '../../../core/models/task_filter.dart';
import '../../../presentation/widgets/chat_input.dart';
import '../../settings/views/settings_screen.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../core/services/auth_service.dart';
import '../../../presentation/screens/auth/login_screen.dart';
import '../../../presentation/screens/profile/profile_screen.dart';
import '../../analysis/views/analysis_page.dart';

class SlideableTaskInput extends StatefulWidget {
  final String dayOfWeek;
  final Function(String, List<String>) onTaskAdded;
  final Function(String, String)? onTaskRestored;
  final Function(String, List<double>?, List<String>)? onVoiceTaskAdded;
  final Future<void> Function()? onSyncTap;

  final SettingsController settingsController;
  final List<String> availableTags;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final TaskFilter? currentFilter;

  const SlideableTaskInput({
    super.key,
    required this.dayOfWeek,
    required this.onTaskAdded,
    required this.settingsController,
    required this.availableTags,
    this.onTaskRestored,
    this.onVoiceTaskAdded,
    this.onSyncTap,
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
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode(); // Controlled from here
  double _dragOffset = 0.0;
  final double _actionThreshold = 0.3; // 30% swipe to snap
  final double _maxRevealRatio = 0.85; // Leave 15% of input visible for return tapping

  @override
  void initState() {
    super.initState();
    // Unbounded to allow physics simulations outside 0.0-1.0 range
    _animationController = AnimationController.unbounded(vsync: this);
    // Remove setState listener to improve performance
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    // Unfocus keyboard when dragging starts to avoid visual glitches
    if (_dragOffset == 0 && details.primaryDelta! > 0) {
      FocusScope.of(context).unfocus();
    }

    // RTL: Dragging RIGHT (positive delta) reveals LEFT actions
    // So we add the delta to the offset
    double newOffset = _dragOffset + details.primaryDelta!;

    // STRICT CLAMPING: 0 to maxWidth * _maxRevealRatio during drag
    newOffset = newOffset.clamp(0.0, maxWidth * _maxRevealRatio);

    setState(() {
      _dragOffset = newOffset;
    });
    // Sync controller directly
    _animationController.value = _dragOffset;
  }

  void _handleDragEnd(DragEndDetails details, double maxWidth) {
    // Determine snap target
    final velocity = details.primaryVelocity ?? 0;
    final double targetOffset;

    // Snap logic:
    // If velocity is high towards Right (> 500) -> Open
    // If velocity is high towards Left (< -500) -> Close
    // Otherwise, check position threshold
    if (velocity > 400) {
      targetOffset = maxWidth * _maxRevealRatio; // Open
    } else if (velocity < -400) {
      targetOffset = 0; // Close
    } else {
      if (_dragOffset > maxWidth * _actionThreshold) {
        targetOffset = maxWidth * _maxRevealRatio; // Open
      } else {
        targetOffset = 0; // Close
      }
    }

    _animateTo(targetOffset, velocity);
  }

  void _animateTo(double target, [double velocity = 0]) {
    final description = SpringDescription(
      mass: 1,
      stiffness: 150,
      damping: 25,
    ); // Critical damping

    final simulation = SpringSimulation(
      description,
      _dragOffset,
      target,
      velocity,
    );

    _animationController.animateWith(simulation);
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
      child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxRevealWidth = maxWidth * _maxRevealRatio;

            return GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  _handleDragUpdate(details, maxWidth),
              onHorizontalDragEnd: (details) =>
                  _handleDragEnd(details, maxWidth),
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final visualOffset = _animationController.value.clamp(0.0, maxRevealWidth);
                  
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Layer 1: Background Actions (Clipped to capsule shape)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Transform.translate(
                            offset: Offset(visualOffset - maxWidth, 0),
                            child: _buildQuickActionsRow(context, maxWidth),
                          ),
                        ),
                      ),
                      
                      // Layer 2: Foreground Input (Sliding)
                      // No ClipRRect here to allow floating tags to overflow upwards
                      Transform.translate(
                        offset: Offset(visualOffset, 0),
                        child: GestureDetector(
                          onTap: () {
                            if (_animationController.value > 0) {
                              _animateTo(0, 0);
                              _inputFocusNode.requestFocus();
                            }
                          },
                          child: Container(
                            // Don't use color here, let ChatInput handle its own background
                            // but we need a background for the capsule shape if it's not open
                            decoration: BoxDecoration(
                              color: RubyTheme.surface(context),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: ChatInput(
                              dayOfWeek: widget.dayOfWeek,
                              focusNode: _inputFocusNode,
                              onTaskAdded: (text, tags) => widget.onTaskAdded(text, tags),
                              onTaskRestored: widget.onTaskRestored,
                              onVoiceTaskAdded: (path, wave, tags) => widget.onVoiceTaskAdded?.call(path, wave, tags),
                              settingsController: widget.settingsController,
                              hasActiveFilters: widget.currentFilter?.hasActiveFilters ?? false,
                              availableTags: widget.availableTags,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context, double maxWidth) {
    // Match theme color from ChatInput
    final themeColor = RubyTheme.surface(context);

    return Container(
      color: themeColor,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) {
          // If we are scrolling the list, let the ScrollView handle it
          // UNLESS we are at the edge and trying to close the bar
          if (_scrollController.hasClients) {
            final position = _scrollController.position;
            // In Flutter RTL, pixels=0 is the right-most point.
            // Dragging RIGHT (positive delta in screen space) should close the bar 
            // if we are already at the right-most point (pixels <= 0).
            // Dragging LEFT (negative delta) at any point should help close
            // if we are already at the left-most scroll point
            if (position.pixels <= 1.0 && details.primaryDelta! < 0) {
               _handleDragUpdate(details, maxWidth);
            } else if (position.pixels >= position.maxScrollExtent - 1.0 && details.primaryDelta! > 0) {
              // RTL: At the right edge, dragging RIGHT opens more/keeps open
               _handleDragUpdate(details, maxWidth);
            }
          }
        },
        onHorizontalDragEnd: (details) => _handleDragEnd(details, maxWidth),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: RubyTheme.spacingM(context)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          _buildQuickActionButton(
            context,
            icon: Icons.person_outline_rounded,
            color: RubyTheme.surfaceVariant(context),
            label: 'الملف الشخصي',
            onTap: () {
              // Check if user is logged in
              final isLoggedIn = AuthService.instance.currentUser != null;

              if (isLoggedIn) {
                // Navigate to profile if logged in
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      settingsController: widget.settingsController,
                    ),
                  ),
                );
              } else {
                // Show login screen if logged out
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      settingsController: widget.settingsController,
                    ),
                  ),
                );
              }
              _animateTo(0, 0);
            },
          ),
          _buildQuickActionButton(
            context,
            icon: Icons.bar_chart_rounded,
            color: RubyTheme.surfaceVariant(context),
            label: 'التحليل',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalysisPage()),
              );
              _animateTo(0, 0);
            },
          ),
          SizedBox(width: 15),
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
              _animateTo(0, 0); // Return to input
            },
          ),
          SizedBox(width: 15),
          _buildQuickActionButton(
            context,
            icon: Icons.search,
            color: RubyTheme.surfaceVariant(context),
            label: 'بحث',
            onTap: () {
              widget.onSearchTap?.call();
              _animateTo(0, 0);
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
                  _animateTo(0, 0);
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
          SizedBox(width: 15),
          // Sync / Login Button
          _buildQuickActionButton(
            context,
            icon: Icons.cloud_sync,
            color: RubyTheme.surfaceVariant(context),
            label: 'مزامنة',
            onTap: () async {
              if (AuthService.instance.isAuthenticated) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('جاري المزامنة...')));
                if (widget.onSyncTap != null) {
                  await widget.onSyncTap!();
                }
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      settingsController: widget.settingsController,
                    ),
                  ),
                );
              }
              _animateTo(0, 0); // Close drawer
            },
          ),
        ],
      ),
    ),
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
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: RubyTheme.textPrimary(context),
          size: 24,
        ),
      ),
    );
  }
}
