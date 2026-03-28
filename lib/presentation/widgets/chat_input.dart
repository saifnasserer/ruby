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

  const ChatInput({
    super.key,
    required this.dayOfWeek,
    required this.onTaskAdded,
    this.onTaskRestored,
    this.onVoiceTaskAdded,
    this.settingsController,
    this.hasActiveFilters = false,
    required this.availableTags,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _showTagSelector = false;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {
        _showTagSelector = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating Tag Selector (Separate from input bar)
            if (_showTagSelector && widget.availableTags.isNotEmpty)
              _buildFloatingTagSelector(),
            if (_showTagSelector && widget.availableTags.isNotEmpty)
              const SizedBox(height: 12),
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
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: RubyTheme.surface(context).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: RubyTheme.sapphire.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.availableTags.length,
        itemBuilder: (context, index) {
          final tag = widget.availableTags[index];
          final isSelected = _selectedTags.contains(tag);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? RubyTheme.sapphire : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected 
                      ? RubyTheme.sapphire 
                      : RubyTheme.textSecondary(context).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    tag,
                    style: RubyTheme.bodyMedium(context).copyWith(
                      color: isSelected ? RubyTheme.pureWhite : RubyTheme.textPrimary(context),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
