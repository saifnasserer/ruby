import 'package:flutter/material.dart';
import '../../core/models/chat_message.dart';
import '../../core/theme/ruby_theme.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showTimestamp;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onTap,
    this.onLongPress,
    this.showTimestamp = true,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: RubyTheme.spacingM(context),
                  vertical: RubyTheme.spacingXS(context),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // RTL alignment
                  children: [
                    // Message bubble
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: RubyTheme.spacingM(context),
                          vertical: RubyTheme.spacingM(context) / 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: _getMessageGradient(),
                          color: _getMessageColor(),
                          borderRadius: BorderRadius.circular(
                            RubyTheme.radiusLarge(context),
                          ),
                          boxShadow: RubyTheme.softShadow,
                          border: _getMessageBorder(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Message type icon
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _getIconBackgroundColor(),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                widget.message.type.icon,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getIconColor(),
                                ),
                              ),
                            ),

                            SizedBox(width: RubyTheme.spacingS(context)),

                            // Message content
                            Flexible(
                              child: Text(
                                widget.message.content,
                                style: RubyTheme.bodyLarge(context).copyWith(
                                  color: _getTextColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: RubyTheme.spacingS(context)),

                    // Timestamp
                    if (widget.showTimestamp)
                      Container(
                        margin: EdgeInsets.only(
                          left: RubyTheme.spacingS(context),
                          top: RubyTheme.spacingXS(context),
                        ),
                        child: Text(
                          _formatTime(widget.message.timestamp),
                          style: RubyTheme.caption(
                            context,
                          ).copyWith(color: RubyTheme.mediumGray),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Gradient? _getMessageGradient() {
    switch (widget.message.type) {
      case ChatMessageType.taskCreated:
        return RubyTheme.rubyGradient;
      case ChatMessageType.taskCompleted:
      case ChatMessageType.taskUncompleted:
      case ChatMessageType.taskDeleted:
      case ChatMessageType.taskMigrated:
      case ChatMessageType.daySummary:
      case ChatMessageType.weekSummary:
      case ChatMessageType.taskRestored:
      case ChatMessageType.taskEdited:
      case ChatMessageType.taskPriorityChanged:
      case ChatMessageType.taskCategoryChanged:
      case ChatMessageType.taskMoved:
        return null; // Use solid color
    }
  }

  Color? _getMessageColor() {
    switch (widget.message.type) {
      case ChatMessageType.taskCreated:
        return null; // Use gradient
      case ChatMessageType.taskCompleted:
        return RubyTheme.emerald.withOpacity(0.15);
      case ChatMessageType.taskUncompleted:
        return RubyTheme.sapphire.withOpacity(0.15);
      case ChatMessageType.taskDeleted:
        return RubyTheme.rubyRed.withOpacity(0.15);
      case ChatMessageType.taskMigrated:
        return RubyTheme.gold.withOpacity(0.15);
      case ChatMessageType.daySummary:
        return RubyTheme.sapphire.withOpacity(0.15);
      case ChatMessageType.weekSummary:
        return RubyTheme.rubyPink.withOpacity(0.15);
      case ChatMessageType.taskRestored:
        return RubyTheme.emerald.withOpacity(0.15);
      case ChatMessageType.taskEdited:
        return RubyTheme.sapphire.withOpacity(0.15);
      case ChatMessageType.taskPriorityChanged:
        return RubyTheme.gold.withOpacity(0.15);
      case ChatMessageType.taskCategoryChanged:
        return RubyTheme.rubyPink.withOpacity(0.15);
      case ChatMessageType.taskMoved:
        return RubyTheme.sapphire.withOpacity(0.15);
    }
  }

  Border? _getMessageBorder() {
    switch (widget.message.type) {
      case ChatMessageType.taskCompleted:
        return Border.all(color: RubyTheme.emerald.withOpacity(0.3), width: 1);
      case ChatMessageType.taskDeleted:
        return Border.all(color: RubyTheme.rubyRed.withOpacity(0.3), width: 1);
      case ChatMessageType.taskMigrated:
        return Border.all(color: RubyTheme.gold.withOpacity(0.3), width: 1);
      case ChatMessageType.daySummary:
        return Border.all(color: RubyTheme.sapphire.withOpacity(0.3), width: 1);
      case ChatMessageType.weekSummary:
        return Border.all(color: RubyTheme.rubyPink.withOpacity(0.3), width: 1);
      case ChatMessageType.taskRestored:
        return Border.all(color: RubyTheme.emerald.withOpacity(0.3), width: 1);
      case ChatMessageType.taskEdited:
        return Border.all(color: RubyTheme.sapphire.withOpacity(0.3), width: 1);
      case ChatMessageType.taskPriorityChanged:
        return Border.all(color: RubyTheme.gold.withOpacity(0.3), width: 1);
      case ChatMessageType.taskCategoryChanged:
        return Border.all(color: RubyTheme.rubyPink.withOpacity(0.3), width: 1);
      case ChatMessageType.taskMoved:
        return Border.all(color: RubyTheme.sapphire.withOpacity(0.3), width: 1);
      default:
        return null;
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.message.type) {
      case ChatMessageType.taskCreated:
        return RubyTheme.pureWhite.withOpacity(0.2);
      case ChatMessageType.taskCompleted:
        return RubyTheme.emerald;
      case ChatMessageType.taskUncompleted:
        return RubyTheme.sapphire;
      case ChatMessageType.taskDeleted:
        return RubyTheme.rubyRed;
      case ChatMessageType.taskMigrated:
        return RubyTheme.gold;
      case ChatMessageType.daySummary:
        return RubyTheme.sapphire;
      case ChatMessageType.weekSummary:
        return RubyTheme.rubyPink;
      case ChatMessageType.taskRestored:
        return RubyTheme.emerald;
      case ChatMessageType.taskEdited:
        return RubyTheme.sapphire;
      case ChatMessageType.taskPriorityChanged:
        return RubyTheme.gold;
      case ChatMessageType.taskCategoryChanged:
        return RubyTheme.rubyPink;
      case ChatMessageType.taskMoved:
        return RubyTheme.sapphire;
    }
  }

  Color _getIconColor() {
    switch (widget.message.type) {
      case ChatMessageType.taskCreated:
        return RubyTheme.pureWhite.withOpacity(0.8);
      case ChatMessageType.taskCompleted:
      case ChatMessageType.taskUncompleted:
      case ChatMessageType.taskDeleted:
      case ChatMessageType.taskMigrated:
      case ChatMessageType.daySummary:
      case ChatMessageType.weekSummary:
      case ChatMessageType.taskRestored:
      case ChatMessageType.taskEdited:
      case ChatMessageType.taskPriorityChanged:
      case ChatMessageType.taskCategoryChanged:
      case ChatMessageType.taskMoved:
        return RubyTheme.pureWhite;
    }
  }

  Color _getTextColor() {
    switch (widget.message.type) {
      case ChatMessageType.taskCreated:
        return RubyTheme.pureWhite;
      case ChatMessageType.taskCompleted:
      case ChatMessageType.taskUncompleted:
      case ChatMessageType.taskDeleted:
      case ChatMessageType.taskMigrated:
      case ChatMessageType.daySummary:
      case ChatMessageType.weekSummary:
      case ChatMessageType.taskRestored:
      case ChatMessageType.taskEdited:
      case ChatMessageType.taskPriorityChanged:
      case ChatMessageType.taskCategoryChanged:
      case ChatMessageType.taskMoved:
        return RubyTheme.darkGray.withOpacity(0.8);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
