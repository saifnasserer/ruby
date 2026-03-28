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
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
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
            // Tag Selector Row
            _buildTagSelector(),
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
                            : (widget.hasActiveFilters
                                ? Container(
                                    margin: EdgeInsets.all(8),
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: RubyTheme.sapphire.withOpacity(
                                        0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.filter_list,
                                      size: 16,
                                      color: RubyTheme.sapphire,
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16,
                                    color: RubyTheme.textSecondary(
                                      context,
                                    ).withOpacity(0.5),
                                  )),
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

  Widget _buildTagSelector() {
    if (widget.availableTags.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 48,
      margin: const EdgeInsets.only(bottom: 12, right: 0, left: 0),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context).withOpacity(0.9),
        borderRadius: BorderRadius.circular(RubyTheme.radiusMedium(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? RubyTheme.sapphire
                      : RubyTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? RubyTheme.sapphire
                        : RubyTheme.textSecondary(context).withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: RubyTheme.sapphire.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tag,
                    style: RubyTheme.bodyMedium(context).copyWith(
                      color: isSelected
                          ? RubyTheme.pureWhite
                          : RubyTheme.textPrimary(context),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
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
