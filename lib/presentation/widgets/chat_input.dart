import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';

class ChatInput extends StatefulWidget {
  final String dayOfWeek;
  final Function(String) onTaskAdded;
  final Function(String, String)? onTaskRestored;

  const ChatInput({
    super.key,
    required this.dayOfWeek,
    required this.onTaskAdded,
    this.onTaskRestored,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendTask() {
    final taskText = _controller.text.trim();
    if (taskText.isNotEmpty) {
      widget.onTaskAdded(taskText);
      _controller.clear();
      // Keep keyboard open for continuous task entry
      // _focusNode.unfocus(); // Removed to prevent keyboard dismissal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RubyTheme.softGradient,
        boxShadow: RubyTheme.softShadow,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: RubyTheme.spacingM(context),
          vertical: RubyTheme.spacingS(context),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Send button
              GestureDetector(
                onTap: _isTyping ? _sendTask : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: RubyTheme.spacingL(context) * 2,
                  height: RubyTheme.spacingL(context) * 2,
                  decoration: BoxDecoration(
                    gradient: _isTyping ? RubyTheme.rubyGradient : null,
                    color: _isTyping ? null : RubyTheme.softGray,
                    shape: BoxShape.circle,
                    boxShadow: _isTyping ? RubyTheme.softShadow : null,
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: Icon(
                      Icons.send_rounded,
                      color: _isTyping
                          ? RubyTheme.pureWhite
                          : RubyTheme.mediumGray,
                      size: 20,
                    ),
                  ),
                ),
              ),

              SizedBox(width: RubyTheme.spacingS(context)),

              // Input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: RubyTheme.pureWhite,
                    borderRadius: BorderRadius.circular(
                      RubyTheme.radiusLarge(context),
                    ),
                    border: Border.all(
                      color: RubyTheme.rubyPink.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: RubyTheme.softShadow,
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textDirection: TextDirection.rtl,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'اكتب التاسك ...',
                      hintStyle: RubyTheme.bodyMedium(
                        context,
                      ).copyWith(color: RubyTheme.mediumGray.withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: RubyTheme.spacingM(context),
                        vertical: RubyTheme.spacingM(context) / 2,
                      ),
                    ),
                    style: RubyTheme.bodyLarge(
                      context,
                    ).copyWith(color: RubyTheme.charcoal),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _sendTask();
                      }
                    },
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
