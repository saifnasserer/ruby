import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/ruby_theme.dart';
import '../../../../responsive.dart';
import '../../../../core/models/task.dart';
import '../../../../features/task_management/controllers/task_controller.dart';
import 'task_detail_card.dart';

class TaskDetailTitleAndAudio extends StatefulWidget {
  final Task task;
  final TaskController taskController;
  final String dateKey;
  final VoidCallback onTaskUpdated;

  const TaskDetailTitleAndAudio({
    super.key,
    required this.task,
    required this.taskController,
    required this.dateKey,
    required this.onTaskUpdated,
  });

  @override
  State<TaskDetailTitleAndAudio> createState() =>
      _TaskDetailTitleAndAudioState();
}

class _TaskDetailTitleAndAudioState extends State<TaskDetailTitleAndAudio>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleAnimationController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late TextEditingController _taskTextController;
  late TextEditingController _transcriptionController;

  bool _isEditingTaskText = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _taskTextController = TextEditingController(text: widget.task.text);
    _transcriptionController = TextEditingController(text: widget.task.text);

    _setupAudioPlayer();
    _initAudioSource();
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _audioPlayer.dispose();
    _taskTextController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  Future<void> _initAudioSource() async {
    if (widget.task.audioPath != null) {
      await _audioPlayer.setSource(DeviceFileSource(widget.task.audioPath!));
    }
  }

  void _setupAudioPlayer() {
    if (widget.task.audioPath == null) return;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _toggleTaskCompletion() {
    widget.taskController.toggleTaskCompletion(widget.dateKey, widget.task.id);
    widget.onTaskUpdated();
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHigh;
      case TaskPriority.normal:
        return RubyTheme.sapphire; // Default or Low priority color
    }
  }

  Gradient _getPriorityGradient() {
    switch (widget.task.priority) {
      case TaskPriority.important:
        return LinearGradient(
          colors: [
            RubyTheme.priorityHigh,
            RubyTheme.priorityHigh.withOpacity(0.8),
          ],
        );
      case TaskPriority.normal:
        return LinearGradient(
          colors: [RubyTheme.sapphire, RubyTheme.sapphire.withOpacity(0.8)],
        );
    }
  }

  Widget _buildAudioPlayerDetail() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RubyTheme.rubyRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: RubyTheme.primary(context),
            ),
            onPressed: _toggleAudio,
            iconSize: 40,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: RubyTheme.primary(context),
                inactiveTrackColor: RubyTheme.textSecondary(
                  context,
                ).withOpacity(0.2),
                thumbColor: RubyTheme.primary(context),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble() > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: (value) {
                  setState(() {
                    _position = Duration(milliseconds: value.toInt());
                  });
                },
                onChangeEnd: (value) async {
                  final position = Duration(milliseconds: value.toInt());
                  try {
                    await _audioPlayer.seek(position);
                  } catch (e) {
                    print('Error seeking: $e');
                  }
                },
              ),
            ),
          ),
          Text(
            '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
            style: RubyTheme.caption(context).copyWith(
              color: RubyTheme.primary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimationController,
          child: GestureDetector(
            onTap: () async {
              await _scaleAnimationController.forward();
              await _scaleAnimationController.reverse();
              _toggleTaskCompletion();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              decoration: BoxDecoration(
                gradient: widget.task.isCompleted
                    ? LinearGradient(
                        colors: [
                          RubyTheme.emerald,
                          RubyTheme.emerald.withOpacity(0.8),
                        ],
                      )
                    : _getPriorityGradient(),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.task.isCompleted
                                ? RubyTheme.emerald
                                : _getPriorityColor())
                            .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge and edit button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status badge
                      Row(
                        children: [
                          Icon(
                            widget.task.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: RubyTheme.pureWhite,
                            size: Responsive.text(
                              context,
                              size: TextSize.heading,
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            widget.task.isCompleted ? 'مكتملة' : 'قيد التنفيذ',
                            style: RubyTheme.bodyLarge(context).copyWith(
                              color: RubyTheme.pureWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: RubyTheme.pureWhite.withOpacity(0.5),
                          ),
                        ],
                      ),

                      // Edit button (only show for non-audio tasks)
                      if (widget.task.audioPath == null)
                        GestureDetector(
                          onTap: () {
                            if (_isEditingTaskText) {
                              // Save the changes when clicking checkmark
                              final newText = _taskTextController.text.trim();
                              if (newText.isNotEmpty &&
                                  newText != widget.task.text) {
                                widget.taskController.editTask(
                                  widget.dateKey,
                                  widget.task.id,
                                  newText,
                                );
                                widget.onTaskUpdated();
                              }
                            }
                            setState(() {
                              _isEditingTaskText = !_isEditingTaskText;
                              if (_isEditingTaskText) {
                                _taskTextController.text = widget.task.text;
                                _taskTextController.addListener(() {
                                  if (mounted) setState(() {});
                                });
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RubyTheme.pureWhite.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _isEditingTaskText ? Icons.check : Icons.edit,
                              color:
                                  _isEditingTaskText &&
                                      _taskTextController.text.trim().isEmpty
                                  ? RubyTheme.pureWhite.withOpacity(0.5)
                                  : RubyTheme.pureWhite,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // Task text (editable or display)
                  if (widget.task.audioPath != null)
                    _buildAudioPlayerDetail()
                  else if (_isEditingTaskText)
                    TextField(
                      controller: _taskTextController,
                      maxLines: null,
                      autofocus: true,
                      textDirection: TextDirection.rtl,
                      style: RubyTheme.heading2(
                        context,
                      ).copyWith(color: RubyTheme.pureWhite, height: 1.5),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: RubyTheme.pureWhite.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: RubyTheme.pureWhite.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: RubyTheme.pureWhite,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: RubyTheme.pureWhite.withOpacity(0.1),
                      ),
                      onSubmitted: (value) {
                        final trimmedValue = value.trim();
                        if (trimmedValue.isNotEmpty &&
                            trimmedValue != widget.task.text) {
                          widget.taskController.editTask(
                            widget.dateKey,
                            widget.task.id,
                            trimmedValue,
                          );
                          widget.onTaskUpdated();
                        }
                        setState(() {
                          _isEditingTaskText = false;
                        });
                      },
                    )
                  else
                    Text(
                      widget.task.text,
                      style: RubyTheme.heading2(
                        context,
                      ).copyWith(color: RubyTheme.pureWhite, height: 1.5),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Transcription Card (for Audio tasks)
        if (widget.task.audioPath != null) ...[
          SizedBox(height: Responsive.space(context, size: Space.large)),
          TaskDetailCard(
            title: 'التاسك',
            children: [
              TextField(
                controller: _transcriptionController,
                maxLines: null,
                textDirection: TextDirection.rtl,
                style: RubyTheme.bodyLarge(context).copyWith(height: 1.6),
                decoration: InputDecoration(
                  hintText: 'تفريغ النص...',
                  hintStyle: RubyTheme.bodyLarge(
                    context,
                  ).copyWith(color: RubyTheme.mediumGray),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  // Save on type
                  widget.taskController.updateTaskText(
                    widget.dateKey,
                    widget.task.id,
                    value,
                  );
                  widget.onTaskUpdated();
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}
