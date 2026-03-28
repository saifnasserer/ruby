import 'package:flutter/material.dart';
import '../../../core/theme/ruby_theme.dart';
import '../../features/settings/controllers/settings_controller.dart';

class ChatInput extends StatefulWidget {
  final String dayOfWeek;
  final Function(String, List<String>) onTaskAdded;
  final Function(String, String)? onTaskRestored;
  final Function(String, List<double>?, List<String>)? onVoiceTaskAdded;
  final SettingsController? settingsController;
  final bool hasActiveFilters;
  final List<String> availableTags;
  final FocusNode? focusNode;

  const ChatInput({
    super.key,
    required this.dayOfWeek,
    required this.onTaskAdded,
    this.onTaskRestored,
    this.onVoiceTaskAdded,
    this.settingsController,
    this.hasActiveFilters = false,
    required this.availableTags,
    this.focusNode,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  bool _isTyping = false;
  bool _showTagSelector = false;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {
        _showTagSelector = _focusNode.hasFocus;
        if (_showTagSelector) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.isNotEmpty != _isTyping) {
      setState(() {
        _isTyping = text.isNotEmpty;
      });
    }
  }

  void _sendTask() {
    final taskText = _controller.text.trim();
    if (taskText.isNotEmpty) {
      widget.onTaskAdded(taskText, _selectedTags);
      _controller.clear();
      setState(() {
        _selectedTags = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = RubyTheme.priorityLow;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: RubyTheme.spacingM(context),
        vertical: RubyTheme.spacingS(context),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Tag Selector
            if (widget.availableTags.isNotEmpty)
              _buildFloatingTagSelector(),
            
            SizedBox(height: RubyTheme.spacingS(context)),

            // Input Bar
            Row(
              children: [
                // Send button
                if (_isTyping)
                  GestureDetector(
                    onTap: _sendTask,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: RubyTheme.spacingL(context) * 2,
                      height: RubyTheme.spacingL(context) * 2,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: RubyTheme.softShadow(context),
                      ),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..scale(-1.0, 1.0),
                        child: Icon(
                          Icons.send_rounded,
                          color: RubyTheme.pureWhite,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                if (_isTyping) SizedBox(width: RubyTheme.spacingS(context)),

                // Input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: RubyTheme.surface(context),
                      borderRadius: BorderRadius.circular(
                        RubyTheme.radiusLarge(context),
                      ),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: RubyTheme.softShadow(context),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textDirection: TextDirection.rtl,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: widget.hasActiveFilters
                            ? 'اكتب التاسك (فلتر نشط) ...'
                            : 'اكتب التاسك ...',
                        hintStyle: RubyTheme.bodyMedium(context).copyWith(
                          color: RubyTheme.textSecondary(
                            context,
                          ).withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: RubyTheme.spacingM(context),
                          vertical: RubyTheme.spacingM(context) / 2,
                        ),
                        suffixIcon: _isTyping
                               ? null
                               : Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     if (widget.hasActiveFilters)
                                       Container(
                                         margin: const EdgeInsets.only(right: 4),
                                         padding: const EdgeInsets.all(6),
                                         decoration: BoxDecoration(
                                           color: RubyTheme.sapphire.withOpacity(0.15),
                                           shape: BoxShape.circle,
                                         ),
                                         child: const Icon(
                                           Icons.filter_list,
                                           size: 16,
                                           color: RubyTheme.sapphire,
                                         ),
                                       )
                                     else
                                       Icon(
                                         Icons.arrow_back_ios_new_rounded,
                                         size: 16,
                                         color: RubyTheme.textSecondary(context).withOpacity(0.5),
                                       ),
                                     const SizedBox(width: 12),
                                   ],
                                 ),
                      ),
                      style: RubyTheme.bodyLarge(
                        context,
                      ).copyWith(color: RubyTheme.textPrimary(context)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingTagSelector() {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: widget.availableTags.length,
          itemBuilder: (context, index) {
            final tag = widget.availableTags[index];
            final isSelected = _selectedTags.contains(tag);

            // Calculate staggered animation delay
            final double start = (index * 0.05).clamp(0.0, 0.6);
            final double end = (start + 0.4).clamp(0.0, 1.0);
            
            final tagAnimation = CurvedAnimation(
              parent: _animationController,
              curve: Interval(start, end, curve: Curves.easeOutBack),
            );

            return FadeTransition(
              opacity: tagAnimation,
              child: ScaleTransition(
                scale: tagAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? RubyTheme.accent(context) 
                          : RubyTheme.surfaceVariant(context).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: isSelected ? RubyTheme.softShadow(context) : null,
                        border: Border.all(
                          color: isSelected 
                            ? RubyTheme.accent(context) 
                            : RubyTheme.textSecondary(context).withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tag,
                          style: RubyTheme.bodyMedium(context).copyWith(
                            color: isSelected ? RubyTheme.pureWhite : RubyTheme.textPrimary(context),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
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
