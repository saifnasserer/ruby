import 'package:flutter/material.dart';
import '../../../../responsive.dart';

class MigrationButton extends StatefulWidget {
  final VoidCallback onTap;
  final int unfinishedTasksCount;

  const MigrationButton({
    super.key,
    required this.onTap,
    required this.unfinishedTasksCount,
  });

  @override
  State<MigrationButton> createState() => _MigrationButtonState();
}

class _MigrationButtonState extends State<MigrationButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Start pulsing animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE91E63), // Ruby red
                      const Color(0xFFAD1457), // Darker ruby
                      const Color(0xFF880E4F), // Even darker ruby
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withOpacity(0.3),
                      blurRadius: Responsive.space(context, size: Space.medium),
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFFE91E63).withOpacity(0.1),
                      blurRadius: Responsive.space(context, size: Space.xlarge),
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated icon with fire effect
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.small),
                          ),
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: Responsive.text(context, size: TextSize.medium),
                        ),
                      ),

                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),

                      // Main text
                      Expanded(
                        child: Text(
                          'نقل المهام غير المكتملة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),

                      // Animated count badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          vertical: Responsive.space(context, size: Space.tiny),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.small),
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${widget.unfinishedTasksCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
