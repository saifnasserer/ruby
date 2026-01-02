import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';
import '../../core/services/audio_recorder_service.dart';
import '../../features/settings/controllers/settings_controller.dart';

class ChatInput extends StatefulWidget {
  final String dayOfWeek;
  final Function(String) onTaskAdded;
  final Function(String, String)? onTaskRestored;
  final Function(String)? onVoiceTaskAdded;
  final SettingsController? settingsController;

  const ChatInput({
    super.key,
    required this.dayOfWeek,
    required this.onTaskAdded,
    this.onTaskRestored,
    this.onVoiceTaskAdded,
    this.settingsController,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  bool _isTyping = false;
  bool _isRecording = false;

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
    _audioRecorderService.dispose();
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

  Future<void> _handleVoiceRecord() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorderService.stopRecording();
      setState(() {
        _isRecording = false;
      });

      if (path != null && widget.onVoiceTaskAdded != null) {
        widget.onVoiceTaskAdded!(path);
      }
    } else {
      // Start recording
      final hasPermission = await _audioRecorderService.hasPermission();
      if (hasPermission) {
        final fileName = 'voice_task_${DateTime.now().millisecondsSinceEpoch}';
        await _audioRecorderService.startRecording(fileName);
        setState(() {
          _isRecording = true;
        });
      } else {
        // Handle permission denial
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب السماح بالوصول للميكروفون لتسجيل الصوت'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme color from settings or use default
    final themeColor =
        widget.settingsController?.backgroundColor ?? RubyTheme.pureWhite;
    final isLightColor = themeColor.computeLuminance() > 0.5;
    final accentColor = isLightColor ? RubyTheme.rubyRed : RubyTheme.rubyPink;

    return Container(
      decoration: BoxDecoration(
        color: themeColor,
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
              // Send/Record button
              GestureDetector(
                onTap: _isTyping ? _sendTask : _handleVoiceRecord,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: RubyTheme.spacingL(context) * 2,
                  height: RubyTheme.spacingL(context) * 2,
                  decoration: BoxDecoration(
                    color: _isTyping
                        ? accentColor
                        : (_isRecording ? Colors.red : RubyTheme.softGray),
                    shape: BoxShape.circle,
                    boxShadow: (_isTyping || _isRecording)
                        ? RubyTheme.softShadow
                        : null,
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: Icon(
                      _isTyping
                          ? Icons.send_rounded
                          : (_isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded),
                      color: _isTyping || _isRecording
                          ? RubyTheme.pureWhite
                          : RubyTheme.mediumGray,
                      size: 20,
                    ),
                  ),
                ),
              ),

              SizedBox(width: RubyTheme.spacingS(context)),

              // Input field (show "Recording..." when recording)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: RubyTheme.pureWhite,
                    borderRadius: BorderRadius.circular(
                      RubyTheme.radiusLarge(context),
                    ),
                    border: Border.all(
                      color: _isRecording
                          ? Colors.red
                          : accentColor.withOpacity(0.3),
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
                    enabled: !_isRecording, // Disable input while recording
                    decoration: InputDecoration(
                      hintText: _isRecording
                          ? 'جاري التسجيل...'
                          : 'اكتب التاسك ...',
                      hintStyle: RubyTheme.bodyMedium(context).copyWith(
                        color: _isRecording
                            ? Colors.red
                            : RubyTheme.mediumGray.withOpacity(0.6),
                      ),
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
